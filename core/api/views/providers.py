from core.models import (
    Laboratory,
    MedicalCenter,
    MedicalImagingCenter,
    MedicalService,
    Medication,
    Pharmacist,
    Pharmacy,
    Provider,
    ProviderServicePrice,
    UserRole,
)
from core.services import apply_role_scope, is_admin_user
from core.api.serializers import (
    LaboratorySerializer,
    MedicalCenterSerializer,
    MedicalImagingCenterSerializer,
    MedicalServiceSerializer,
    MedicationSerializer,
    PharmacistSerializer,
    PharmacySerializer,
    ProviderSerializer,
    ProviderServicePriceSerializer,
)

from .common import BaseOwnedModelViewSet


class PharmacyViewSet(BaseOwnedModelViewSet):
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
        return apply_role_scope(
            self.queryset,
            self.request.user,
            {
                UserRole.PHARMACIST: lambda queryset, user: queryset.filter(pharmacists__user=user).distinct(),
            },
            default_all=True,
        )


class ProviderViewSet(BaseOwnedModelViewSet):
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
        return apply_role_scope(
            self.queryset,
            self.request.user,
            {
                UserRole.PHARMACIST: lambda queryset, user: queryset.filter(user=user),
            },
        )


class LaboratoryViewSet(BaseOwnedModelViewSet):
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
        return apply_role_scope(
            self.queryset,
            self.request.user,
            {
                UserRole.LABORATORY: lambda queryset, user: queryset.filter(user=user),
            },
        )


class MedicalImagingCenterViewSet(BaseOwnedModelViewSet):
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
        return apply_role_scope(
            self.queryset,
            self.request.user,
            {
                UserRole.IMAGING_CENTER: lambda queryset, user: queryset.filter(user=user),
            },
        )


class MedicalCenterViewSet(BaseOwnedModelViewSet):
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
        return apply_role_scope(
            self.queryset,
            self.request.user,
            {
                UserRole.MEDICAL_CENTER: lambda queryset, user: queryset.filter(user=user),
            },
        )


class MedicationViewSet(BaseOwnedModelViewSet):
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
        return self.queryset if is_admin_user(self.request.user) else self.queryset.filter(is_active=True)
