"""Student-style API view modules for the HealthBridge backend."""

from .auth import DashboardSummaryView, LoginView, LogoutView, MeView
from .catalog import MedicalServiceViewSet, MedicationViewSet
from .providers import (
    PharmacyViewSet,
    ProviderServicePriceViewSet,
    ProviderViewSet,
)
from .system import AuditLogViewSet, NotificationViewSet
from .users import DependentViewSet, DoctorViewSet, EmployeeViewSet, InsuranceOfficerViewSet, UserViewSet
from .workflow import DispenseViewSet, InsuranceRequestViewSet, PrescriptionViewSet
