from rest_framework.routers import DefaultRouter

from core.api.views.workflow import DispenseViewSet, InsuranceRequestViewSet, PrescriptionViewSet

router = DefaultRouter()
router.register("prescriptions", PrescriptionViewSet, basename="prescription")
router.register("insurance", InsuranceRequestViewSet, basename="insurance")
router.register("dispenses", DispenseViewSet, basename="dispense")

urlpatterns = router.urls

