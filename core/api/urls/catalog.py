from rest_framework.routers import DefaultRouter

from core.api.views.catalog import MedicalServiceViewSet, MedicationViewSet

router = DefaultRouter()
router.register("medical-services", MedicalServiceViewSet, basename="medical-service")
router.register("medications", MedicationViewSet, basename="medication")

urlpatterns = router.urls

