from .models import UserRole


class RoleAccessMixin:
    """Simple per-action role gate for DRF viewsets."""

    role_permissions = {}

    def has_role_permission(self, request):
        if not request.user.is_authenticated:
            return False
        if request.user.is_superuser or request.user.role == UserRole.ADMIN:
            return True

        allowed_roles = self.role_permissions.get(getattr(self, "action", None))
        if allowed_roles is None:
            allowed_roles = self.role_permissions.get("*")
        if allowed_roles is None:
            return True
        return request.user.role in allowed_roles
