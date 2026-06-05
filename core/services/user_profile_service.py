from __future__ import annotations

from django.contrib.auth import get_user_model
from django.utils.text import slugify

from core.models import (
    ContractStatus,
    Doctor,
    Employee,
    InsuranceOfficer,
    Pharmacist,
    Pharmacy,
    Provider,
    ProviderType,
    UserRole,
)

User = get_user_model()


def split_full_name(full_name: str) -> tuple[str, str]:
    normalized = " ".join((full_name or "").split()).strip()
    if not normalized:
        return "", ""
    parts = normalized.split(" ", 1)
    if len(parts) == 1:
        return parts[0], ""
    return parts[0], parts[1]


def build_unique_username(email: str = "", full_name: str = "", fallback_prefix: str = "employee") -> str:
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


def ensure_role_profile(user) -> None:
    if user.role == UserRole.ADMIN:
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

    if user.role == UserRole.DOCTOR:
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
                "provider": provider,
                "license_number": f"DOC-{user.id:04d}",
                "specialization": "عام",
                "clinic_name": "عيادة HealthBridge",
                "clinic_address": "",
                "consultation_price": 0,
                "contract_status": ContractStatus.ACTIVE,
            },
        )
        return

    if user.role == UserRole.PHARMACIST:
        provider, _ = Provider.objects.get_or_create(
            provider_name=f"Pharmacy {user.id:04d}",
            provider_type=ProviderType.PHARMACY,
            defaults={
                "city": "",
                "address": "",
                "phone": "",
                "google_maps_url": "",
                "working_hours": "",
                "contract_status": ContractStatus.ACTIVE,
            },
        )
        pharmacy, _ = Pharmacy.objects.get_or_create(
            license_number=f"PHA-{user.id:04d}",
            defaults={
                "name": f"صيدلية HealthBridge {user.id:04d}",
                "provider": provider,
                "address": "",
                "phone_number": user.phone_number or "",
                "is_active": True,
            },
        )
        if pharmacy.provider_id is None:
            pharmacy.provider = provider
            pharmacy.save(update_fields=["provider", "updated_at"])
        Pharmacist.objects.get_or_create(
            user=user,
            defaults={
                "pharmacy": pharmacy,
                "license_number": f"RPH-{user.id:04d}",
            },
        )
        return

    if user.role == UserRole.INSURANCE_OFFICER:
        InsuranceOfficer.objects.get_or_create(
            user=user,
            defaults={
                "organization_name": "قسم التأمين الصحي",
                "employee_id": f"INS-{user.id:04d}",
            },
        )
        return
