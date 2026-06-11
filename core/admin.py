from django.contrib import admin
from rest_framework.authtoken.admin import TokenAdmin
from rest_framework.authtoken.models import Token, TokenProxy

from .models import (
    AuditLog,
    Dependent,
    Dispense,
    Doctor,
    Employee,
    InsuranceOfficer,
    InsuranceRequest,
    Medication,
    MedicalService,
    Notification,
    Pharmacist,
    Pharmacy,
    Prescription,
    PrescriptionItem,
    Provider,
    ProviderServicePrice,
    User,
)


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ("username", "email", "role", "is_active", "is_staff", "created_at")
    list_filter = ("role", "is_active", "is_staff", "is_superuser")
    search_fields = ("username", "email", "first_name", "last_name")


@admin.register(Employee)
class EmployeeAdmin(admin.ModelAdmin):
    list_display = ("medical_record_number", "user", "insurance_provider", "created_at")
    search_fields = ("medical_record_number", "user__username", "user__email")


@admin.register(Provider)
class ProviderAdmin(admin.ModelAdmin):
    list_display = ("provider_name", "provider_type", "city", "contract_status", "created_at")
    search_fields = ("provider_name", "provider_type", "city", "phone")
    list_filter = ("provider_type", "contract_status")


@admin.register(Doctor)
class DoctorAdmin(admin.ModelAdmin):
    list_display = ("license_number", "user", "specialization", "created_at")
    search_fields = ("license_number", "user__username", "user__email", "specialization")


@admin.register(Pharmacy)
class PharmacyAdmin(admin.ModelAdmin):
    list_display = ("name", "license_number", "phone_number", "is_active", "created_at")
    search_fields = ("name", "license_number", "phone_number")
    list_filter = ("is_active",)


@admin.register(Pharmacist)
class PharmacistAdmin(admin.ModelAdmin):
    list_display = ("license_number", "user", "pharmacy", "created_at")
    search_fields = ("license_number", "user__username", "pharmacy__name")


@admin.register(InsuranceOfficer)
class InsuranceOfficerAdmin(admin.ModelAdmin):
    list_display = ("employee_id", "user", "organization_name", "created_at")
    search_fields = ("employee_id", "user__username", "organization_name")


@admin.register(Dependent)
class DependentAdmin(admin.ModelAdmin):
    list_display = ("full_name", "employee", "relation", "date_of_birth", "is_active", "created_at")
    search_fields = ("full_name", "relation", "employee__user__username")


@admin.register(Medication)
class MedicationAdmin(admin.ModelAdmin):
    list_display = ("name", "strength", "is_active", "created_at")
    search_fields = ("name", "strength", "manufacturer")
    list_filter = ("is_active",)


@admin.register(MedicalService)
class MedicalServiceAdmin(admin.ModelAdmin):
    list_display = ("service_name", "service_type", "default_price", "requires_insurance_approval", "created_at")
    search_fields = ("service_name", "service_type")
    list_filter = ("service_type", "requires_insurance_approval")


@admin.register(ProviderServicePrice)
class ProviderServicePriceAdmin(admin.ModelAdmin):
    list_display = ("provider", "service", "price", "coverage_percentage", "is_available", "created_at")
    search_fields = ("provider__provider_name", "service__service_name")
    list_filter = ("is_available", "requires_pre_approval")


class PrescriptionItemInline(admin.TabularInline):
    model = PrescriptionItem
    extra = 0


@admin.register(Prescription)
class PrescriptionAdmin(admin.ModelAdmin):
    list_display = ("prescription_number", "employee", "doctor", "service_type", "status", "issued_at", "created_at")
    list_filter = ("status",)
    search_fields = ("prescription_number", "employee__user__username", "doctor__user__username")
    inlines = [PrescriptionItemInline]


@admin.register(InsuranceRequest)
class InsuranceRequestAdmin(admin.ModelAdmin):
    list_display = ("request_number", "prescription", "status", "submitted_at", "reviewed_at")
    list_filter = ("status",)
    search_fields = ("request_number", "prescription__prescription_number")


@admin.register(Dispense)
class DispenseAdmin(admin.ModelAdmin):
    list_display = ("dispense_number", "prescription", "pharmacist", "status", "dispensed_at")
    list_filter = ("status",)
    search_fields = ("dispense_number", "prescription__prescription_number", "pharmacist__user__username")


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ("user", "notification_type", "is_read", "created_at")
    list_filter = ("notification_type", "is_read")
    search_fields = ("user__username", "title", "message")


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ("action", "actor", "target_model", "target_id", "created_at")
    search_fields = ("action", "target_model", "target_id", "actor__username")


admin.site.unregister(TokenProxy)
admin.site.register(Token, TokenAdmin)
