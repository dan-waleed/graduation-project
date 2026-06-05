
from importlib.util import find_spec
from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase

from .models import (
    AuditLog,
    Dependent,
    Dispense,
    DispenseStatus,
    Doctor,
    InsuranceOfficer,
    InsuranceRequest,
    InsuranceRequestStatus,
    Medication,
    Notification,
    Employee,
    Pharmacist,
    Pharmacy,
    Prescription,
    PrescriptionStatus,
    UserRole,
)

User = get_user_model()


class BaseAPITestCase(APITestCase):
    def create_user(self, username, role, password="pass12345", **extra_fields):
        user = User.objects.create_user(
            username=username,
            email=f"{username}@example.com",
            password=password,
            role=role,
            **extra_fields,
        )
        Token.objects.get_or_create(user=user)
        return user

    def auth(self, user):
        token = Token.objects.get(user=user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")


class HealthBridgeWorkflowTests(BaseAPITestCase):
    def setUp(self):
        self.admin = self.create_user("admin", UserRole.ADMIN, is_staff=True, is_superuser=True)

        self.employee_user = self.create_user("employee1", UserRole.EMPLOYEE)
        self.employee = Employee.objects.create(
            user=self.employee_user,
            medical_record_number="MRN-001",
            insurance_provider="Bridge Insurance",
        )

        self.other_employee_user = self.create_user("employee2", UserRole.EMPLOYEE)
        self.other_employee = Employee.objects.create(
            user=self.other_employee_user,
            medical_record_number="MRN-002",
        )

        self.doctor_user = self.create_user("doctor1", UserRole.DOCTOR)
        self.doctor = Doctor.objects.create(
            user=self.doctor_user,
            license_number="DOC-001",
            specialization="Cardiology",
        )

        self.officer_user = self.create_user("officer1", UserRole.INSURANCE_OFFICER)
        self.officer = InsuranceOfficer.objects.create(
            user=self.officer_user,
            organization_name="Bridge Insurance",
            employee_id="INS-001",
        )

        self.pharmacy = Pharmacy.objects.create(
            name="Main Pharmacy",
            license_number="PHM-001",
        )
        self.pharmacist_user = self.create_user("pharmacist1", UserRole.PHARMACIST)
        self.pharmacist = Pharmacist.objects.create(
            user=self.pharmacist_user,
            pharmacy=self.pharmacy,
            license_number="PHA-001",
        )

        self.medication = Medication.objects.create(
            name="Amoxicillin",
            strength="500mg",
            dosage_form="Capsule",
        )

    def test_login_endpoint_rXeturns_token_and_user(self):
        response = self.client.post(
            reverse("api-login"),
            {"username": "doctor1", "password": "pass12345"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("token", response.data)
        self.assertEqual(response.data["user"]["username"], "doctor1")

    def test_dashboard_summary_returns_role_aware_payload(self):
        Prescription.objects.create(
            prescription_number="RX-DASH-001",
            employee=self.employee,
            doctor=self.doctor,
            status=PrescriptionStatus.SENT,
            diagnosis="Checkup",
            issued_at=timezone.now(),
        )
        self.auth(self.doctor_user)
        response = self.client.get("/api/dashboard/summary/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["role"], UserRole.DOCTOR)
        self.assertTrue(response.data["metrics"])
        self.assertTrue(response.data["recent_activity"])

    def test_doctor_can_create_prescription_with_nested_items(self):
        self.auth(self.doctor_user)
        response = self.client.post(
            "/api/prescriptions/",
            {
                "prescription_number": "RX-001",
                "employee": self.employee.id,
                "doctor": self.doctor.id,
                "status": PrescriptionStatus.SENT,
                "diagnosis": "Infection",
                "notes": "Take after meals",
                "issued_at": timezone.now().isoformat(),
                "items": [
                    {
                        "medication": self.medication.id,
                        "dosage_instructions": "Twice daily",
                        "quantity": "20",
                        "duration": "10 days",
                        "substitution_allowed": False,
                    }
                ],
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        prescription = Prescription.objects.get(prescription_number="RX-001")
        self.assertEqual(prescription.doctor, self.doctor)
        self.assertEqual(prescription.items.count(), 1)
        self.assertTrue(Notification.objects.filter(user=self.employee_user, title="New medical order created").exists())
        self.assertTrue(AuditLog.objects.filter(action="Prescription created", target_id=str(prescription.id)).exists())

    def test_employee_only_sees_own_prescriptions(self):
        own_rx = Prescription.objects.create(
            prescription_number="RX-OWN",
            employee=self.employee,
            doctor=self.doctor,
            status=PrescriptionStatus.SENT,
            issued_at=timezone.now(),
        )
        Prescription.objects.create(
            prescription_number="RX-OTHER",
            employee=self.other_employee,
            doctor=self.doctor,
            status=PrescriptionStatus.SENT,
            issued_at=timezone.now(),
        )
        self.auth(self.employee_user)
        response = self.client.get("/api/prescriptions/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data["results"]
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["prescription_number"], own_rx.prescription_number)

    def test_admin_can_list_all_users(self):
        self.auth(self.admin)
        response = self.client.get("/api/users/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data["results"]
        usernames = {item["username"] for item in results}
        self.assertIn("admin", usernames)
        self.assertIn("doctor1", usernames)
        self.assertIn("employee1", usernames)

    def test_api_rejects_creating_a_second_admin_user(self):
        self.auth(self.admin)
        response = self.client.post(
            "/api/users/",
            {
                "username": "new_admin",
                "email": "new_admin@example.com",
                "first_name": "System",
                "last_name": "Admin",
                "role": UserRole.ADMIN,
                "password": "pass12345",
                "is_active": True,
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(User.objects.filter(username="new_admin").exists())

    def test_employee_role_user_created_from_api_gets_employee_profile(self):
        self.auth(self.admin)
        response = self.client.post(
            "/api/users/",
            {
                "username": "new_employee",
                "email": "new_employee@example.com",
                "first_name": "New",
                "last_name": "Employee",
                "role": UserRole.EMPLOYEE,
                "password": "pass12345",
                "is_active": True,
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        created = User.objects.get(username="new_employee")
        self.assertTrue(Employee.objects.filter(user=created).exists())

    def test_admin_can_create_employee_with_nested_dependents(self):
        self.auth(self.admin)
        response = self.client.post(
            "/api/employees/",
            {
                "user": {
                    "full_name": "Ahmad Ali",
                    "email": "ahmad@example.com",
                    "phone": "0599000000",
                    "password": "123456",
                },
                "national_id": "123456789",
                "university_id": "2024001",
                "insurance_number": "INS-100",
                "date_of_birth": "1990-01-01",
                "gender": "Male",
                "address": "Hebron",
                "dependents": [
                    {
                        "full_name": "Mohammad Ahmad",
                        "national_id": "987654321",
                        "relation": "son",
                        "date_of_birth": "2015-05-10",
                    },
                    {
                        "full_name": "Sara Ahmad",
                        "relation": "daughter",
                        "date_of_birth": "2018-03-20",
                    },
                    {
                        "full_name": "Mona Ahmad",
                        "relation": "wife",
                        "date_of_birth": "1992-07-15",
                    },
                ],
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        created_user = User.objects.get(email="ahmad@example.com")
        employee = Employee.objects.get(user=created_user)
        self.assertEqual(employee.national_id, "123456789")
        self.assertEqual(employee.university_id, "2024001")
        self.assertEqual(employee.insurance_number, "INS-100")
        self.assertEqual(employee.gender, "Male")
        self.assertEqual(employee.beneficiaries.count(), 3)
        self.assertEqual(response.data["full_name"], "Ahmad Ali")
        self.assertEqual(len(response.data["dependents"]), 3)
        created_relations = {item["full_name"]: item["relation"] for item in response.data["dependents"]}
        compatibility_relations = {item["full_name"]: item["relationship"] for item in response.data["dependents"]}
        self.assertEqual(created_relations["Mohammad Ahmad"], "son")
        self.assertEqual(compatibility_relations["Sara Ahmad"], "daughter")
        self.assertTrue(all(item["is_active"] for item in response.data["dependents"]))

    def test_employee_creation_rejects_invalid_dependent_relation(self):
        self.auth(self.admin)
        response = self.client.post(
            "/api/employees/",
            {
                "user": {
                    "full_name": "Invalid Dependent User",
                    "email": "invalid-dependent@example.com",
                    "password": "123456",
                },
                "dependents": [
                    {
                        "full_name": "Dependent One",
                        "relation": "brother",
                    }
                ],
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(User.objects.filter(email="invalid-dependent@example.com").exists())
        self.assertIn("dependents", response.data)

    def test_insurance_request_is_auto_approved_on_create(self):
        prescription = Prescription.objects.create(
            prescription_number="RX-INS-001",
            employee=self.employee,
            doctor=self.doctor,
            status=PrescriptionStatus.SENT,
            issued_at=timezone.now(),
        )
        self.auth(self.doctor_user)
        response = self.client.post(
            "/api/insurance/",
            {
                "prescription": prescription.id,
                "request_number": "INS-REQ-001",
                "status": InsuranceRequestStatus.PENDING,
                "submitted_at": timezone.now().isoformat(),
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        insurance_request = InsuranceRequest.objects.get(request_number="INS-REQ-001")
        prescription.refresh_from_db()
        self.assertEqual(insurance_request.status, InsuranceRequestStatus.APPROVED)
        self.assertIsNotNone(insurance_request.reviewed_at)
        self.assertEqual(prescription.status, PrescriptionStatus.APPROVED)

    def test_insurance_officer_can_review_but_cannot_change_request_status(self):
        prescription = Prescription.objects.create(
            prescription_number="RX-INS-002",
            employee=self.employee,
            doctor=self.doctor,
            status=PrescriptionStatus.APPROVED,
            issued_at=timezone.now(),
        )
        insurance_request = InsuranceRequest.objects.create(
            prescription=prescription,
            request_number="INS-REQ-002",
            status=InsuranceRequestStatus.APPROVED,
            submitted_at=timezone.now(),
            reviewed_at=timezone.now(),
        )
        self.auth(self.officer_user)
        response = self.client.patch(
            f"/api/insurance/{insurance_request.id}/",
            {"status": InsuranceRequestStatus.REJECTED},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_pharmacist_completed_dispense_marks_prescription_dispensed(self):
        prescription = Prescription.objects.create(
            prescription_number="RX-DSP-001",
            employee=self.employee,
            doctor=self.doctor,
            status=PrescriptionStatus.APPROVED,
            issued_at=timezone.now(),
        )
        self.auth(self.pharmacist_user)
        response = self.client.post(
            "/api/dispenses/",
            {
                "prescription": prescription.id,
                "pharmacist": self.pharmacist.id,
                "dispense_number": "DSP-001",
                "status": DispenseStatus.COMPLETED,
                "dispensed_at": timezone.now().isoformat(),
                "notes": "Fully dispensed",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        dispense = Dispense.objects.get(dispense_number="DSP-001")
        prescription.refresh_from_db()
        self.assertEqual(dispense.pharmacist, self.pharmacist)
        self.assertEqual(prescription.status, PrescriptionStatus.DISPENSED)

    def test_cannot_dispense_non_approved_prescription(self):
        prescription = Prescription.objects.create(
            prescription_number="RX-DSP-002",
            employee=self.employee,
            doctor=self.doctor,
            status=PrescriptionStatus.REJECTED,
            issued_at=timezone.now(),
        )
        self.auth(self.pharmacist_user)
        response = self.client.post(
            "/api/dispenses/",
            {
                "prescription": prescription.id,
                "dispense_number": "DSP-002",
                "status": DispenseStatus.COMPLETED,
                "dispensed_at": timezone.now().isoformat(),
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_qr_code_endpoint_returns_svg(self):
        if find_spec("qrcode") is None:
            self.skipTest("qrcode package is not installed")

        prescription = Prescription.objects.create(
            prescription_number="RX-QR-001",
            employee=self.employee,
            doctor=self.doctor,
            status=PrescriptionStatus.SENT,
            issued_at=timezone.now(),
        )
        self.auth(self.employee_user)
        response = self.client.get(f"/api/prescriptions/{prescription.id}/qr-code/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response["Content-Type"], "image/svg+xml")
