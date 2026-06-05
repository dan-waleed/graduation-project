from django.utils import timezone
from rest_framework.decorators import action
from rest_framework.response import Response

from core.models import AuditLog, Notification, UserRole
from core.services import is_admin_user
from core.api.serializers import AuditLogSerializer, NotificationSerializer

from .common import BaseOwnedModelViewSet


class NotificationViewSet(BaseOwnedModelViewSet):
    serializer_class = NotificationSerializer
    queryset = Notification.objects.select_related("user").all()
    search_fields = ("title", "message", "notification_type", "user__username")
    ordering = ("-created_at",)
    exact_filter_fields = {
        "user": "user_id",
        "notification_type": "notification_type",
        "is_read": "is_read",
    }
    role_permissions = {
        "create": [UserRole.ADMIN],
        "update": [
            UserRole.ADMIN,
            UserRole.DOCTOR,
            UserRole.EMPLOYEE,
            UserRole.PHARMACIST,
            UserRole.INSURANCE_OFFICER,
        ],
        "partial_update": [
            UserRole.ADMIN,
            UserRole.DOCTOR,
            UserRole.EMPLOYEE,
            UserRole.PHARMACIST,
            UserRole.INSURANCE_OFFICER,
        ],
        "destroy": [UserRole.ADMIN],
    }

    def get_queryset(self):
        if is_admin_user(self.request.user):
            return self.queryset
        return self.queryset.filter(user=self.request.user)

    @action(detail=True, methods=["patch", "post"], url_path="mark-read")
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        serializer = self.get_serializer(notification, data={"is_read": True}, partial=True)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return Response(serializer.data)

    @action(detail=True, methods=["patch", "post"], url_path="read")
    def read(self, request, pk=None):
        return self.mark_read(request, pk=pk)

    @action(detail=False, methods=["patch", "post"], url_path="mark-all-read")
    def mark_all_read(self, request):
        queryset = self.filter_queryset(self.get_queryset()).filter(is_read=False)
        updated_count = queryset.update(is_read=True, read_at=timezone.now())
        self.log_action("Notifications marked as read", details=f"count={updated_count}")
        return Response({"updated_count": updated_count})

    @action(detail=False, methods=["get"], url_path="unread-count")
    def unread_count(self, request):
        count = self.filter_queryset(self.get_queryset()).filter(is_read=False).count()
        return Response({"count": count})


class AuditLogViewSet(BaseOwnedModelViewSet):
    serializer_class = AuditLogSerializer
    queryset = AuditLog.objects.select_related("actor").all()
    search_fields = ("action", "target_model", "target_id", "actor__username")
    ordering = ("-created_at",)
    exact_filter_fields = {
        "actor": "actor_id",
        "target_model": "target_model",
        "target_id": "target_id",
    }
    http_method_names = ["get", "head", "options"]
    role_permissions = {
        "*": [UserRole.ADMIN],
    }

    def get_queryset(self):
        return self.queryset if is_admin_user(self.request.user) else self.queryset.none()
