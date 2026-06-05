from __future__ import annotations

from decimal import Decimal

from django.utils import timezone

from core.models import (
    DispenseStatus,
    InsuranceRequestStatus,
    PrescriptionStatus,
    ProviderServicePrice,
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


def apply_coverage_calculations(payload):
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
    coverage_percentage = provider_price.coverage_percentage if provider_price is not None else service.coverage_percentage
    requires_approval = (
        provider_price.requires_pre_approval if provider_price is not None else service.requires_insurance_approval
    )
    covered_amount = (base_price * coverage_percentage) / Decimal("100")
    employee_share = base_price - covered_amount

    payload.setdefault("final_price", base_price)
    payload["coverage_percentage"] = coverage_percentage
    payload["covered_amount"] = covered_amount
    payload["employee_share"] = employee_share
    payload["requires_insurance_approval"] = requires_approval
    return payload


def sync_prescription_status_from_insurance(insurance_request) -> None:
    prescription = insurance_request.prescription
    status_map = {
        InsuranceRequestStatus.APPROVED: PrescriptionStatus.APPROVED,
        InsuranceRequestStatus.REJECTED: PrescriptionStatus.REJECTED,
        InsuranceRequestStatus.PENDING: PrescriptionStatus.PENDING_INSURANCE_APPROVAL,
        InsuranceRequestStatus.NEEDS_UPDATE: PrescriptionStatus.PENDING_INSURANCE_APPROVAL,
    }
    next_status = status_map.get(insurance_request.status)
    if next_status and prescription.status != next_status:
        prescription.status = next_status
        prescription.save(update_fields=["status", "updated_at"])


def mark_insurance_review(insurance_request, reviewer) -> None:
    if insurance_request.reviewed_by_id is None:
        insurance_request.reviewed_by = reviewer
        insurance_request.reviewed_at = insurance_request.reviewed_at or timezone.now()
        insurance_request.save(update_fields=["reviewed_by", "reviewed_at", "updated_at"])


def sync_prescription_status_from_dispense(dispense) -> None:
    if dispense.status == DispenseStatus.COMPLETED:
        next_status = PrescriptionStatus.DISPENSED
    elif dispense.status in {DispenseStatus.PARTIAL, DispenseStatus.CANCELLED}:
        next_status = PrescriptionStatus.APPROVED
    else:
        return

    if dispense.prescription.status != next_status:
        dispense.prescription.status = next_status
        dispense.prescription.save(update_fields=["status", "updated_at"])
