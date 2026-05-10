from decimal import Decimal

from django.contrib.auth import get_user_model
from django.contrib.auth import authenticate
from django.db import transaction
from django.utils import timezone
from django.utils.text import slugify
from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field

from .models import (
    AuditLog,
    ContractStatus,
    Dependent,
    DependentRelation,
    Dispense,
    DispenseStatus,
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
    PrescriptionStatus,
    Pharmacist,
    Pharmacy,
    Prescription,
    PrescriptionItem,
    Provider,
    ProviderServicePrice,
    ProviderType,
    ServiceType,
    UserRole,
)

User = get_user_model()


def _split_full_name(full_name):
    normalized = " ".join((full_name or "").split()).strip()
    if not normalized:
        return "", ""
    parts = normalized.split(" ", 1)
    if len(parts) == 1:
        return parts[0], ""
    return parts[0], parts[1]


def _build_unique_username(email="", full_name="", fallback_prefix="employee"):
    base = ""
    if email:
        base = email.split("@", 1)[0]
    if not base and full_name:
        base = slugify(full_name.replace(" ", ".")) or slugify(full_name) or fallback_prefix
    base = base or fallback_prefix
    candidate = base
    suffix = 1
    while User.objects.filter(username=candidate).exists():
        suffix += 1
        candidate = f"{base}{suffix}"
    return candidate


def _ensure_role_profile(user):
    if user.role == "Admin":
        return

    if user.role == UserRole.EMPLOYEE:
        Employee.objects.get_or_create(
            user=user,
            defaults={
                "medical_record_number": f"MRN-{user.id:04d}",
                "insurance_provider": "",
                "address": "",
            },
        )
        return

    if user.role == "Doctor":
        provider, _ = Provider.objects.get_or_create(
            provider_name=f"Clinic {user.id:04d}",
            provider_type=ProviderType.DOCTOR,
            defaults={
                "city": "",
                "address": "",
                "phone": "",
                "google_maps_url": "",
                "working_hours": "",
                "contract_status": ContractStatus.ACTIVE,
            },
        )
        Doctor.objects.get_or_create(
            user=user,
            defaults={
                "license_number": f"DOC-{user.id:04d}",
                "specialization": "عام",
                "clinic_name": "عيادة HealthBridge",
                "clinic_address": "",
                "consultation_price": 0,
                "contract_status": ContractStatus.ACTIVE,
            },
        )
        return

    if user.role == "InsuranceOfficer":
        InsuranceOfficer.objects.get_or_create(
            user=user,
            defaults={
                "organization_name": "قسم التأمين الصحي",
                "employee_id": f"INS-{user.id:04d}",
            },
        )
        return

    if user.role == "Pharmacist":
        pharmacy, _ = Pharmacy.objects.get_or_create(
            license_number="PHA-DEFAULT-001",
            defaults={
                "name": "صيدلية النظام",
                "address": "الفرع الرئيسي",
                "phone_number": "",
                "is_active": True,
            },
        )
        Pharmacist.objects.get_or_create(
            user=user,
            defaults={
                "pharmacy": pharmacy,
                "license_number": f"PHARM-{user.id:04d}",
            },
        )
        return

    if user.role == UserRole.LABORATORY:
        provider, _ = Provider.objects.get_or_create(
            provider_name=f"Laboratory {user.id:04d}",
            provider_type=ProviderType.LABORATORY,
            defaults={"contract_status": ContractStatus.ACTIVE},
        )
        Laboratory.objects.get_or_create(
            user=user,
            defaults={
                "provider": provider,
                "license_number": f"LAB-{user.id:04d}",
            },
        )
        return

    if user.role == UserRole.IMAGING_CENTER:
        provider, _ = Provider.objects.get_or_create(
            provider_name=f"Imaging Center {user.id:04d}",
            provider_type=ProviderType.IMAGING_CENTER,
            defaults={"contract_status": ContractStatus.ACTIVE},
        )
        MedicalImagingCenter.objects.get_or_create(
            user=user,
            defaults={
                "provider": provider,
                "license_number": f"IMG-{user.id:04d}",
            },
        )
        return

    if user.role == UserRole.MEDICAL_CENTER:
        provider, _ = Provider.objects.get_or_create(
            provider_name=f"Medical Center {user.id:04d}",
            provider_type=ProviderType.MEDICAL_CENTER,
            defaults={"contract_status": ContractStatus.ACTIVE},
        )
        MedicalCenter.objects.get_or_create(
            user=user,
            defaults={
                "provider": provider,
                "license_number": f"MED-{user.id:04d}",
            },
        )


PRESCRIPTION_ALLOWED_TRANSITIONS = {
    PrescriptionStatus.DRAFT: {PrescriptionStatus.SENT, PrescriptionStatus.CANCELLED},
    PrescriptionStatus.SENT: {
        PrescriptionStatus.PENDING_EMPLOYEE_SELECTION,
        PrescriptionStatus.PENDING_INSURANCE_APPROVAL,
        PrescriptionStatus.APPROVED,
        PrescriptionStatus.REJECTED,
        PrescriptionStatus.CANCELLED,
    },
    PrescriptionStatus.PENDING_EMPLOYEE_SELECTION: {
        PrescriptionStatus.PENDING_INSURANCE_APPROVAL,
        PrescriptionStatus.APPROVED,
        PrescriptionStatus.REJECTED,
        PrescriptionStatus.CANCELLED,
    },
    PrescriptionStatus.PENDING_INSURANCE_APPROVAL: {
        PrescriptionStatus.APPROVED,
        PrescriptionStatus.REJECTED,
        PrescriptionStatus.CANCELLED,
    },
    PrescriptionStatus.APPROVED: {
        PrescriptionStatus.DISPENSED,
        PrescriptionStatus.PERFORMED,
        PrescriptionStatus.CANCELLED,
        PrescriptionStatus.EXPIRED,
    },
    PrescriptionStatus.REJECTED: {PrescriptionStatus.SENT, PrescriptionStatus.CANCELLED},
    PrescriptionStatus.DISPENSED: set(),
    PrescriptionStatus.PERFORMED: set(),
    PrescriptionStatus.CANCELLED: set(),
    PrescriptionStatus.EXPIRED: set(),
}


INSURANCE_ALLOWED_TRANSITIONS = {
    InsuranceRequestStatus.PENDING: {
        InsuranceRequestStatus.APPROVED,
        InsuranceRequestStatus.REJECTED,
        InsuranceRequestStatus.NEEDS_UPDATE,
    },
    InsuranceRequestStatus.NEEDS_UPDATE: {
        InsuranceRequestStatus.PENDING,
        InsuranceRequestStatus.APPROVED,
        InsuranceRequestStatus.REJECTED,
    },
    InsuranceRequestStatus.APPROVED: set(),
    InsuranceRequestStatus.REJECTED: set(),
}


DISPENSE_ALLOWED_TRANSITIONS = {
    DispenseStatus.PARTIAL: {DispenseStatus.COMPLETED, DispenseStatus.CANCELLED},
    DispenseStatus.COMPLETED: set(),
    DispenseStatus.CANCELLED: set(),
}


class UserSerializer(serializers.ModelSerializer):
    """Serializer for the custom user model."""

    password = serializers.CharField(write_only=True, required=False, style={"input_type": "password"})

    class Meta:
        model = User
        fields = (
            "id",
            "username",
            "first_name",
            "last_name",
            "email",
            "phone_number",
            "role",
            "is_active",
            "is_staff",
            "created_at",
            "updated_at",
            "password",
        )
        read_only_fields = ("id", "created_at", "updated_at")

    @transaction.atomic
    def create(self, validated_data):
        password = validated_data.pop("password", None)
        role = validated_data.get("role")
        if role == "Admin":
            validated_data["is_staff"] = True
        user = User(**validated_data)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save()
        _ensure_role_profile(user)
        return user

    @transaction.atomic
    def update(self, instance, validated_data):
        password = validated_data.pop("password", None)
        role = validated_data.get("role", instance.role)
        if role == "Admin":
            validated_data["is_staff"] = True
        elif not instance.is_superuser:
            validated_data["is_staff"] = False
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        _ensure_role_profile(instance)
        return instance


class LoginRequestSerializer(serializers.Serializer):
    """Validate login credentials for token authentication."""

    username = serializers.CharField()
    password = serializers.CharField(style={"input_type": "password"}, trim_whitespace=False)

    def validate(self, attrs):
        username = attrs.get("username")
        password = attrs.get("password")
        request = self.context.get("request")
        user = authenticate(request=request, username=username, password=password)
        if user is None:
            raise serializers.ValidationError({"detail": "اسم المستخدم أو كلمة المرور غير صحيحة."})
        if not user.is_active:
            raise serializers.ValidationError({"detail": "هذا الحساب غير مفعّل حاليًا."})
        attrs["user"] = user
        return attrs


class LoginResponseSerializer(serializers.Serializer):
    """Schema serializer for login responses."""

    token = serializers.CharField()
    user = UserSerializer()


class LogoutResponseSerializer(serializers.Serializer):
    """Schema serializer for logout responses."""

    detail = serializers.CharField()


class DashboardMetricSerializer(serializers.Serializer):
    """Compact serializer for dashboard metric cards."""

    key = serializers.CharField()
    label = serializers.CharField()
    value = serializers.IntegerField()
    icon = serializers.CharField()


class DashboardActivitySerializer(serializers.Serializer):
    """Compact serializer for recent activity feed items."""

    title = serializers.CharField()
    subtitle = serializers.CharField()
    status = serializers.CharField(allow_blank=True)
    created_at = serializers.DateTimeField(allow_null=True)


class DashboardSummarySerializer(serializers.Serializer):
    """Role-aware dashboard summary payload."""

    role = serializers.CharField()
    title = serializers.CharField()
    subtitle = serializers.CharField()
    metrics = DashboardMetricSerializer(many=True)
    recent_activity = DashboardActivitySerializer(many=True)


class EmployeeCreateUserSerializer(serializers.Serializer):
    """Serializer for nested user payloads used during employee creation."""

    full_name = serializers.CharField(required=False, allow_blank=False)
    email = serializers.EmailField(required=False)
    phone = serializers.CharField(required=False, allow_blank=True)
    phone_number = serializers.CharField(required=False, allow_blank=True)
    password = serializers.CharField(required=False, write_only=True, style={"input_type": "password"})
    username = serializers.CharField(required=False, allow_blank=False)
    first_name = serializers.CharField(required=False, allow_blank=True)
    last_name = serializers.CharField(required=False, allow_blank=True)
    is_active = serializers.BooleanField(required=False)

    def validate(self, attrs):
        full_name = attrs.get("full_name", "").strip()
        first_name = attrs.get("first_name", "").strip()
        last_name = attrs.get("last_name", "").strip()
        email = attrs.get("email", "").strip()

        if not full_name and not first_name and not email:
            raise serializers.ValidationError(
                {"full_name": "يجب توفير full_name أو first_name على الأقل عند إنشاء المستخدم."}
            )

        if not attrs.get("username"):
            attrs["username"] = _build_unique_username(email=email, full_name=full_name)

        if full_name and not first_name:
            generated_first_name, generated_last_name = _split_full_name(full_name)
            attrs["first_name"] = generated_first_name
            attrs["last_name"] = last_name or generated_last_name

        if "phone" in attrs and "phone_number" not in attrs:
            attrs["phone_number"] = attrs["phone"]

        return attrs


class EmployeeSerializer(serializers.ModelSerializer):
    """Serializer for employee profiles."""

    user = EmployeeCreateUserSerializer(write_only=True, required=False)
    user_details = UserSerializer(source="user", read_only=True)
    full_name = serializers.CharField(source="user.get_full_name", read_only=True)
    email = serializers.EmailField(source="user.email", read_only=True)
    phone_number = serializers.CharField(source="user.phone_number", read_only=True)
    username = serializers.CharField(source="user.username", read_only=True)
    dependents = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Employee
        fields = (
            "id",
            "user",
            "user_details",
            "username",
            "full_name",
            "email",
            "phone_number",
            "national_id",
            "university_id",
            "insurance_number",
            "medical_record_number",
            "date_of_birth",
            "gender",
            "address",
            "insurance_provider",
            "dependents",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at", "user_details")
        extra_kwargs = {
            "national_id": {"required": False, "allow_blank": True},
            "university_id": {"required": False, "allow_blank": True},
            "insurance_number": {"required": False, "allow_blank": True},
            "medical_record_number": {"required": False},
            "date_of_birth": {"required": False, "allow_null": True},
            "gender": {"required": False, "allow_blank": True},
            "address": {"required": False, "allow_blank": True},
            "insurance_provider": {"required": False, "allow_blank": True},
        }

    def get_dependents(self, obj):
        return DependentSerializer(obj.beneficiaries.all(), many=True).data

    def validate_user(self, value):
        if isinstance(value, dict):
            serializer = EmployeeCreateUserSerializer(data=value)
            serializer.is_valid(raise_exception=True)
            return serializer.validated_data
        if isinstance(value, User):
            return value
        if isinstance(value, int):
            try:
                return User.objects.get(pk=value)
            except User.DoesNotExist as exc:
                raise serializers.ValidationError("المستخدم المحدد غير موجود.") from exc
        raise serializers.ValidationError("حقل user يجب أن يكون كائنًا أو معرف مستخدم صالحًا.")

    def validate(self, attrs):
        attrs = super().validate(attrs)
        request = self.context.get("request")
        if self.instance is None and "user" not in attrs:
            raise serializers.ValidationError({"user": "حقل user مطلوب عند إنشاء الموظف الجامعي."})

        dependents_payload = []
        initial_dependents = self.initial_data.get("dependents", None)
        if initial_dependents is not None:
            dependent_serializer = DependentSerializer(data=initial_dependents, many=True)
            try:
                dependent_serializer.is_valid(raise_exception=True)
            except serializers.ValidationError as exc:
                raise serializers.ValidationError({"dependents": exc.detail}) from exc
            dependents_payload = dependent_serializer.validated_data

        attrs["dependents_payload"] = dependents_payload

        if self.instance is not None and request and request.user.role == UserRole.EMPLOYEE:
            attrs.pop("user", None)

        return attrs

    @transaction.atomic
    def create(self, validated_data):
        user_payload = validated_data.pop("user", None)
        dependents_payload = validated_data.pop("dependents_payload", [])

        if isinstance(user_payload, User):
            user = user_payload
        else:
            user_data = dict(user_payload or {})
            user_data["role"] = UserRole.EMPLOYEE
            user_serializer = UserSerializer(data=user_data, context=self.context)
            user_serializer.is_valid(raise_exception=True)
            user = user_serializer.save()

        employee = Employee.objects.filter(user=user).first()
        if employee is None:
            validated_data.setdefault("medical_record_number", f"MRN-{user.id:04d}")
            employee = Employee.objects.create(user=user, **validated_data)
        else:
            for attr, value in validated_data.items():
                setattr(employee, attr, value)
            employee.save()

        self._create_dependents(employee, dependents_payload)
        return employee

    @transaction.atomic
    def update(self, instance, validated_data):
        validated_data.pop("dependents_payload", None)
        validated_data.pop("user", None)
        return super().update(instance, validated_data)

    def _create_dependents(self, employee, dependents_payload):
        if employee.pk is None:
            raise serializers.ValidationError({"dependents": "لا يمكن إنشاء المستفيدين قبل إنشاء الموظف الجامعي."})
        for dependent_data in dependents_payload:
            Dependent.objects.create(employee=employee, **dependent_data)


class DoctorSerializer(serializers.ModelSerializer):
    """Serializer for doctor profiles."""

    user_details = UserSerializer(source="user", read_only=True)
    provider_name = serializers.CharField(source="provider.provider_name", read_only=True)
    provider_city = serializers.CharField(source="provider.city", read_only=True)
    provider_address = serializers.CharField(source="provider.address", read_only=True)

    class Meta:
        model = Doctor
        fields = (
            "id",
            "user",
            "user_details",
            "license_number",
            "specialization",
            "clinic_name",
            "clinic_address",
            "consultation_price",
            "contract_status",
            "provider_name",
            "provider_city",
            "provider_address",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "created_at",
            "updated_at",
            "user_details",
            "provider_name",
            "provider_city",
            "provider_address",
        )


class ProviderSerializer(serializers.ModelSerializer):
    """Serializer for healthcare providers."""

    class Meta:
        model = Provider
        fields = (
            "id",
            "provider_name",
            "provider_type",
            "city",
            "address",
            "phone",
            "latitude",
            "longitude",
            "google_maps_url",
            "working_hours",
            "contract_status",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")


class MedicalServiceSerializer(serializers.ModelSerializer):
    """Serializer for supported medical services."""

    class Meta:
        model = MedicalService
        fields = (
            "id",
            "service_name",
            "service_type",
            "default_price",
            "requires_insurance_approval",
            "coverage_percentage",
            "employee_share",
            "description",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")


class ProviderServicePriceSerializer(serializers.ModelSerializer):
    """Serializer for provider-specific service pricing."""

    provider_name = serializers.CharField(source="provider.provider_name", read_only=True)
    service_name = serializers.CharField(source="service.service_name", read_only=True)

    class Meta:
        model = ProviderServicePrice
        fields = (
            "id",
            "provider",
            "provider_name",
            "service",
            "service_name",
            "price",
            "coverage_percentage",
            "covered_amount_limit",
            "employee_share",
            "is_available",
            "requires_pre_approval",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at", "provider_name", "service_name")


class PharmacySerializer(serializers.ModelSerializer):
    """Serializer for pharmacies."""

    class Meta:
        model = Pharmacy
        fields = (
            "id",
            "name",
            "license_number",
            "address",
            "phone_number",
            "is_active",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")


class PharmacistSerializer(serializers.ModelSerializer):
    """Serializer for pharmacist profiles."""

    user_details = UserSerializer(source="user", read_only=True)
    pharmacy_name = serializers.CharField(source="pharmacy.name", read_only=True)

    class Meta:
        model = Pharmacist
        fields = (
            "id",
            "user",
            "user_details",
            "pharmacy",
            "pharmacy_name",
            "license_number",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at", "user_details", "pharmacy_name")


class LaboratorySerializer(serializers.ModelSerializer):
    """Serializer for laboratory profiles."""

    user_details = UserSerializer(source="user", read_only=True)
    provider_details = ProviderSerializer(source="provider", read_only=True)

    class Meta:
        model = Laboratory
        fields = (
            "id",
            "user",
            "user_details",
            "provider",
            "provider_details",
            "license_number",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at", "user_details", "provider_details")


class MedicalImagingCenterSerializer(serializers.ModelSerializer):
    """Serializer for medical imaging center profiles."""

    user_details = UserSerializer(source="user", read_only=True)
    provider_details = ProviderSerializer(source="provider", read_only=True)

    class Meta:
        model = MedicalImagingCenter
        fields = (
            "id",
            "user",
            "user_details",
            "provider",
            "provider_details",
            "license_number",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at", "user_details", "provider_details")


class MedicalCenterSerializer(serializers.ModelSerializer):
    """Serializer for medical center profiles."""

    user_details = UserSerializer(source="user", read_only=True)
    provider_details = ProviderSerializer(source="provider", read_only=True)

    class Meta:
        model = MedicalCenter
        fields = (
            "id",
            "user",
            "user_details",
            "provider",
            "provider_details",
            "license_number",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at", "user_details", "provider_details")


class InsuranceOfficerSerializer(serializers.ModelSerializer):
    """Serializer for insurance officer profiles."""

    user_details = UserSerializer(source="user", read_only=True)

    class Meta:
        model = InsuranceOfficer
        fields = (
            "id",
            "user",
            "user_details",
            "organization_name",
            "employee_id",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at", "user_details")


class DependentSerializer(serializers.ModelSerializer):
    """Serializer for employee beneficiaries."""

    employee_record_number = serializers.CharField(source="employee.medical_record_number", read_only=True)
    relationship = serializers.CharField(source="relation", read_only=True)

    class Meta:
        model = Dependent
        fields = (
            "id",
            "employee",
            "employee_record_number",
            "full_name",
            "national_id",
            "relation",
            "relationship",
            "date_of_birth",
            "is_active",
            "notes",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at", "employee_record_number")
        extra_kwargs = {
            "employee": {"required": False},
            "notes": {"required": False, "allow_blank": True},
            "national_id": {"required": False, "allow_blank": True},
            "date_of_birth": {"required": False, "allow_null": True},
            "is_active": {"required": False},
        }

    def validate_full_name(self, value):
        if not value.strip():
            raise serializers.ValidationError("full_name للمستفيد إجباري.")
        return value

    def validate_relation(self, value):
        allowed_values = {choice for choice, _label in DependentRelation.choices}
        if value not in allowed_values:
            raise serializers.ValidationError("relation لا يقبل إلا son أو daughter أو wife أو husband.")
        return value


class MedicationSerializer(serializers.ModelSerializer):
    """Serializer for medications."""

    class Meta:
        model = Medication
        fields = (
            "id",
            "name",
            "generic_name",
            "strength",
            "dosage_form",
            "manufacturer",
            "description",
            "is_active",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")


class PrescriptionItemSerializer(serializers.ModelSerializer):
    """Serializer for medication line items inside a medical order."""

    medication_name = serializers.CharField(source="medication.name", read_only=True)

    class Meta:
        model = PrescriptionItem
        fields = (
            "id",
            "prescription",
            "medication",
            "medication_name",
            "dosage_instructions",
            "quantity",
            "duration",
            "substitution_allowed",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at", "medication_name")
        extra_kwargs = {"prescription": {"required": False}}


class PrescriptionSerializer(serializers.ModelSerializer):
    """Serializer for medical orders with optional medication line items."""

    items = PrescriptionItemSerializer(many=True)
    patient = serializers.PrimaryKeyRelatedField(source="employee", queryset=Employee.objects.all(), required=False)
    dependent = serializers.PrimaryKeyRelatedField(source="beneficiary", queryset=Dependent.objects.all(), required=False, allow_null=True)
    employee_record_number = serializers.CharField(source="employee.medical_record_number", read_only=True)
    employee_name = serializers.SerializerMethodField()
    doctor_license_number = serializers.CharField(source="doctor.license_number", read_only=True)
    doctor_name = serializers.SerializerMethodField()
    beneficiary_name = serializers.CharField(source="beneficiary.full_name", read_only=True)
    provider_name = serializers.CharField(source="provider.provider_name", read_only=True)
    service_name = serializers.CharField(source="service.service_name", read_only=True)
    qr_payload = serializers.SerializerMethodField()
    patient_name = serializers.SerializerMethodField(read_only=True)
    dependent_name = serializers.CharField(source="beneficiary.full_name", read_only=True)

    class Meta:
        model = Prescription
        fields = (
            "id",
            "patient",
            "prescription_number",
            "employee",
            "employee_record_number",
            "employee_name",
            "patient_name",
            "doctor",
            "doctor_license_number",
            "doctor_name",
            "dependent",
            "beneficiary",
            "beneficiary_name",
            "dependent_name",
            "provider",
            "provider_name",
            "service",
            "service_name",
            "service_type",
            "status",
            "requires_insurance_approval",
            "coverage_percentage",
            "covered_amount",
            "employee_share",
            "final_price",
            "diagnosis",
            "notes",
            "provider_notes",
            "report_attachment_url",
            "issued_at",
            "performed_at",
            "valid_until",
            "qr_payload",
            "items",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "created_at",
            "updated_at",
            "employee_record_number",
            "employee_name",
            "patient_name",
            "doctor_license_number",
            "doctor_name",
            "beneficiary_name",
            "dependent_name",
            "provider_name",
            "service_name",
            "qr_payload",
        )

    def validate(self, attrs):
        employee = attrs.get("employee", getattr(self.instance, "employee", None))
        beneficiary = attrs.get("beneficiary", getattr(self.instance, "beneficiary", None))
        new_status = attrs.get("status", getattr(self.instance, "status", None))
        service_type = attrs.get("service_type", getattr(self.instance, "service_type", ServiceType.MEDICATION))
        items = attrs.get("items", None)
        if beneficiary and employee and beneficiary.employee_id != employee.id:
            raise serializers.ValidationError({"beneficiary": "Selected beneficiary does not belong to this employee."})
        if self.instance and "status" in attrs:
            current_status = self.instance.status
            if new_status != current_status and new_status not in PRESCRIPTION_ALLOWED_TRANSITIONS[current_status]:
                raise serializers.ValidationError(
                    {"status": f"لا يمكن تغيير حالة الطلب الطبي من {current_status} إلى {new_status}."}
                )
        if self.instance is None and service_type == ServiceType.MEDICATION and not attrs.get("items"):
            raise serializers.ValidationError({"items": "Medication orders must include at least one medication item."})
        if items is not None and service_type != ServiceType.MEDICATION and items:
            raise serializers.ValidationError({"items": "Only medication orders may include medication items."})
        return attrs

    def _apply_coverage_calculations(self, payload):
        service = payload.get("service")
        provider = payload.get("provider")

        if service is None:
            return payload

        provider_price = None
        if provider is not None:
            provider_price = ProviderServicePrice.objects.filter(
                provider=provider,
                service=service,
                is_available=True,
            ).first()

        base_price = provider_price.price if provider_price is not None else service.default_price
        coverage_percentage = (
            provider_price.coverage_percentage if provider_price is not None else service.coverage_percentage
        )
        requires_approval = (
            provider_price.requires_pre_approval
            if provider_price is not None
            else service.requires_insurance_approval
        )
        covered_amount = (base_price * coverage_percentage) / Decimal("100")
        employee_share = base_price - covered_amount

        payload.setdefault("final_price", base_price)
        payload["coverage_percentage"] = coverage_percentage
        payload["covered_amount"] = covered_amount
        payload["employee_share"] = employee_share
        payload["requires_insurance_approval"] = requires_approval
        return payload

    def create(self, validated_data):
        items_data = validated_data.pop("items", [])
        validated_data = self._apply_coverage_calculations(validated_data)
        prescription = Prescription.objects.create(**validated_data)
        for item_data in items_data:
            PrescriptionItem.objects.create(prescription=prescription, **item_data)
        return prescription

    def update(self, instance, validated_data):
        items_data = validated_data.pop("items", None)
        merged_data = {
            "service": validated_data.get("service", instance.service),
            "provider": validated_data.get("provider", instance.provider),
            "final_price": validated_data.get("final_price", instance.final_price),
            "coverage_percentage": validated_data.get("coverage_percentage", instance.coverage_percentage),
            "covered_amount": validated_data.get("covered_amount", instance.covered_amount),
            "employee_share": validated_data.get("employee_share", instance.employee_share),
            "requires_insurance_approval": validated_data.get(
                "requires_insurance_approval",
                instance.requires_insurance_approval,
            ),
        }
        recalculated = self._apply_coverage_calculations(merged_data)
        validated_data.update(
            {
                "final_price": recalculated.get("final_price"),
                "coverage_percentage": recalculated.get("coverage_percentage"),
                "covered_amount": recalculated.get("covered_amount"),
                "employee_share": recalculated.get("employee_share"),
                "requires_insurance_approval": recalculated.get("requires_insurance_approval"),
            }
        )
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if items_data is not None:
            instance.items.all().delete()
            for item_data in items_data:
                PrescriptionItem.objects.create(prescription=instance, **item_data)

        return instance

    @extend_schema_field({"type": "object"})
    def get_qr_payload(self, obj):
        return {
            "prescription_number": obj.prescription_number,
            "employee_id": obj.employee_id,
            "doctor_id": obj.doctor_id,
            "beneficiary_id": obj.beneficiary_id,
            "service_type": obj.service_type,
            "status": obj.status,
        }

    @extend_schema_field(str)
    def get_employee_name(self, obj):
        return obj.employee.user.get_full_name() or obj.employee.user.username

    @extend_schema_field(str)
    def get_patient_name(self, obj):
        return self.get_employee_name(obj)

    @extend_schema_field(str)
    def get_doctor_name(self, obj):
        return obj.doctor.user.get_full_name() or obj.doctor.user.username


class InsuranceRequestSerializer(serializers.ModelSerializer):
    """Serializer for insurance approval requests."""

    prescription_number = serializers.CharField(source="prescription.prescription_number", read_only=True)
    reviewed_by_name = serializers.CharField(source="reviewed_by.user.username", read_only=True)
    employee_name = serializers.SerializerMethodField()
    doctor_name = serializers.SerializerMethodField()
    beneficiary_name = serializers.CharField(source="prescription.beneficiary.full_name", read_only=True)
    provider_name = serializers.CharField(source="prescription.provider.provider_name", read_only=True)
    service_name = serializers.CharField(source="prescription.service.service_name", read_only=True)
    service_type = serializers.CharField(source="prescription.service_type", read_only=True)
    total_price = serializers.DecimalField(source="prescription.final_price", max_digits=10, decimal_places=2, read_only=True)
    coverage_percentage = serializers.DecimalField(source="prescription.coverage_percentage", max_digits=5, decimal_places=2, read_only=True)
    covered_amount = serializers.DecimalField(source="prescription.covered_amount", max_digits=10, decimal_places=2, read_only=True)
    employee_share = serializers.DecimalField(source="prescription.employee_share", max_digits=10, decimal_places=2, read_only=True)
    prescription_status = serializers.CharField(source="prescription.status", read_only=True)

    class Meta:
        model = InsuranceRequest
        fields = (
            "id",
            "prescription",
            "prescription_number",
            "employee_name",
            "doctor_name",
            "beneficiary_name",
            "provider_name",
            "service_name",
            "service_type",
            "total_price",
            "coverage_percentage",
            "covered_amount",
            "employee_share",
            "prescription_status",
            "reviewed_by",
            "reviewed_by_name",
            "request_number",
            "status",
            "submitted_at",
            "reviewed_at",
            "response_notes",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at", "prescription_number", "reviewed_by_name")

    def validate(self, attrs):
        prescription = attrs.get("prescription", getattr(self.instance, "prescription", None))
        new_status = attrs.get("status", getattr(self.instance, "status", None))

        if self.instance is None and prescription.status not in {
            PrescriptionStatus.SENT,
            PrescriptionStatus.PENDING_INSURANCE_APPROVAL,
            PrescriptionStatus.APPROVED,
        }:
            raise serializers.ValidationError(
                {"prescription": "يمكن إنشاء طلب تأمين فقط للطلبات الطبية المرسلة أو قيد اعتماد التأمين."}
            )

        if self.instance and "status" in attrs:
            current_status = self.instance.status
            if new_status != current_status and new_status not in INSURANCE_ALLOWED_TRANSITIONS[current_status]:
                raise serializers.ValidationError(
                    {"status": f"لا يمكن تغيير حالة طلب التأمين من {current_status} إلى {new_status}."}
                )
        return attrs

    @extend_schema_field(str)
    def get_employee_name(self, obj):
        return obj.prescription.employee.user.get_full_name() or obj.prescription.employee.user.username

    @extend_schema_field(str)
    def get_doctor_name(self, obj):
        return obj.prescription.doctor.user.get_full_name() or obj.prescription.doctor.user.username


class DispenseSerializer(serializers.ModelSerializer):
    """Serializer for dispense records."""

    prescription_number = serializers.CharField(source="prescription.prescription_number", read_only=True)
    pharmacist_name = serializers.CharField(source="pharmacist.user.username", read_only=True)
    employee_name = serializers.SerializerMethodField()

    class Meta:
        model = Dispense
        fields = (
            "id",
            "prescription",
            "prescription_number",
            "employee_name",
            "pharmacist",
            "pharmacist_name",
            "dispense_number",
            "status",
            "dispensed_at",
            "notes",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at", "prescription_number", "pharmacist_name")

    def validate(self, attrs):
        prescription = attrs.get("prescription", getattr(self.instance, "prescription", None))
        new_status = attrs.get("status", getattr(self.instance, "status", None))

        if self.instance is None:
            if prescription.status != PrescriptionStatus.APPROVED:
                raise serializers.ValidationError(
                    {"prescription": "يمكن صرف الوصفات المعتمدة فقط."}
                )
            if prescription.dispenses.exclude(status=DispenseStatus.CANCELLED).exists():
                raise serializers.ValidationError(
                    {"prescription": "هذه الوصفة لديها بالفعل سجل صرف نشط."}
                )

        if self.instance and "status" in attrs:
            current_status = self.instance.status
            if new_status != current_status and new_status not in DISPENSE_ALLOWED_TRANSITIONS[current_status]:
                raise serializers.ValidationError(
                    {"status": f"لا يمكن تغيير حالة الصرف من {current_status} إلى {new_status}."}
                )
        return attrs

    @extend_schema_field(str)
    def get_employee_name(self, obj):
        return obj.prescription.employee.user.get_full_name() or obj.prescription.employee.user.username


class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for user notifications."""

    user_username = serializers.CharField(source="user.username", read_only=True)

    class Meta:
        model = Notification
        fields = (
            "id",
            "user",
            "user_username",
            "notification_type",
            "title",
            "message",
            "related_entity_type",
            "related_entity_id",
            "is_read",
            "read_at",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at", "user_username")

    def update(self, instance, validated_data):
        is_read = validated_data.get("is_read")
        if is_read is True and instance.read_at is None:
            validated_data["read_at"] = timezone.now()
        if is_read is False:
            validated_data["read_at"] = None
        return super().update(instance, validated_data)


class AuditLogSerializer(serializers.ModelSerializer):
    """Serializer for audit log entries."""

    actor_username = serializers.CharField(source="actor.username", read_only=True)

    class Meta:
        model = AuditLog
        fields = (
            "id",
            "actor",
            "actor_username",
            "action",
            "target_model",
            "target_id",
            "details",
            "created_at",
        )
        read_only_fields = ("id", "created_at", "actor_username")


# Backward-compatible aliases while the project migrates from patient naming.
PatientCreateUserSerializer = EmployeeCreateUserSerializer
PatientSerializer = EmployeeSerializer
