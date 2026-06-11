from django.urls import path
from rest_framework.routers import DefaultRouter

from core.api.views.system import AuditLogViewSet, NotificationViewSet, SystemSettingsView

router = DefaultRouter()
router.register("notifications", NotificationViewSet, basename="notification")
router.register("audit-logs", AuditLogViewSet, basename="audit-log")

urlpatterns = [
    *router.urls,
    path("system-settings/", SystemSettingsView.as_view(), name="system-settings"),
]
