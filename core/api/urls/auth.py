from django.urls import path

from core.api.views.auth import DashboardSummaryView, LoginView, LogoutView, MeView

urlpatterns = [
    path("auth/login/", LoginView.as_view(), name="api-login"),
    path("auth/logout/", LogoutView.as_view(), name="api-logout"),
    path("auth/me/", MeView.as_view(), name="api-me"),
    path("dashboard/summary/", DashboardSummaryView.as_view(), name="api-dashboard-summary"),
]

