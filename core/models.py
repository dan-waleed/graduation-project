from django.contrib.auth.models import AbstractUser
from django.db import models


class TimeStampedModel(models.Model):
    """Abstract base model that tracks creation and modification times."""

    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created at")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Updated at")

    class Meta:
        abstract = True


class UserRole(models.TextChoices):
    ADMIN = "Admin", "Admin"
    DOCTOR = "Doctor", "Doctor"
    EMPLOYEE = "Employee", "Employee"
    PHARMACIST = "Pharmacist", "Pharmacist"
    LABORATORY = "Laboratory", "Laboratory"
    IMAGING_CENTER = "ImagingCenter", "Medical Imaging Center"
    MEDICAL_CENTER = "MedicalCenter", "Medical Center"
    INSURANCE_OFFICER = "InsuranceOfficer", "Insurance Officer"


SUPPORTED_USER_ROLES = (
    UserRole.ADMIN,
    UserRole.DOCTOR,
    UserRole.EMPLOYEE,
    UserRole.PHARMACIST,
    UserRole.INSURANCE_OFFICER,
)

ASSIGNABLE_USER_ROLES = (
    UserRole.DOCTOR,
    UserRole.EMPLOYEE,
    UserRole.PHARMACIST,
    UserRole.INSURANCE_OFFICER,
)

LEGACY_PROVIDER_ROLES = (
    UserRole.LABORATORY,
    UserRole.IMAGING_CENTER,
    UserRole.MEDICAL_CENTER,
)


class PrescriptionStatus(models.TextChoices):
    DRAFT = "Draft", "Draft"
    SENT = "Sent", "Sent"
    PENDING_EMPLOYEE_SELECTION = "PendingEmployeeSelection", "Pending Employee Selection"
    PENDING_INSURANCE_APPROVAL = "PendingInsuranceApproval", "Pending Insurance Approval"
    APPROVED = "Approved", "Approved"
    REJECTED = "Rejected", "Rejected"
    DISPENSED = "Dispensed", "Dispensed"
    PERFORMED = "Performed", "Performed"
    CANCELLED = "Cancelled", "Cancelled"
    EXPIRED = "Expired", "Expired"


class ProviderType(models.TextChoices):
    DOCTOR = "Doctor", "Doctor"
    PHARMACY = "Pharmacy", "Pharmacy"
    LABORATORY = "Lab", "Laboratory"
    IMAGING_CENTER = "ImagingCenter", "Medical Imaging Center"
    MEDICAL_CENTER = "MedicalCenter", "Medical Center"


class ContractStatus(models.TextChoices):
    ACTIVE = "active", "Active"
    INACTIVE = "inactive", "Inactive"


class ServiceType(models.TextChoices):
    MEDICATION = "Medication", "Medication"
    LAB_TEST = "LabTest", "Lab Test"
    IMAGING = "Imaging", "Imaging"
    PROCEDURE = "Procedure", "Procedure"
    CONSULTATION = "Consultation", "Consultation"


class InsuranceRequestStatus(models.TextChoices):
    PENDING = "Pending", "Pending"
    APPROVED = "Approved", "Approved"
    REJECTED = "Rejected", "Rejected"
    NEEDS_UPDATE = "NeedsUpdate", "Needs Update"


class DispenseStatus(models.TextChoices):
    COMPLETED = "Completed", "Completed"
    PARTIAL = "Partial", "Partial"
    CANCELLED = "Cancelled", "Cancelled"


class NotificationType(models.TextChoices):
    PRESCRIPTION_CREATED = "PrescriptionCreated", "Prescription Created"
    INSURANCE_UPDATED = "InsuranceUpdated", "Insurance Updated"
    DISPENSE_UPDATED = "DispenseUpdated", "Dispense Updated"
    SYSTEM_ALERT = "SystemAlert", "System Alert"


class User(AbstractUser, TimeStampedModel):
    """Custom authentication model used across the HealthBridge platform."""

    email = models.EmailField(unique=True, verbose_name="Email address")
    role = models.CharField(
        max_length=32,
        choices=UserRole.choices,
        verbose_name="Role",
    )
    phone_number = models.CharField(max_length=20, blank=True, verbose_name="Phone number")

    class Meta:
        verbose_name = "User"
        verbose_name_plural = "Users"
        ordering = ["username"]

    def __str__(self) -> str:
        return f"{self.get_full_name() or self.username} ({self.role})"


class Employee(TimeStampedModel):
    """Represents an insured university employee profile connected to a user account."""

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="employee_profile",
        verbose_name="User",
    )
    national_id = models.CharField(max_length=32, blank=True, verbose_name="National ID")
    university_id = models.CharField(max_length=50, blank=True, verbose_name="University ID")
    insurance_number = models.CharField(max_length=50, blank=True, verbose_name="Insurance number")
    medical_record_number = models.CharField(max_length=50, unique=True, verbose_name="Medical record number")
    date_of_birth = models.DateField(null=True, blank=True, verbose_name="Date of birth")
    gender = models.CharField(max_length=20, blank=True, verbose_name="Gender")
    address = models.TextField(blank=True, verbose_name="Address")
    insurance_provider = models.CharField(max_length=255, blank=True, verbose_name="Insurance provider")

    class Meta:
        verbose_name = "University employee"
        verbose_name_plural = "University employees"
        ordering = ["medical_record_number"]

    def __str__(self) -> str:
        return f"Employee {self.medical_record_number}"

    @property
    def dependents(self):
        return self.beneficiaries

    @property
    def prescriptions(self):
        return self.medical_orders


class Doctor(TimeStampedModel):
    """Represents a doctor authorized to create prescriptions."""

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="doctor_profile",
        verbose_name="User",
    )
    provider = models.OneToOneField(
        "Provider",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="doctor_profile",
        verbose_name="Provider",
    )
    license_number = models.CharField(max_length=50, unique=True, verbose_name="License number")
    specialization = models.CharField(max_length=255, blank=True, verbose_name="Specialization")
    clinic_name = models.CharField(max_length=255, blank=True, verbose_name="Clinic name")
    clinic_address = models.TextField(blank=True, verbose_name="Clinic address")
    consultation_price = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Consultation price")
    contract_status = models.CharField(
        max_length=10,
        choices=ContractStatus.choices,
        default=ContractStatus.ACTIVE,
        verbose_name="Contract status",
    )

    class Meta:
        verbose_name = "Doctor"
        verbose_name_plural = "Doctors"
        ordering = ["license_number"]

    def __str__(self) -> str:
        return f"Dr. {self.user.get_full_name() or self.user.username}"


class Pharmacy(TimeStampedModel):
    """Represents a pharmacy where prescriptions can be dispensed."""

    name = models.CharField(max_length=255, verbose_name="Name")
    provider = models.OneToOneField(
        "Provider",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="pharmacy_profile",
        verbose_name="Provider",
    )
    license_number = models.CharField(max_length=50, unique=True, verbose_name="License number")
    address = models.TextField(blank=True, verbose_name="Address")
    phone_number = models.CharField(max_length=20, blank=True, verbose_name="Phone number")
    is_active = models.BooleanField(default=True, verbose_name="Is active")

    class Meta:
        verbose_name = "Pharmacy"
        verbose_name_plural = "Pharmacies"
        ordering = ["name"]

    def __str__(self) -> str:
        return self.name


class Provider(TimeStampedModel):
    """Represents a contracted healthcare provider with location and pricing context."""

    provider_name = models.CharField(max_length=255, verbose_name="Provider name")
    provider_type = models.CharField(max_length=30, choices=ProviderType.choices, verbose_name="Provider type")
    city = models.CharField(max_length=100, blank=True, verbose_name="City")
    address = models.TextField(blank=True, verbose_name="Address")
    phone = models.CharField(max_length=20, blank=True, verbose_name="Phone")
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True, verbose_name="Latitude")
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True, verbose_name="Longitude")
    google_maps_url = models.URLField(blank=True, verbose_name="Google maps URL")
    working_hours = models.CharField(max_length=255, blank=True, verbose_name="Working hours")
    contract_status = models.CharField(
        max_length=10,
        choices=ContractStatus.choices,
        default=ContractStatus.ACTIVE,
        verbose_name="Contract status",
    )

    class Meta:
        verbose_name = "Provider"
        verbose_name_plural = "Providers"
        ordering = ["provider_type", "provider_name"]

    def __str__(self) -> str:
        return self.provider_name


class MedicalService(TimeStampedModel):
    """Represents a medical service that can be ordered electronically."""

    service_name = models.CharField(max_length=255, verbose_name="Service name")
    service_type = models.CharField(max_length=20, choices=ServiceType.choices, verbose_name="Service type")
    default_price = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Default price")
    requires_insurance_approval = models.BooleanField(default=False, verbose_name="Requires insurance approval")
    coverage_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0, verbose_name="Coverage percentage")
    employee_share = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Employee share")
    description = models.TextField(blank=True, verbose_name="Description")

    class Meta:
        verbose_name = "Medical service"
        verbose_name_plural = "Medical services"
        ordering = ["service_type", "service_name"]

    def __str__(self) -> str:
        return self.service_name


class ProviderServicePrice(TimeStampedModel):
    """Overrides service prices and coverage rules per provider."""

    provider = models.ForeignKey(
        Provider,
        on_delete=models.CASCADE,
        related_name="service_prices",
        verbose_name="Provider",
    )
    service = models.ForeignKey(
        MedicalService,
        on_delete=models.CASCADE,
        related_name="provider_prices",
        verbose_name="Medical service",
    )
    price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Price")
    coverage_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0, verbose_name="Coverage percentage")
    covered_amount_limit = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Covered amount limit")
    employee_share = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Employee share")
    is_available = models.BooleanField(default=True, verbose_name="Is available")
    requires_pre_approval = models.BooleanField(default=False, verbose_name="Requires pre approval")

    class Meta:
        verbose_name = "Provider service price"
        verbose_name_plural = "Provider service prices"
        ordering = ["provider", "service"]
        unique_together = ("provider", "service")

    def __str__(self) -> str:
        return f"{self.provider} - {self.service}"


class Pharmacist(TimeStampedModel):
    """Represents a pharmacist profile associated with a pharmacy."""

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="pharmacist_profile",
        verbose_name="User",
    )
    pharmacy = models.ForeignKey(
        Pharmacy,
        on_delete=models.CASCADE,
        related_name="pharmacists",
        verbose_name="Pharmacy",
    )
    license_number = models.CharField(max_length=50, unique=True, verbose_name="License number")

    class Meta:
        verbose_name = "Pharmacist"
        verbose_name_plural = "Pharmacists"
        ordering = ["license_number"]

    def __str__(self) -> str:
        return self.user.get_full_name() or self.user.username


class Laboratory(TimeStampedModel):
    """Represents a laboratory user profile tied to a provider."""

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="laboratory_profile",
        verbose_name="User",
    )
    provider = models.OneToOneField(
        Provider,
        on_delete=models.CASCADE,
        related_name="laboratory_profile",
        verbose_name="Provider",
    )
    license_number = models.CharField(max_length=50, unique=True, verbose_name="License number")

    class Meta:
        verbose_name = "Laboratory"
        verbose_name_plural = "Laboratories"
        ordering = ["license_number"]

    def __str__(self) -> str:
        return self.provider.provider_name


class MedicalImagingCenter(TimeStampedModel):
    """Represents an imaging center user profile tied to a provider."""

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="imaging_center_profile",
        verbose_name="User",
    )
    provider = models.OneToOneField(
        Provider,
        on_delete=models.CASCADE,
        related_name="imaging_center_profile",
        verbose_name="Provider",
    )
    license_number = models.CharField(max_length=50, unique=True, verbose_name="License number")

    class Meta:
        verbose_name = "Medical imaging center"
        verbose_name_plural = "Medical imaging centers"
        ordering = ["license_number"]

    def __str__(self) -> str:
        return self.provider.provider_name


class MedicalCenter(TimeStampedModel):
    """Represents a medical center user profile tied to a provider."""

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="medical_center_profile",
        verbose_name="User",
    )
    provider = models.OneToOneField(
        Provider,
        on_delete=models.CASCADE,
        related_name="medical_center_profile",
        verbose_name="Provider",
    )
    license_number = models.CharField(max_length=50, unique=True, verbose_name="License number")

    class Meta:
        verbose_name = "Medical center"
        verbose_name_plural = "Medical centers"
        ordering = ["license_number"]

    def __str__(self) -> str:
        return self.provider.provider_name


class InsuranceOfficer(TimeStampedModel):
    """Represents an insurance organization employee reviewing requests."""

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="insurance_officer_profile",
        verbose_name="User",
    )
    organization_name = models.CharField(max_length=255, verbose_name="Organization name")
    employee_id = models.CharField(max_length=50, unique=True, verbose_name="Employee ID")

    class Meta:
        verbose_name = "Insurance officer"
        verbose_name_plural = "Insurance officers"
        ordering = ["organization_name", "employee_id"]

    def __str__(self) -> str:
        return f"{self.organization_name} - {self.user.get_full_name() or self.user.username}"


class DependentRelation(models.TextChoices):
    SON = "son", "ابن"
    DAUGHTER = "daughter", "ابنة"
    WIFE = "wife", "زوجة"
    HUSBAND = "husband", "زوج"


class Dependent(TimeStampedModel):
    """Represents a beneficiary covered under an employee insurance account."""

    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name="beneficiaries",
        verbose_name="Employee",
    )
    full_name = models.CharField(max_length=255, verbose_name="Full name")
    national_id = models.CharField(max_length=32, blank=True, verbose_name="National ID")
    relation = models.CharField(
        max_length=20,
        choices=DependentRelation.choices,
        verbose_name="Relation",
    )
    date_of_birth = models.DateField(null=True, blank=True, verbose_name="Date of birth")
    is_active = models.BooleanField(default=True, verbose_name="Is active")
    notes = models.TextField(blank=True, verbose_name="Notes")

    class Meta:
        verbose_name = "Beneficiary"
        verbose_name_plural = "Beneficiaries"
        ordering = ["full_name"]

    def __str__(self) -> str:
        return f"{self.full_name} ({self.relation})"

    @property
    def patient(self):
        return self.employee


class Medication(TimeStampedModel):
    """Represents a medication that can be prescribed and dispensed."""

    name = models.CharField(max_length=255, verbose_name="Name")
    generic_name = models.CharField(max_length=255, blank=True, verbose_name="Generic name")
    strength = models.CharField(max_length=100, blank=True, verbose_name="Strength")
    dosage_form = models.CharField(max_length=100, blank=True, verbose_name="Dosage form")
    manufacturer = models.CharField(max_length=255, blank=True, verbose_name="Manufacturer")
    description = models.TextField(blank=True, verbose_name="Description")
    is_active = models.BooleanField(default=True, verbose_name="Is active")

    class Meta:
        verbose_name = "Medication"
        verbose_name_plural = "Medications"
        ordering = ["name", "strength"]

    def __str__(self) -> str:
        strength = f" {self.strength}" if self.strength else ""
        return f"{self.name}{strength}"


class Prescription(TimeStampedModel):
    """Represents an electronic medical order for an employee or beneficiary."""

    prescription_number = models.CharField(max_length=50, unique=True, verbose_name="Prescription number")
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name="medical_orders",
        verbose_name="Employee",
    )
    doctor = models.ForeignKey(
        Doctor,
        on_delete=models.CASCADE,
        related_name="prescriptions",
        verbose_name="Doctor",
    )
    beneficiary = models.ForeignKey(
        Dependent,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="medical_orders",
        verbose_name="Beneficiary",
    )
    provider = models.ForeignKey(
        Provider,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="medical_orders",
        verbose_name="Provider",
    )
    service = models.ForeignKey(
        MedicalService,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="medical_orders",
        verbose_name="Medical service",
    )
    service_type = models.CharField(
        max_length=20,
        choices=ServiceType.choices,
        default=ServiceType.MEDICATION,
        verbose_name="Service type",
    )
    status = models.CharField(
        max_length=32,
        choices=PrescriptionStatus.choices,
        default=PrescriptionStatus.DRAFT,
        verbose_name="Status",
    )
    requires_insurance_approval = models.BooleanField(default=False, verbose_name="Requires insurance approval")
    coverage_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0, verbose_name="Coverage percentage")
    covered_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Covered amount")
    employee_share = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Employee share")
    final_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True, verbose_name="Final price")
    diagnosis = models.TextField(blank=True, verbose_name="Diagnosis")
    notes = models.TextField(blank=True, verbose_name="Notes")
    provider_notes = models.TextField(blank=True, verbose_name="Provider notes")
    report_attachment_url = models.URLField(blank=True, verbose_name="Report attachment URL")
    issued_at = models.DateTimeField(verbose_name="Issued at")
    performed_at = models.DateTimeField(null=True, blank=True, verbose_name="Performed at")
    valid_until = models.DateTimeField(null=True, blank=True, verbose_name="Valid until")

    class Meta:
        verbose_name = "Prescription"
        verbose_name_plural = "Prescriptions"
        ordering = ["-issued_at", "-created_at"]

    def __str__(self) -> str:
        return self.prescription_number

    @property
    def patient(self):
        return self.employee

    @property
    def dependent(self):
        return self.beneficiary


class PrescriptionItem(TimeStampedModel):
    """Represents an individual medication entry inside a prescription."""

    prescription = models.ForeignKey(
        Prescription,
        on_delete=models.CASCADE,
        related_name="items",
        verbose_name="Prescription",
    )
    medication = models.ForeignKey(
        Medication,
        on_delete=models.PROTECT,
        related_name="prescription_items",
        verbose_name="Medication",
    )
    dosage_instructions = models.TextField(verbose_name="Dosage instructions")
    quantity = models.CharField(max_length=100, verbose_name="Quantity")
    duration = models.CharField(max_length=100, blank=True, verbose_name="Duration")
    substitution_allowed = models.BooleanField(default=False, verbose_name="Substitution allowed")

    class Meta:
        verbose_name = "Prescription item"
        verbose_name_plural = "Prescription items"
        ordering = ["prescription", "id"]

    def __str__(self) -> str:
        return f"{self.prescription} - {self.medication}"


class InsuranceRequest(TimeStampedModel):
    """Represents an insurance approval workflow for a prescription."""

    prescription = models.OneToOneField(
        Prescription,
        on_delete=models.CASCADE,
        related_name="insurance_request",
        verbose_name="Prescription",
    )
    reviewed_by = models.ForeignKey(
        InsuranceOfficer,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="insurance_requests",
        verbose_name="Reviewed by",
    )
    request_number = models.CharField(max_length=50, unique=True, verbose_name="Request number")
    status = models.CharField(
        max_length=20,
        choices=InsuranceRequestStatus.choices,
        default=InsuranceRequestStatus.PENDING,
        verbose_name="Status",
    )
    submitted_at = models.DateTimeField(verbose_name="Submitted at")
    reviewed_at = models.DateTimeField(null=True, blank=True, verbose_name="Reviewed at")
    response_notes = models.TextField(blank=True, verbose_name="Response notes")

    class Meta:
        verbose_name = "Insurance request"
        verbose_name_plural = "Insurance requests"
        ordering = ["-submitted_at", "-created_at"]

    def __str__(self) -> str:
        return self.request_number


class Dispense(TimeStampedModel):
    """Represents the fulfillment of a prescription by a pharmacist."""

    prescription = models.ForeignKey(
        Prescription,
        on_delete=models.CASCADE,
        related_name="dispenses",
        verbose_name="Prescription",
    )
    pharmacist = models.ForeignKey(
        Pharmacist,
        on_delete=models.CASCADE,
        related_name="dispenses",
        verbose_name="Pharmacist",
    )
    dispense_number = models.CharField(max_length=50, unique=True, verbose_name="Dispense number")
    status = models.CharField(
        max_length=20,
        choices=DispenseStatus.choices,
        default=DispenseStatus.COMPLETED,
        verbose_name="Status",
    )
    dispensed_at = models.DateTimeField(verbose_name="Dispensed at")
    notes = models.TextField(blank=True, verbose_name="Notes")

    class Meta:
        verbose_name = "Dispense"
        verbose_name_plural = "Dispenses"
        ordering = ["-dispensed_at", "-created_at"]

    def __str__(self) -> str:
        return self.dispense_number


class Notification(TimeStampedModel):
    """Represents a user-facing notification inside the platform."""

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="notifications",
        verbose_name="User",
    )
    notification_type = models.CharField(
        max_length=30,
        choices=NotificationType.choices,
        verbose_name="Notification type",
    )
    title = models.CharField(max_length=255, verbose_name="Title")
    message = models.TextField(verbose_name="Message")
    related_entity_type = models.CharField(max_length=100, blank=True, verbose_name="Related entity type")
    related_entity_id = models.CharField(max_length=100, blank=True, verbose_name="Related entity ID")
    is_read = models.BooleanField(default=False, verbose_name="Is read")
    read_at = models.DateTimeField(null=True, blank=True, verbose_name="Read at")

    class Meta:
        verbose_name = "Notification"
        verbose_name_plural = "Notifications"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.user.username} - {self.title}"


class AuditLog(models.Model):
    """Stores a lightweight audit trail for sensitive system actions."""

    actor = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="audit_logs",
        verbose_name="Actor",
    )
    action = models.CharField(max_length=255, verbose_name="Action")
    target_model = models.CharField(max_length=100, blank=True, verbose_name="Target model")
    target_id = models.CharField(max_length=100, blank=True, verbose_name="Target ID")
    details = models.TextField(blank=True, verbose_name="Details")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created at")

    class Meta:
        verbose_name = "Audit log"
        verbose_name_plural = "Audit logs"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.action} ({self.created_at:%Y-%m-%d %H:%M})"


# Backward-compatible aliases during the employee refactor.
Patient = Employee
