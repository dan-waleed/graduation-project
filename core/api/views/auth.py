from django.contrib.auth import get_user_model, logout
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.generics import GenericAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from core.api.serializers import (
    DashboardSummarySerializer,
    LoginRequestSerializer,
    LoginResponseSerializer,
    LogoutResponseSerializer,
    UserSerializer,
)
from core.services.dashboard_service import build_dashboard_summary
from core.utils import create_audit_log

User = get_user_model()


class LoginView(GenericAPIView):
    serializer_class = LoginRequestSerializer
    authentication_classes = []
    permission_classes = []

    @extend_schema(
        request=LoginRequestSerializer,
        responses={status.HTTP_200_OK: LoginResponseSerializer},
        tags=["Authentication"],
    )
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        token, _ = Token.objects.get_or_create(user=user)
        create_audit_log(
            actor=user,
            action="User login",
            target_model="User",
            target_id=user.pk,
            details=f"username={user.username}",
        )
        return Response({"token": token.key, "user": UserSerializer(user).data}, status=status.HTTP_200_OK)


class LogoutView(GenericAPIView):
    serializer_class = LogoutResponseSerializer
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=None,
        responses={status.HTTP_200_OK: LogoutResponseSerializer},
        tags=["Authentication"],
    )
    def post(self, request, *args, **kwargs):
        create_audit_log(
            actor=request.user,
            action="User logout",
            target_model="User",
            target_id=request.user.pk,
            details=f"username={request.user.username}",
        )
        Token.objects.filter(user=request.user).delete()
        logout(request)
        return Response(
            LogoutResponseSerializer({"detail": "تم تسجيل الخروج بنجاح."}).data,
            status=status.HTTP_200_OK,
        )


class MeView(GenericAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    @extend_schema(
        responses={status.HTTP_200_OK: UserSerializer},
        tags=["Authentication"],
    )
    def get(self, request, *args, **kwargs):
        return Response(self.get_serializer(request.user).data, status=status.HTTP_200_OK)


class DashboardSummaryView(GenericAPIView):
    serializer_class = DashboardSummarySerializer
    permission_classes = [IsAuthenticated]

    @extend_schema(
        responses={status.HTTP_200_OK: DashboardSummarySerializer},
        tags=["Dashboard"],
    )
    def get(self, request, *args, **kwargs):
        payload = build_dashboard_summary(request.user)
        return Response(self.get_serializer(payload).data, status=status.HTTP_200_OK)
