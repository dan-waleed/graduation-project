from .models import AuditLog, Notification, NotificationType, SystemSettings


def create_audit_log(*, actor, action, target_model="", target_id="", details=""):
    """Persist an audit log entry for sensitive API actions."""

    AuditLog.objects.create(
        actor=actor if getattr(actor, "is_authenticated", False) else None,
        action=action,
        target_model=target_model,
        target_id=str(target_id) if target_id else "",
        details=details,
    )


def create_notification(
    *,
    user,
    notification_type,
    title,
    message,
    related_entity_type="",
    related_entity_id="",
):
    """Create a user notification if a target user exists."""

    if not SystemSettings.get_solo().notifications_enabled:
        return
    if user is None:
        return
    Notification.objects.create(
        user=user,
        notification_type=notification_type,
        title=title,
        message=message,
        related_entity_type=related_entity_type,
        related_entity_id=str(related_entity_id) if related_entity_id else "",
    )


def notify_prescription_created(prescription):
    create_notification(
        user=prescription.employee.user,
        notification_type=NotificationType.PRESCRIPTION_CREATED,
        title="New medical order created",
        message=f"Medical order {prescription.prescription_number} is now available.",
        related_entity_type="Prescription",
        related_entity_id=prescription.id,
    )


def notify_insurance_updated(insurance_request):
    employee_user = insurance_request.prescription.employee.user
    doctor_user = insurance_request.prescription.doctor.user
    message = (
        f"Insurance request {insurance_request.request_number} "
        f"was updated to {insurance_request.status}."
    )
    create_notification(
        user=employee_user,
        notification_type=NotificationType.INSURANCE_UPDATED,
        title="Insurance request updated",
        message=message,
        related_entity_type="InsuranceRequest",
        related_entity_id=insurance_request.id,
    )
    if doctor_user != employee_user:
        create_notification(
            user=doctor_user,
            notification_type=NotificationType.INSURANCE_UPDATED,
            title="Insurance request updated",
            message=message,
            related_entity_type="InsuranceRequest",
            related_entity_id=insurance_request.id,
        )


def notify_dispense_updated(dispense):
    create_notification(
        user=dispense.prescription.employee.user,
        notification_type=NotificationType.DISPENSE_UPDATED,
        title="Medical order updated",
        message=(
            f"Dispense record {dispense.dispense_number} "
            f"was updated to {dispense.status}."
        ),
        related_entity_type="Dispense",
        related_entity_id=dispense.id,
    )
