from __future__ import annotations

from collections.abc import Callable

from django.db.models import QuerySet

from core.models import UserRole


RoleScope = Callable[[QuerySet, object], QuerySet]


def is_admin_user(user) -> bool:
    return bool(getattr(user, "is_superuser", False) or getattr(user, "role", None) == UserRole.ADMIN)


def apply_role_scope(queryset: QuerySet, user, role_scopes: dict[str, RoleScope | None], *, default_all: bool = False) -> QuerySet:
    """Apply a role-aware queryset scope while keeping admin access unrestricted."""

    if is_admin_user(user):
        return queryset

    scope = role_scopes.get(getattr(user, "role", ""))
    if scope is None:
        return queryset if default_all else queryset.none()
    return scope(queryset, user)
