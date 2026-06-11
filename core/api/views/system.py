from django.utils import timezone
from rest_framework.generics import GenericAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.response import Response

from core.models import AuditLog, Notification, SystemSettings, UserRole
from core.services import is_admin_user
from core.api.serializers import AuditLogSerializer, NotificationSerializer, SystemSettingsSerializer
from core.utils import create_audit_log

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
        self.log_action(
            "Notification marked as read",
            notification,
            details=f"notification_id={notification.pk}",
        )
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


class SystemSettingsView(GenericAPIView):
    serializer_class = SystemSettingsSerializer
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        if not is_admin_user(request.user):
            self.permission_denied(request, message="ليس لديك صلاحية للوصول إلى إعدادات النظام.")
        return Response(self.get_serializer(SystemSettings.get_solo()).data)

    def patch(self, request, *args, **kwargs):
        if not is_admin_user(request.user):
            self.permission_denied(request, message="ليس لديك صلاحية لتعديل إعدادات النظام.")
        settings = SystemSettings.get_solo()
        before_state = SystemSettingsSerializer(settings).data
        serializer = self.get_serializer(settings, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        after_state = serializer.data
        changed_fields = [
            key for key, before_value in before_state.items() if before_value != after_state.get(key)
        ]
        create_audit_log(
            actor=request.user,
            action="System settings updated",
            target_model="SystemSettings",
            target_id=settings.pk,
            details=", ".join(changed_fields) if changed_fields else "no field changes detected",
        )
        return Response(serializer.data)
