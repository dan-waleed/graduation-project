from rest_framework.routers import DefaultRouter

from core.api.views.users import DependentViewSet, DoctorViewSet, EmployeeViewSet, InsuranceOfficerViewSet, UserViewSet

router = DefaultRouter()
router.register("users", UserViewSet, basename="user")
router.register("employees", EmployeeViewSet, basename="employee")
router.register("patients", EmployeeViewSet, basename="patient-legacy")
router.register("doctors", DoctorViewSet, basename="doctor")
router.register("insurance-officers", InsuranceOfficerViewSet, basename="insurance-officer")
router.register("dependents", DependentViewSet, basename="dependent")

urlpatterns = router.urls

