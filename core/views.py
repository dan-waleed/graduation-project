import io

from django.contrib.auth import get_user_model
from django.http import HttpResponse
from django.db import transaction
from django.utils import timezone
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet

from .models import (
    LEGACY_PROVIDER_ROLES,
    AuditLog,
    Dependent,
    Dispense,
    Doctor,
    Employee,
    InsuranceOfficer,
    InsuranceRequest,
    InsuranceRequestStatus,
    Laboratory,
    Medication,
    MedicalCenter,
    MedicalImagingCenter,
    MedicalService,
    Notification,
    Pharmacist,
    Pharmacy,
    Prescription,
    Provider,
    ProviderServicePrice,
    UserRole,
)
from .permissions import RoleAccessMixin
from .serializers import (
    AuditLogSerializer,
    DependentSerializer,
    DispenseSerializer,
    DoctorSerializer,
    EmployeeSerializer,
    InsuranceOfficerSerializer,
    InsuranceRequestSerializer,
    LaboratorySerializer,
    MedicationSerializer,
    MedicalCenterSerializer,
    MedicalImagingCenterSerializer,
    MedicalServiceSerializer,
    NotificationSerializer,
    PharmacistSerializer,
    PharmacySerializer,
    PrescriptionSerializer,
    ProviderSerializer,
    ProviderServicePriceSerializer,
    UserSerializer,
)
from .utils import (
    create_audit_log,
    notify_dispense_updated,
    notify_insurance_updated,
    notify_prescription_created,
)

User = get_user_model()


class BaseOwnedModelViewSet(RoleAccessMixin, ModelViewSet):
    """Base viewset that enforces authentication for all API endpoints."""

    permission_classes = [IsAuthenticated]
    search_fields = ()
    ordering_fields = "__all__"
    ordering = ("-id",)
    exact_filter_fields = {}

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        if not self.has_role_permission(request):
            self.permission_denied(request, message="ليس لديك صلاحية لتنفيذ هذا الإجراء.")

    def log_action(self, action, instance=None, details=""):
        create_audit_log(
            actor=self.request.user,
            action=action,
            target_model=instance.__class__.__name__ if instance is not None else "",
            target_id=getattr(instance, "pk", ""),
            details=details,
        )

    def perform_create(self, serializer):
        instance = serializer.save()
        self.log_action(f"{instance.__class__.__name__} created", instance)

    def perform_update(self, serializer):
        instance = serializer.save()
        self.log_action(f"{instance.__class__.__name__} updated", instance)

    def perform_destroy(self, instance):
        self.log_action(f"{instance.__class__.__name__} deleted", instance)
        instance.delete()

    def filter_queryset(self, queryset):
        queryset = super().filter_queryset(queryset)
        for query_param, model_field in self.exact_filter_fields.items():
            value = self.request.query_params.get(query_param)
            if value not in (None, ""):
                queryset = queryset.filter(**{model_field: value})
        return queryset


class UserViewSet(BaseOwnedModelViewSet):
    """API endpoints for user accounts."""

    serializer_class = UserSerializer
    queryset = User.objects.all().order_by("username")
    search_fields = ("username", "email", "first_name", "last_name", "role")
    ordering = ("username",)
    exact_filter_fields = {
        "role": "role",
        "is_active": "is_active",
    }
    role_permissions = {
        "list": [UserRole.ADMIN],
        "create": [UserRole.ADMIN],
        "destroy": [UserRole.ADMIN],
        "update": [UserRole.ADMIN],
        "partial_update": [UserRole.ADMIN],
        "retrieve": [
            UserRole.ADMIN,
            UserRole.DOCTOR,
            UserRole.EMPLOYEE,
            UserRole.PHARMACIST,
            UserRole.LABORATORY,
            UserRole.IMAGING_CENTER,
            UserRole.MEDICAL_CENTER,
            UserRole.INSURANCE_OFFICER,
        ],
    }

    def get_queryset(self):
        user = self.request.user
        if user.role == "Admin" or user.is_superuser:
            return self.queryset.exclude(role__in=LEGACY_PROVIDER_ROLES)
        return self.queryset.filter(pk=user.pk)


class EmployeeViewSet(BaseOwnedModelViewSet):
    """API endpoints for insured university employee profiles."""

    serializer_class = EmployeeSerializer
    queryset = Employee.objects.select_related("user").all()
    search_fields = ("medical_record_number", "user__username", "user__first_name", "user__last_name")
    ordering = ("medical_record_number",)
    exact_filter_fields = {
        "user": "user_id",
        "medical_record_number": "medical_record_number",
    }
    role_permissions = {
        "create": [UserRole.ADMIN],
        "update": [UserRole.ADMIN, UserRole.EMPLOYEE],
        "partial_update": [UserRole.ADMIN, UserRole.EMPLOYEE],
        "destroy": [UserRole.ADMIN],
    }

    def get_queryset(self):
        user = self.request.user
        if user.role == "Admin" or user.is_superuser:
            return self.queryset
        if user.role == UserRole.EMPLOYEE:
            return self.queryset.filter(user=user)
        if user.role == "Doctor":
            return self.queryset
        if user.role == "Pharmacist":
            return self.queryset.filter(prescriptions__dispenses__pharmacist__user=user).distinct()
        if user.role == "InsuranceOfficer":
            return self.queryset.filter(medical_orders__insurance_request__isnull=False).distinct()
        return self.queryset.none()


class DoctorViewSet(BaseOwnedModelViewSet):
    """API endpoints for doctor profiles."""

    serializer_class = DoctorSerializer
    queryset = Doctor.objects.select_related("user").all()
    search_fields = ("license_number", "specialization", "user__username", "user__first_name", "user__last_name")
    ordering = ("license_number",)
    exact_filter_fields = {
        "user": "user_id",
        "specialization": "specialization",
        "city": "provider__city",
        "provider_name": "provider__provider_name",
        "contract_status": "contract_status",
    }
    role_permissions = {
        "create": [UserRole.ADMIN],
        "update": [UserRole.ADMIN, UserRole.DOCTOR],
        "partial_update": [UserRole.ADMIN, UserRole.DOCTOR],
        "destroy": [UserRole.ADMIN],
    }

    def get_queryset(self):
        user = self.request.user
        if user.role == "Admin" or user.is_superuser:
            return self.queryset
        if user.role == "Doctor":
            return self.queryset.filter(user=user)
        return self.queryset.none()


class PharmacyViewSet(BaseOwnedModelViewSet):
    """API endpoints for pharmacies."""

    serializer_class = PharmacySerializer
    queryset = Pharmacy.objects.all()
    search_fields = ("name", "license_number", "phone_number")
    ordering = ("name",)
    exact_filter_fields = {
        "is_active": "is_active",
        "license_number": "license_number",
    }
    role_permissions = {
        "create": [UserRole.ADMIN],
        "update": [UserRole.ADMIN],
        "partial_update": [UserRole.ADMIN],
        "destroy": [UserRole.ADMIN],
    }

    def get_queryset(self):
        user = self.request.user
        if user.role == "Admin" or user.is_superuser:
            return self.queryset
        if user.role == "Pharmacist":
            return self.queryset.filter(pharmacists__user=user).distinct()
        return self.queryset


class ProviderViewSet(BaseOwnedModelViewSet):
    """API endpoints for generic providers."""

    serializer_class = ProviderSerializer
    queryset = Provider.objects.all()
    search_fields = ("provider_name", "provider_type", "city", "address", "phone")
    ordering = ("provider_type", "provider_name")
    exact_filter_fields = {
        "provider_type": "provider_type",
        "contract_status": "contract_status",
        "city": "city",
    }
    role_permissions = {
        "create": [UserRole.ADMIN],
        "update": [UserRole.ADMIN],
        "partial_update": [UserRole.ADMIN],
        "destroy": [UserRole.ADMIN],
    }


class MedicalServiceViewSet(BaseOwnedModelViewSet):
    """API endpoints for medical services."""

    serializer_class = MedicalServiceSerializer
    queryset = MedicalService.objects.all()
    search_fields = ("service_name", "service_type", "description")
    ordering = ("service_type", "service_name")
    exact_filter_fields = {
        "service_type": "service_type",
        "requires_insurance_approval": "requires_insurance_approval",
    }
    role_permissions = {
        "create": [UserRole.ADMIN],
        "update": [UserRole.ADMIN],
        "partial_update": [UserRole.ADMIN],
        "destroy": [UserRole.ADMIN],
    }


class ProviderServicePriceViewSet(BaseOwnedModelViewSet):
    """API endpoints for provider-specific service pricing."""

    serializer_class = ProviderServicePriceSerializer
    queryset = ProviderServicePrice.objects.select_related("provider", "service").all()
    search_fields = ("provider__provider_name", "service__service_name", "provider__city")
    ordering = ("provider__provider_name", "service__service_name")
    exact_filter_fields = {
        "provider": "provider_id",
        "service": "service_id",
        "is_available": "is_available",
    }
    role_permissions = {
        "create": [UserRole.ADMIN],
        "update": [UserRole.ADMIN],
        "partial_update": [UserRole.ADMIN],
        "destroy": [UserRole.ADMIN],
    }


class PharmacistViewSet(BaseOwnedModelViewSet):
    """API endpoints for pharmacist profiles."""

    serializer_class = PharmacistSerializer
    queryset = Pharmacist.objects.select_related("user", "pharmacy").all()
    search_fields = ("license_number", "user__username", "user__first_name", "user__last_name", "pharmacy__name")
    ordering = ("license_number",)
    exact_filter_fields = {
        "user": "user_id",
        "pharmacy": "pharmacy_id",
        "license_number": "license_number",
    }
    role_permissions = {
        "create": [UserRole.ADMIN],
        "update": [UserRole.ADMIN, UserRole.PHARMACIST],
        "partial_update": [UserRole.ADMIN, UserRole.PHARMACIST],
        "destroy": [UserRole.ADMIN],
    }

    def get_queryset(self):
        user = self.request.user
        if user.role == "Admin" or user.is_superuser:
            return self.queryset
        if user.role == "Pharmacist":
            return self.queryset.filter(user=user)
        return self.queryset.none()


class LaboratoryViewSet(BaseOwnedModelViewSet):
    """API endpoints for laboratory profiles."""

    serializer_class = LaboratorySerializer
    queryset = Laboratory.objects.select_related("user", "provider").all()
    search_fields = ("license_number", "provider__provider_name", "user__username")
    ordering = ("license_number",)
    exact_filter_fields = {
        "user": "user_id",
        "provider": "provider_id",
    }
    role_permissions = {
        "create": [UserRole.ADMIN],
        "update": [UserRole.ADMIN, UserRole.LABORATORY],
        "partial_update": [UserRole.ADMIN, UserRole.LABORATORY],
        "destroy": [UserRole.ADMIN],
    }

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.ADMIN or user.is_superuser:
            return self.queryset
        if user.role == UserRole.LABORATORY:
            return self.queryset.filter(user=user)
        return self.queryset.none()


class MedicalImagingCenterViewSet(BaseOwnedModelViewSet):
    """API endpoints for medical imaging center profiles."""

    serializer_class = MedicalImagingCenterSerializer
    queryset = MedicalImagingCenter.objects.select_related("user", "provider").all()
    search_fields = ("license_number", "provider__provider_name", "user__username")
    ordering = ("license_number",)
    exact_filter_fields = {
        "user": "user_id",
        "provider": "provider_id",
    }
    role_permissions = {
        "create": [UserRole.ADMIN],
        "update": [UserRole.ADMIN, UserRole.IMAGING_CENTER],
        "partial_update": [UserRole.ADMIN, UserRole.IMAGING_CENTER],
        "destroy": [UserRole.ADMIN],
    }

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.ADMIN or user.is_superuser:
            return self.queryset
        if user.role == UserRole.IMAGING_CENTER:
            return self.queryset.filter(user=user)
        return self.queryset.none()


class MedicalCenterViewSet(BaseOwnedModelViewSet):
    """API endpoints for medical center profiles."""

    serializer_class = MedicalCenterSerializer
    queryset = MedicalCenter.objects.select_related("user", "provider").all()
    search_fields = ("license_number", "provider__provider_name", "user__username")
    ordering = ("license_number",)
    exact_filter_fields = {
        "user": "user_id",
        "provider": "provider_id",
    }
    role_permissions = {
        "create": [UserRole.ADMIN],
        "update": [UserRole.ADMIN, UserRole.MEDICAL_CENTER],
        "partial_update": [UserRole.ADMIN, UserRole.MEDICAL_CENTER],
        "destroy": [UserRole.ADMIN],
    }

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.ADMIN or user.is_superuser:
            return self.queryset
        if user.role == UserRole.MEDICAL_CENTER:
            return self.queryset.filter(user=user)
        return self.queryset.none()


class MedicationViewSet(BaseOwnedModelViewSet):
    """API endpoints for medications."""

    serializer_class = MedicationSerializer
    queryset = Medication.objects.all()
    search_fields = ("name", "generic_name", "strength", "manufacturer")
    ordering = ("name", "strength")
    exact_filter_fields = {
        "is_active": "is_active",
        "name": "name",
    }
    role_permissions = {
        "create": [UserRole.ADMIN, UserRole.DOCTOR],
        "update": [UserRole.ADMIN, UserRole.DOCTOR],
        "partial_update": [UserRole.ADMIN, UserRole.DOCTOR],
        "destroy": [UserRole.ADMIN],
    }

    def get_queryset(self):
        return self.queryset.filter(is_active=True) if not self.request.user.is_superuser else self.queryset


class PrescriptionViewSet(BaseOwnedModelViewSet):
    """API endpoints for prescriptions and nested prescription items."""

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
    search_fields = ("prescription_number", "employee__medical_record_number", "doctor__license_number", "status")
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
        user = self.request.user
        if user.role == "Admin" or user.is_superuser:
            return self.queryset
        if user.role == UserRole.EMPLOYEE:
            return self.queryset.filter(employee__user=user)
        if user.role == "Doctor":
            return self.queryset.filter(doctor__user=user)
        if user.role == "Pharmacist":
            return self.queryset.filter(service_type="Medication", status__in=["Approved", "Dispensed"]).distinct()
        if user.role == "InsuranceOfficer":
            return self.queryset.filter(insurance_request__isnull=False).distinct()
        return self.queryset.none()

    @transaction.atomic
    def perform_create(self, serializer):
        if self.request.user.role == UserRole.DOCTOR and not self.request.user.is_superuser:
            prescription = serializer.save(doctor=self.request.user.doctor_profile)
        else:
            prescription = serializer.save()
        self.log_action("Prescription created", prescription)
        notify_prescription_created(prescription)

    @transaction.atomic
    def perform_update(self, serializer):
        previous_status = serializer.instance.status
        prescription = serializer.save()
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
    """API endpoints for insurance requests."""

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
        "update": [UserRole.ADMIN],
        "partial_update": [UserRole.ADMIN],
        "destroy": [UserRole.ADMIN],
    }

    def get_queryset(self):
        user = self.request.user
        if user.role == "Admin" or user.is_superuser:
            return self.queryset
        if user.role == UserRole.EMPLOYEE:
            return self.queryset.filter(prescription__employee__user=user)
        if user.role == "Doctor":
            return self.queryset.filter(prescription__doctor__user=user)
        if user.role == "InsuranceOfficer":
            return self.queryset
        return self.queryset.none()

    @transaction.atomic
    def perform_update(self, serializer):
        previous_status = serializer.instance.status
        if (
            self.request.user.role == UserRole.INSURANCE_OFFICER
            and not self.request.user.is_superuser
        ):
            insurance_request = serializer.save(reviewed_by=self.request.user.insurance_officer_profile)
        else:
            insurance_request = serializer.save()
        if self.request.user.role == UserRole.INSURANCE_OFFICER and insurance_request.reviewed_by_id is None:
            insurance_request.reviewed_by = self.request.user.insurance_officer_profile
            insurance_request.reviewed_at = insurance_request.reviewed_at or timezone.now()
            insurance_request.save(update_fields=["reviewed_by", "reviewed_at", "updated_at"])
        if previous_status != insurance_request.status:
            prescription = insurance_request.prescription
            if insurance_request.status == "Approved":
                prescription.status = "Approved"
            elif insurance_request.status == "Rejected":
                prescription.status = "Rejected"
            elif insurance_request.status in {"Pending", "NeedsUpdate"}:
                prescription.status = "PendingInsuranceApproval"
            prescription.save(update_fields=["status", "updated_at"])
        self.log_action("Insurance request updated", insurance_request)
        notify_insurance_updated(insurance_request)

    @transaction.atomic
    def perform_create(self, serializer):
        review_payload = {
            "status": InsuranceRequestStatus.APPROVED,
            "reviewed_at": timezone.now(),
        }
        insurance_request = serializer.save(**review_payload)
        prescription = insurance_request.prescription
        prescription.status = "Approved"
        prescription.save(update_fields=["status", "updated_at"])
        self.log_action("Insurance request created", insurance_request)
        notify_insurance_updated(insurance_request)


class DispenseViewSet(BaseOwnedModelViewSet):
    """API endpoints for dispensed prescriptions."""

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
        user = self.request.user
        if user.role == "Admin" or user.is_superuser:
            return self.queryset
        if user.role == UserRole.EMPLOYEE:
            return self.queryset.filter(prescription__employee__user=user)
        if user.role == "Doctor":
            return self.queryset.filter(prescription__doctor__user=user)
        if user.role == "Pharmacist":
            return self.queryset.filter(pharmacist__user=user)
        return self.queryset.none()

    @transaction.atomic
    def perform_create(self, serializer):
        if self.request.user.role == UserRole.PHARMACIST and not self.request.user.is_superuser:
            dispense = serializer.save(pharmacist=self.request.user.pharmacist_profile)
        else:
            dispense = serializer.save()
        if dispense.status == "Completed":
            dispense.prescription.status = "Dispensed"
            dispense.prescription.save(update_fields=["status", "updated_at"])
        self.log_action("Dispense created", dispense)
        notify_dispense_updated(dispense)

    @transaction.atomic
    def perform_update(self, serializer):
        previous_status = serializer.instance.status
        dispense = serializer.save()
        if previous_status != dispense.status:
            if dispense.status == "Completed":
                dispense.prescription.status = "Dispensed"
            elif dispense.status in {"Partial", "Cancelled"}:
                dispense.prescription.status = "Approved"
            dispense.prescription.save(update_fields=["status", "updated_at"])
        self.log_action("Dispense updated", dispense)
        notify_dispense_updated(dispense)


class NotificationViewSet(BaseOwnedModelViewSet):
    """API endpoints for notifications."""

    serializer_class = NotificationSerializer
    queryset = Notification.objects.select_related("user").all()
    search_fields = ("title", "message", "notification_type", "user__username")
    ordering = ("-created_at",)
    exact_filter_fields = {
        "user": "user_id",
        "notification_type": "notification_type",
        "is_read": "is_read",
    }
    role_permissions = {
        "create": [UserRole.ADMIN],
        "update": [
            UserRole.ADMIN,
            UserRole.DOCTOR,
            UserRole.EMPLOYEE,
            UserRole.PHARMACIST,
            UserRole.LABORATORY,
            UserRole.IMAGING_CENTER,
            UserRole.MEDICAL_CENTER,
            UserRole.INSURANCE_OFFICER,
        ],
        "partial_update": [
            UserRole.ADMIN,
            UserRole.DOCTOR,
            UserRole.EMPLOYEE,
            UserRole.PHARMACIST,
            UserRole.LABORATORY,
            UserRole.IMAGING_CENTER,
            UserRole.MEDICAL_CENTER,
            UserRole.INSURANCE_OFFICER,
        ],
        "destroy": [UserRole.ADMIN],
    }

    def get_queryset(self):
        user = self.request.user
        if user.role == "Admin" or user.is_superuser:
            return self.queryset
        return self.queryset.filter(user=user)

    @action(detail=True, methods=["patch", "post"], url_path="mark-read")
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        serializer = self.get_serializer(
            notification,
            data={"is_read": True},
            partial=True,
        )
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return Response(serializer.data)

    @action(detail=True, methods=["patch", "post"], url_path="read")
    def read(self, request, pk=None):
        return self.mark_read(request, pk=pk)

    @action(detail=False, methods=["patch", "post"], url_path="mark-all-read")
    def mark_all_read(self, request):
        queryset = self.filter_queryset(self.get_queryset()).filter(is_read=False)
        updated_count = queryset.update(is_read=True, read_at=timezone.now())
        self.log_action("Notifications marked as read", details=f"count={updated_count}")
        return Response({"updated_count": updated_count})


    @action(detail=False, methods=["get"], url_path="unread-count")
    def unread_count(self, request):
        count = self.filter_queryset(self.get_queryset()).filter(is_read=False).count()
        return Response({"count": count})


class InsuranceOfficerViewSet(BaseOwnedModelViewSet):
    """API endpoints for insurance officer profiles."""

    serializer_class = InsuranceOfficerSerializer
    queryset = InsuranceOfficer.objects.select_related("user").all()
    search_fields = ("employee_id", "organization_name", "user__username", "user__first_name", "user__last_name")
    ordering = ("organization_name", "employee_id")
    exact_filter_fields = {
        "user": "user_id",
        "organization_name": "organization_name",
    }
    role_permissions = {
        "create": [UserRole.ADMIN],
        "update": [UserRole.ADMIN, UserRole.INSURANCE_OFFICER],
        "partial_update": [UserRole.ADMIN, UserRole.INSURANCE_OFFICER],
        "destroy": [UserRole.ADMIN],
    }

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.ADMIN or user.is_superuser:
            return self.queryset
        if user.role == UserRole.INSURANCE_OFFICER:
            return self.queryset.filter(user=user)
        return self.queryset.none()


class DependentViewSet(BaseOwnedModelViewSet):
    """API endpoints for employee beneficiaries."""

    serializer_class = DependentSerializer
    queryset = Dependent.objects.select_related("employee", "employee__user").all()
    search_fields = ("full_name", "relation", "employee__medical_record_number")
    ordering = ("full_name",)
    exact_filter_fields = {
        "employee": "employee_id",
        "relation": "relation",
    }
    role_permissions = {
        "create": [UserRole.ADMIN, UserRole.EMPLOYEE],
        "update": [UserRole.ADMIN, UserRole.EMPLOYEE],
        "partial_update": [UserRole.ADMIN, UserRole.EMPLOYEE],
        "destroy": [UserRole.ADMIN, UserRole.EMPLOYEE],
    }

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.ADMIN or user.is_superuser:
            return self.queryset
        if user.role == UserRole.EMPLOYEE:
            return self.queryset.filter(employee__user=user)
        if user.role == UserRole.DOCTOR:
            return self.queryset.filter(medical_orders__doctor__user=user).distinct()
        return self.queryset.none()

    def perform_create(self, serializer):
        if self.request.user.role == UserRole.EMPLOYEE and not self.request.user.is_superuser:
            dependent = serializer.save(employee=self.request.user.employee_profile)
        else:
            dependent = serializer.save()
        self.log_action("Dependent created", dependent)


class AuditLogViewSet(BaseOwnedModelViewSet):
    """Read-only API endpoints for audit logs."""

    serializer_class = AuditLogSerializer
    queryset = AuditLog.objects.select_related("actor").all()
    search_fields = ("action", "target_model", "target_id", "actor__username")
    ordering = ("-created_at",)
    exact_filter_fields = {
        "actor": "actor_id",
        "target_model": "target_model",
        "target_id": "target_id",
    }
    http_method_names = ["get", "head", "options"]
    role_permissions = {
        "*": [UserRole.ADMIN],
    }

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.ADMIN or user.is_superuser:
            return self.queryset
        return self.queryset.none()
