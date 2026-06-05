from rest_framework.routers import DefaultRouter

from core.api.views.providers import (
    PharmacyViewSet,
    ProviderServicePriceViewSet,
    ProviderViewSet,
)

router = DefaultRouter()
router.register("providers", ProviderViewSet, basename="provider")
router.register("pharmacies", PharmacyViewSet, basename="pharmacy")
router.register("provider-service-prices", ProviderServicePriceViewSet, basename="provider-service-price")

urlpatterns = router.urls
