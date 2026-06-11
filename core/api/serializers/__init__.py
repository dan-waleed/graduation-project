"""Student-style API serializer modules for the HealthBridge backend."""

from .auth import DashboardSummarySerializer, LoginRequestSerializer, LoginResponseSerializer, LogoutResponseSerializer
from .catalog import MedicalServiceSerializer, MedicationSerializer
from .providers import (
    PharmacySerializer,
    PharmacistSerializer,
    ProviderSerializer,
    ProviderServicePriceSerializer,
)
from .system import AuditLogSerializer, NotificationSerializer, SystemSettingsSerializer
from .users import (
    DependentSerializer,
    DoctorSerializer,
    DoctorSerializerForPUT,
    EmployeeCreateUserSerializer,
    EmployeeSerializer,
    InsuranceOfficerSerializer,
    UserSerializer,
    UserUpdateSerializer,
)
from .workflow import DispenseSerializer, InsuranceRequestSerializer, PrescriptionItemSerializer, PrescriptionSerializer
