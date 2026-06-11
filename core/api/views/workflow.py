import io

from django.db import transaction
from django.http import HttpResponse
from django.utils import timezone
from rest_framework.decorators import action

from core.models import Dispense, InsuranceRequest, InsuranceRequestStatus, Prescription, SystemSettings, UserRole
from core.services import (
    apply_role_scope,
    sync_prescription_status_from_dispense,
    sync_prescription_status_from_insurance,
)
from core.api.serializers import DispenseSerializer, InsuranceRequestSerializer, PrescriptionSerializer
from core.utils import notify_dispense_updated, notify_insurance_updated, notify_prescription_created

from .common import BaseOwnedModelViewSet


def _ensure_auto_approved_insurance_request(viewset, prescription):
    if prescription.status not in {"Sent", "PendingInsuranceApproval", "Approved"}:
        return
    settings = SystemSettings.get_solo()
    if not settings.insurance_workflow_enabled:
        if prescription.status != "Approved":
            prescription.status = "Approved"
            prescription.save(update_fields=["status", "updated_at"])
        return
    if hasattr(prescription, "insurance_request"):
        return

    insurance_request = InsuranceRequest.objects.create(
        prescription=prescription,
        request_number=f"INS-{prescription.prescription_number}",
        status=InsuranceRequestStatus.APPROVED,
        submitted_at=timezone.now(),
        reviewed_at=timezone.now(),
    )
    sync_prescription_status_from_insurance(insurance_request)
    viewset.log_action("Insurance request auto-created", insurance_request)
    notify_insurance_updated(insurance_request)


class PrescriptionViewSet(BaseOwnedModelViewSet):
    serializer_class = PrescriptionSerializer
    queryset = Prescription.objects.select_related(
        "employee",
        "employee__user",
        "doctor",
        "doctor__user",
        "beneficiary",
        "provider",
        "service",
    ).prefetch_related("items", "items__medication")
    search_fields = (
        "prescription_number",
        "employee__medical_record_number",
        "employee__user__username",
        "employee__user__first_name",
        "employee__user__last_name",
        "doctor__license_number",
        "doctor__user__username",
        "doctor__user__first_name",
        "doctor__user__last_name",
        "status",
    )
    ordering = ("-issued_at", "-created_at")
    exact_filter_fields = {
        "status": "status",
        "employee": "employee_id",
        "doctor": "doctor_id",
        "beneficiary": "beneficiary_id",
        "provider": "provider_id",
        "service_type": "service_type",
    }
    role_permissions = {
        "create": [UserRole.ADMIN, UserRole.DOCTOR],
        "update": [UserRole.ADMIN, UserRole.DOCTOR],
        "partial_update": [UserRole.ADMIN, UserRole.DOCTOR],
        "destroy": [UserRole.ADMIN, UserRole.DOCTOR],
    }

    def get_queryset(self):
        return apply_role_scope(
            self.queryset,
            self.request.user,
            {
                UserRole.EMPLOYEE: lambda queryset, user: queryset.filter(employee__user=user),
                UserRole.DOCTOR: lambda queryset, user: queryset.filter(doctor__user=user),
                UserRole.PHARMACIST: lambda queryset, user: queryset.filter(
                    service_type="Medication",
                ).exclude(
                    status__in=["Draft", "Cancelled", "Expired"],
                ).distinct(),
                UserRole.INSURANCE_OFFICER: lambda queryset, user: queryset.filter(
                    insurance_request__isnull=False
                ).distinct(),
            },
        )

    @transaction.atomic
    def perform_create(self, serializer):
        if self.request.user.role == UserRole.DOCTOR and not self.request.user.is_superuser:
            prescription = serializer.save(doctor=self.request.user.doctor_profile)
        else:
            prescription = serializer.save()
        _ensure_auto_approved_insurance_request(self, prescription)
        self.log_action("Prescription created", prescription)
        notify_prescription_created(prescription)

    @transaction.atomic
    def perform_update(self, serializer):
        previous_status = serializer.instance.status
        prescription = serializer.save()
        _ensure_auto_approved_insurance_request(self, prescription)
        self.log_action(
            "Prescription updated",
            prescription,
            details=f"Status changed from {previous_status} to {prescription.status}.",
        )

    @action(detail=True, methods=["get"], url_path="qr-code")
    def qr_code(self, request, pk=None):
        prescription = self.get_object()
        import qrcode
        import qrcode.image.svg

        qr_data = self.get_serializer(prescription).data["qr_payload"]
        factory = qrcode.image.svg.SvgImage
        image = qrcode.make(qr_data, image_factory=factory, box_size=10)
        stream = io.BytesIO()
        image.save(stream)
        return HttpResponse(stream.getvalue(), content_type="image/svg+xml")


class InsuranceRequestViewSet(BaseOwnedModelViewSet):
    serializer_class = InsuranceRequestSerializer
    queryset = InsuranceRequest.objects.select_related(
        "prescription",
        "prescription__employee",
        "prescription__employee__user",
        "prescription__doctor",
        "prescription__doctor__user",
        "prescription__provider",
        "prescription__service",
        "reviewed_by",
        "reviewed_by__user",
    ).all()
    search_fields = ("request_number", "prescription__prescription_number", "status")
    ordering = ("-submitted_at", "-created_at")
    exact_filter_fields = {
        "status": "status",
        "prescription": "prescription_id",
        "reviewed_by": "reviewed_by_id",
    }
    role_permissions = {
        "create": [UserRole.ADMIN, UserRole.DOCTOR],
        "update": [UserRole.ADMIN, UserRole.INSURANCE_OFFICER],
        "partial_update": [UserRole.ADMIN, UserRole.INSURANCE_OFFICER],
        "destroy": [UserRole.ADMIN],
    }

    def get_queryset(self):
        return apply_role_scope(
            self.queryset,
            self.request.user,
            {
                UserRole.EMPLOYEE: lambda queryset, user: queryset.filter(prescription__employee__user=user),
                UserRole.DOCTOR: lambda queryset, user: queryset.filter(prescription__doctor__user=user),
                UserRole.INSURANCE_OFFICER: lambda queryset, user: queryset,
            },
        )

    @transaction.atomic
    def perform_update(self, serializer):
        previous_status = serializer.instance.status
        if self.request.user.role == UserRole.INSURANCE_OFFICER and not self.request.user.is_superuser:
            insurance_request = serializer.save(
                reviewed_by=self.request.user.insurance_officer_profile,
                reviewed_at=timezone.now(),
            )
        else:
            insurance_request = serializer.save()
        if previous_status != insurance_request.status:
            sync_prescription_status_from_insurance(insurance_request)
        self.log_action("Insurance request updated", insurance_request)
        notify_insurance_updated(insurance_request)

    @transaction.atomic
    def perform_create(self, serializer):
        review_payload = {
            "status": InsuranceRequestStatus.APPROVED,
            "reviewed_at": timezone.now(),
        }
        insurance_request = serializer.save(**review_payload)
        sync_prescription_status_from_insurance(insurance_request)
        self.log_action("Insurance request created", insurance_request)
        notify_insurance_updated(insurance_request)


class DispenseViewSet(BaseOwnedModelViewSet):
    serializer_class = DispenseSerializer
    queryset = Dispense.objects.select_related(
        "prescription",
        "prescription__employee",
        "prescription__employee__user",
        "prescription__doctor",
        "prescription__doctor__user",
        "pharmacist",
        "pharmacist__user",
        "pharmacist__pharmacy",
    ).all()
    search_fields = ("dispense_number", "prescription__prescription_number", "status")
    ordering = ("-dispensed_at", "-created_at")
    exact_filter_fields = {
        "status": "status",
        "prescription": "prescription_id",
        "pharmacist": "pharmacist_id",
        "pharmacy": "pharmacist__pharmacy_id",
    }
    role_permissions = {
        "create": [UserRole.ADMIN, UserRole.PHARMACIST],
        "update": [UserRole.ADMIN, UserRole.PHARMACIST],
        "partial_update": [UserRole.ADMIN, UserRole.PHARMACIST],
        "destroy": [UserRole.ADMIN],
    }

    def get_queryset(self):
        return apply_role_scope(
            self.queryset,
            self.request.user,
            {
                UserRole.EMPLOYEE: lambda queryset, user: queryset.filter(prescription__employee__user=user),
                UserRole.DOCTOR: lambda queryset, user: queryset.filter(prescription__doctor__user=user),
                UserRole.PHARMACIST: lambda queryset, user: queryset.filter(pharmacist__user=user),
            },
        )

    @transaction.atomic
    def perform_create(self, serializer):
        if self.request.user.role == UserRole.PHARMACIST and not self.request.user.is_superuser:
            dispense = serializer.save(pharmacist=self.request.user.pharmacist_profile)
        else:
            dispense = serializer.save()
        sync_prescription_status_from_dispense(dispense)
        self.log_action("Dispense created", dispense)
        notify_dispense_updated(dispense)

    @transaction.atomic
    def perform_update(self, serializer):
        previous_status = serializer.instance.status
        dispense = serializer.save()
        if previous_status != dispense.status:
            sync_prescription_status_from_dispense(dispense)
        self.log_action("Dispense updated", dispense)
        notify_dispense_updated(dispense)
