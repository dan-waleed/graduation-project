"""Student-style API serializer modules for the HealthBridge backend."""

from .auth import DashboardSummarySerializer, LoginRequestSerializer, LoginResponseSerializer, LogoutResponseSerializer
from .catalog import MedicalServiceSerializer, MedicationSerializer
from .providers import (
    LaboratorySerializer,
    MedicalCenterSerializer,
    MedicalImagingCenterSerializer,
    PharmacySerializer,
    PharmacistSerializer,
    ProviderSerializer,
    ProviderServicePriceSerializer,
)
from .system import AuditLogSerializer, NotificationSerializer
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
