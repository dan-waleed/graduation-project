from django.contrib.auth import get_user_model
from rest_framework.permissions import IsAuthenticated
from rest_framework.viewsets import ModelViewSet

from core.permissions import RoleAccessMixin
from core.utils import create_audit_log

User = get_user_model()


class BaseOwnedModelViewSet(RoleAccessMixin, ModelViewSet):
    """Base viewset that enforces authentication for all API endpoints."""

    permission_classes = [IsAuthenticated]
    search_fields = ()
    ordering_fields = "__all__"
    ordering = ("-id",)
    exact_filter_fields = {}

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        if not self.has_role_permission(request):
            self.permission_denied(request, message="ليس لديك صلاحية لتنفيذ هذا الإجراء.")

    def log_action(self, action, instance=None, details=""):
        create_audit_log(
            actor=self.request.user,
            action=action,
            target_model=instance.__class__.__name__ if instance is not None else "",
            target_id=getattr(instance, "pk", ""),
            details=details,
        )

    def perform_create(self, serializer):
        instance = serializer.save()
        self.log_action(f"{instance.__class__.__name__} created", instance)

    def perform_update(self, serializer):
        instance = serializer.save()
        self.log_action(f"{instance.__class__.__name__} updated", instance)

    def perform_destroy(self, instance):
        self.log_action(f"{instance.__class__.__name__} deleted", instance)
        instance.delete()

    def filter_queryset(self, queryset):
        queryset = super().filter_queryset(queryset)
        for query_param, model_field in self.exact_filter_fields.items():
            value = self.request.query_params.get(query_param)
            if value not in (None, ""):
                queryset = queryset.filter(**{model_field: value})
        return queryset
