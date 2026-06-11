from django.contrib.auth import get_user_model
from django.db.models import Sum
from django.utils import timezone

from core.models import (
    Dependent,
    Dispense,
    Doctor,
    Employee,
    InsuranceRequest,
    InsuranceOfficer,
    Pharmacist,
    Notification,
    Pharmacy,
    Prescription,
    UserRole,
)

User = get_user_model()


def build_dashboard_summary(user):
    """Return a small role-aware dashboard payload for the mobile app."""

    role = user.role
    display_name = user.get_full_name() or user.username

    builders = {
        UserRole.DOCTOR: _doctor_summary,
        UserRole.EMPLOYEE: _employee_summary,
        UserRole.PHARMACIST: _pharmacist_summary,
        UserRole.INSURANCE_OFFICER: _insurance_summary,
    }

    builder = builders.get(role, _admin_summary)
    title, subtitle, metrics, recent_activity = builder(user, display_name)

    return {
        "role": role,
        "title": title,
        "subtitle": subtitle,
        "metrics": metrics,
        "recent_activity": recent_activity,
    }


def _doctor_summary(user, display_name):
    doctor = getattr(user, "doctor_profile", None)
    prescriptions = Prescription.objects.filter(doctor=doctor) if doctor else Prescription.objects.none()

    metrics = [
        _metric("employees", "المرضى", prescriptions.values("employee").distinct().count(), "people"),
        _metric("orders", "إجمالي الطلبات الطبية", prescriptions.count(), "prescriptions"),
        _metric("draft_orders", "المسودات", prescriptions.filter(status="Draft").count(), "today"),
        _metric("sent_orders", "الطلبات المرسلة", prescriptions.filter(status="Sent").count(), "prescriptions"),
        _metric("pending_approvals", "الموافقات المعلّقة", prescriptions.filter(status="PendingInsuranceApproval").count(), "pending"),
        _metric("approved_orders", "طلبات معتمدة", prescriptions.filter(status="Approved").count(), "approved"),
        _metric("dispensed_orders", "طلبات تم صرفها", prescriptions.filter(status="Dispensed").count(), "done"),
    ]
    activity = [
        _activity(
            title=f"طلب للموظف {item.employee.user.get_full_name() or item.employee.user.username}",
            subtitle=f"{item.prescription_number} • {item.diagnosis or 'بدون تشخيص مفصل'}",
            status=item.status,
            created_at=item.created_at,
        )
        for item in prescriptions.select_related("employee__user").order_by("-created_at")[:5]
    ]
    return (
        "",
        "",
        metrics,
        activity,
    )


def _employee_summary(user, display_name):
    employee = getattr(user, "employee_profile", None)
    prescriptions = Prescription.objects.filter(employee=employee) if employee else Prescription.objects.none()
    totals = prescriptions.aggregate(
        covered=Sum("covered_amount"),
        share=Sum("employee_share"),
    )

    metrics = [
        _metric("orders", "طلباتي الطبية", prescriptions.count(), "prescriptions"),
        _metric("pending", "طلبات قيد المراجعة", prescriptions.filter(status__in=["PendingEmployeeSelection", "PendingInsuranceApproval"]).count(), "pending"),
        _metric("approved", "طلبات معتمدة", prescriptions.filter(status="Approved").count(), "approved"),
        _metric("rejected", "طلبات مرفوضة", prescriptions.filter(status="Rejected").count(), "rejected"),
        _metric("beneficiaries", "عدد المستفيدين", employee.beneficiaries.count() if employee else 0, "family"),
        _metric("covered", "إجمالي المغطى", int(totals["covered"] or 0), "insurance"),
        _metric("share", "إجمالي حصة الموظف", int(totals["share"] or 0), "payments"),
        _metric("notifications", "إشعارات جديدة", Notification.objects.filter(user=user, is_read=False).count(), "notifications"),
    ]
    activity = [
        _activity(
            title=f"وصفة من {item.doctor.user.get_full_name() or item.doctor.user.username}",
            subtitle=f"{item.prescription_number} • {item.diagnosis or 'مراجعة طبية'}",
            status=item.status,
            created_at=item.created_at,
        )
        for item in prescriptions.select_related("doctor__user").order_by("-created_at")[:5]
    ]
    return (
        f"أهلاً بك، {display_name}",
        "آخر المستجدات المتعلقة بطلباتك الطبية",
        metrics,
        activity,
    )


def _pharmacist_summary(user, display_name):
    pharmacist = getattr(user, "pharmacist_profile", None)
    dispenses = Dispense.objects.filter(pharmacist=pharmacist) if pharmacist else Dispense.objects.none()

    metrics = [
        _metric("dispenses", "عمليات الصرف", dispenses.count(), "dispense"),
        _metric("completed", "صرف مكتمل", dispenses.filter(status="Completed").count(), "done"),
        _metric("partial", "صرف جزئي", dispenses.filter(status="Partial").count(), "partial"),
        _metric("approved_rx", "وصفات جاهزة للصرف", Prescription.objects.filter(status="Approved").count(), "approved"),
    ]
    activity = [
        _activity(
            title=f"صرف للموظف {item.prescription.employee.user.get_full_name() or item.prescription.employee.user.username}",
            subtitle=f"{item.dispense_number} • {item.notes or 'تم تحديث سجل الصرف'}",
            status=item.status,
            created_at=item.created_at,
        )
        for item in dispenses.select_related("prescription__employee__user").order_by("-created_at")[:5]
    ]
    return (
        f"أهلاً بك، {display_name}",
        "ملخص يومي لعمليات الصرف والتحقق",
        metrics,
        activity,
    )


def _insurance_summary(user, display_name):
    requests = InsuranceRequest.objects.all()
    related_orders = Prescription.objects.filter(insurance_request__isnull=False)
    totals = related_orders.aggregate(total=Sum("final_price"), covered=Sum("covered_amount"), share=Sum("employee_share"))

    metrics = [
        _metric("requests", "طلبات التغطية", requests.count(), "insurance"),
        _metric("pending", "المعلّقة", requests.filter(status="Pending").count(), "pending"),
        _metric("approved", "المقبولة", requests.filter(status="Approved").count(), "approved"),
        _metric("rejected", "المرفوضة", requests.filter(status="Rejected").count(), "rejected"),
        _metric("needs_update", "تحتاج تعديل", requests.filter(status="NeedsUpdate").count(), "update"),
        _metric("total_cost", "إجمالي السعر", int(totals["total"] or 0), "payments"),
        _metric("covered", "إجمالي المغطى", int(totals["covered"] or 0), "insurance"),
        _metric("share", "إجمالي حصة الموظف", int(totals["share"] or 0), "payments"),
    ]
    activity = [
        _activity(
            title=f"طلب تغطية {item.request_number}",
            subtitle=f"{item.prescription.prescription_number} • {item.response_notes or 'بانتظار المراجعة'}",
            status=item.status,
            created_at=item.created_at,
        )
        for item in requests.select_related("prescription").order_by("-created_at")[:5]
    ]
    return (
        f"أهلاً بك، {display_name}",
        "متابعة الطلبات التأمينية والقرارات الأخيرة",
        metrics,
        activity,
    )


def _admin_summary(user, display_name):
    totals = Prescription.objects.aggregate(total=Sum("final_price"), covered=Sum("covered_amount"), share=Sum("employee_share"))
    metrics = [
        _metric("users", "عدد المستخدمين", User.objects.count(), "users"),
        _metric("beneficiaries", "عدد المستفيدين", Dependent.objects.count(), "family"),
        _metric("doctors", "عدد الأطباء", Doctor.objects.count(), "doctor"),
        _metric("employees", "عدد الموظفين الجامعيين", Employee.objects.count(), "employee"),
        _metric("pharmacies", "عدد الصيدليات", Pharmacy.objects.count(), "pharmacy"),
        _metric("pharmacists", "عدد الصيادلة", Pharmacist.objects.count(), "pharmacy"),
        _metric("insurance_officers", "عدد موظفي التأمين", InsuranceOfficer.objects.count(), "insurance"),
        _metric("orders", "عدد الطلبات الطبية", Prescription.objects.count(), "prescriptions"),
        _metric("coverage_requests", "طلبات التغطية", InsuranceRequest.objects.count(), "insurance"),
        _metric("pending_requests", "الطلبات المعلقة", InsuranceRequest.objects.filter(status="Pending").count(), "pending"),
        _metric("approved_requests", "الطلبات المعتمدة", InsuranceRequest.objects.filter(status="Approved").count(), "approved"),
        _metric("rejected_requests", "الطلبات المرفوضة", InsuranceRequest.objects.filter(status="Rejected").count(), "rejected"),
        _metric("covered", "إجمالي المغطى", int(totals["covered"] or 0), "insurance"),
        _metric("share", "إجمالي حصة الموظف", int(totals["share"] or 0), "payments"),
    ]
    activity = [
        _activity(
            title=f"تنبيه: {item.title}",
            subtitle=item.message,
            status="SystemAlert",
            created_at=item.created_at,
        )
        for item in Notification.objects.order_by("-created_at")[:5]
    ]
    return (
        f"أهلاً بك، {display_name}",
        "نظرة عامة على بيانات النظام ونشاطه",
        metrics,
        activity,
    )


def _metric(key, label, value, icon):
    return {
        "key": key,
        "label": label,
        "value": value,
        "icon": icon,
    }


def _activity(title, subtitle, status, created_at):
    return {
        "title": title,
        "subtitle": subtitle,
        "status": status,
        "created_at": created_at,
    }
