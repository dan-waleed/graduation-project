from django.urls import path
from rest_framework.routers import DefaultRouter

from .auth_views import DashboardSummaryView, LoginView, LogoutView, MeView
from .views import (
    AuditLogViewSet,
    DependentViewSet,
    DispenseViewSet,
    DoctorViewSet,
    EmployeeViewSet,
    InsuranceOfficerViewSet,
    InsuranceRequestViewSet,
    MedicationViewSet,
    MedicalServiceViewSet,
    NotificationViewSet,
    PharmacistViewSet,
    PharmacyViewSet,
    PrescriptionViewSet,
    ProviderServicePriceViewSet,
    ProviderViewSet,
    UserViewSet,
)

router = DefaultRouter()
router.register("users", UserViewSet, basename="user")
router.register("employees", EmployeeViewSet, basename="employee")
router.register("patients", EmployeeViewSet, basename="patient-legacy")
router.register("doctors", DoctorViewSet, basename="doctor")
router.register("insurance-officers", InsuranceOfficerViewSet, basename="insurance-officer")
router.register("providers", ProviderViewSet, basename="provider")
router.register("pharmacies", PharmacyViewSet, basename="pharmacy")
router.register("pharmacists", PharmacistViewSet, basename="pharmacist")
router.register("medical-services", MedicalServiceViewSet, basename="medical-service")
router.register("provider-service-prices", ProviderServicePriceViewSet, basename="provider-service-price")
router.register("dependents", DependentViewSet, basename="dependent")
router.register("medications", MedicationViewSet, basename="medication")
router.register("prescriptions", PrescriptionViewSet, basename="prescription")
router.register("insurance", InsuranceRequestViewSet, basename="insurance")
router.register("dispenses", DispenseViewSet, basename="dispense")
router.register("notifications", NotificationViewSet, basename="notification")
router.register("audit-logs", AuditLogViewSet, basename="audit-log")

urlpatterns = [
    path("auth/login/", LoginView.as_view(), name="api-login"),
    path("auth/logout/", LogoutView.as_view(), name="api-logout"),
    path("auth/me/", MeView.as_view(), name="api-me"),
    path("dashboard/summary/", DashboardSummaryView.as_view(), name="api-dashboard-summary"),
]

urlpatterns += router.urls
