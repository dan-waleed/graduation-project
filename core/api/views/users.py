from django.contrib.auth import get_user_model

from core.models import Dependent, Doctor, Employee, InsuranceOfficer, LEGACY_PROVIDER_ROLES, UserRole
from core.services import apply_role_scope, is_admin_user
from core.api.serializers import (
    DependentSerializer,
    DoctorSerializer,
    DoctorSerializerForPUT,
    EmployeeSerializer,
    InsuranceOfficerSerializer,
    UserSerializer,
    UserUpdateSerializer,
)

from .common import BaseOwnedModelViewSet

User = get_user_model()


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
            UserRole.INSURANCE_OFFICER,
        ],
    }

    def get_serializer_class(self):
        if self.action in {"update", "partial_update"}:
            return UserUpdateSerializer
        return UserSerializer

    def get_queryset(self):
        user = self.request.user
        if is_admin_user(user):
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
        return apply_role_scope(
            self.queryset,
            self.request.user,
            {
                UserRole.EMPLOYEE: lambda queryset, user: queryset.filter(user=user),
                UserRole.DOCTOR: lambda queryset, user: queryset,
                UserRole.PHARMACIST: lambda queryset, user: queryset.filter(
                    prescriptions__dispenses__pharmacist__user=user
                ).distinct(),
                UserRole.INSURANCE_OFFICER: lambda queryset, user: queryset.filter(
                    medical_orders__insurance_request__isnull=False
                ).distinct(),
            },
        )


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

    def get_serializer_class(self):
        if self.action in {"update", "partial_update"}:
            return DoctorSerializerForPUT
        return DoctorSerializer

    def get_queryset(self):
        return apply_role_scope(
            self.queryset,
            self.request.user,
            {
                UserRole.DOCTOR: lambda queryset, user: queryset.filter(user=user),
            },
        )


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
        return apply_role_scope(
            self.queryset,
            self.request.user,
            {
                UserRole.INSURANCE_OFFICER: lambda queryset, user: queryset.filter(user=user),
            },
        )


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
        return apply_role_scope(
            self.queryset,
            self.request.user,
            {
                UserRole.EMPLOYEE: lambda queryset, user: queryset.filter(employee__user=user),
                UserRole.DOCTOR: lambda queryset, user: queryset.filter(medical_orders__doctor__user=user).distinct(),
            },
        )

    def perform_create(self, serializer):
        if self.request.user.role == UserRole.EMPLOYEE and not self.request.user.is_superuser:
            dependent = serializer.save(employee=self.request.user.employee_profile)
        else:
            dependent = serializer.save()
        self.log_action("Dependent created", dependent)
