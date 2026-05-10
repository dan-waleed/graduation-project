from datetime import timedelta

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.utils import timezone

from core.models import (
    ContractStatus,
    Dependent,
    Dispense,
    DispenseStatus,
    Doctor,
    InsuranceOfficer,
    InsuranceRequest,
    InsuranceRequestStatus,
    Laboratory,
    Medication,
    MedicalCenter,
    MedicalImagingCenter,
    MedicalService,
    Notification,
    NotificationType,
    Employee,
    Pharmacist,
    Pharmacy,
    Prescription,
    PrescriptionItem,
    PrescriptionStatus,
    Provider,
    ProviderServicePrice,
    ProviderType,
    ServiceType,
    UserRole,
)

User = get_user_model()


class Command(BaseCommand):
    help = "Seed simple, presentation-ready demo data for HealthBridge."

    def handle(self, *args, **options):
        now = timezone.now()

        admin_user = self._upsert_user(
            username="admin_demo",
            password="admin12345",
            role=UserRole.ADMIN,
            first_name="مدير",
            last_name="النظام",
            email="admin_demo@healthbridge.local",
            phone_number="+970599100100",
            is_staff=True,
            is_superuser=True,
        )

        doctor_user = self._upsert_user(
            username="doctor_demo",
            password="demo12345",
            role=UserRole.DOCTOR,
            first_name="لينا",
            last_name="الشامي",
            email="doctor_demo@healthbridge.local",
            phone_number="+970599100101",
        )
        doctor, _ = Doctor.objects.update_or_create(
            user=doctor_user,
            defaults={
                "license_number": "DOC-DEMO-001",
                "specialization": "طب الأسرة",
                "clinic_name": "عيادة الجامعة الطبية",
                "clinic_address": "الخليل - جامعة بوليتكنك فلسطين - المبنى الطبي",
                "consultation_price": 80,
                "contract_status": ContractStatus.ACTIVE,
            },
        )

        employee_user = self._upsert_user(
            username="patient_demo",
            password="demo12345",
            role=UserRole.EMPLOYEE,
            first_name="أحمد",
            last_name="الخطيب",
            email="patient_demo@healthbridge.local",
            phone_number="+970599100102",
        )
        employee, _ = Employee.objects.update_or_create(
            user=employee_user,
            defaults={
                "medical_record_number": "MRN-DEMO-001",
                "date_of_birth": "2001-03-14",
                "insurance_provider": "التأمين الصحي الجامعي",
                "address": "الخليل - فلسطين",
            },
        )

        dependent, _ = Dependent.objects.update_or_create(
            employee=employee,
            full_name="سارة الخطيب",
            defaults={
                "relation": "daughter",
                "date_of_birth": "2006-07-21",
                "notes": "مستفيدة مرتبطة بالحساب لتجربة الوصفات العائلية.",
            },
        )

        officer_user = self._upsert_user(
            username="insurance_demo",
            password="demo12345",
            role=UserRole.INSURANCE_OFFICER,
            first_name="سمر",
            last_name="التميمي",
            email="insurance_demo@healthbridge.local",
            phone_number="+970599100103",
        )
        officer, _ = InsuranceOfficer.objects.update_or_create(
            user=officer_user,
            defaults={
                "organization_name": "قسم التأمين الصحي",
                "employee_id": "INS-DEMO-001",
            },
        )

        doctor_provider = self._upsert_provider(
            provider_name="عيادة الجامعة الطبية",
            provider_type=ProviderType.DOCTOR,
            city="الخليل",
            address="جامعة بوليتكنك فلسطين - المبنى الطبي",
            phone="+97022990010",
            google_maps_url="https://maps.google.com/?q=Palestine+Polytechnic+University",
            working_hours="08:00 - 15:00",
        )
        if doctor.provider_id != doctor_provider.id:
            doctor.provider = doctor_provider
            doctor.save(update_fields=["provider", "updated_at"])

        pharmacy, _ = Pharmacy.objects.update_or_create(
            license_number="PHA-DEMO-001",
            defaults={
                "name": "صيدلية الجامعة",
                "address": "الخليل - شارع الجامعة",
                "phone_number": "+97022990011",
                "is_active": True,
            },
        )
        pharmacy_provider = self._upsert_provider(
            provider_name="صيدلية الجامعة",
            provider_type=ProviderType.PHARMACY,
            city="الخليل",
            address="الخليل - شارع الجامعة",
            phone="+97022990011",
            google_maps_url="https://maps.google.com/?q=Hebron+University+Pharmacy",
            working_hours="08:00 - 17:00",
        )
        if pharmacy.provider_id != pharmacy_provider.id:
            pharmacy.provider = pharmacy_provider
            pharmacy.save(update_fields=["provider", "updated_at"])

        pharmacist_user = self._upsert_user(
            username="pharmacist_demo",
            password="demo12345",
            role=UserRole.PHARMACIST,
            first_name="سامر",
            last_name="نزال",
            email="pharmacist_demo@healthbridge.local",
            phone_number="+970599100104",
        )
        pharmacist, _ = Pharmacist.objects.update_or_create(
            user=pharmacist_user,
            defaults={
                "pharmacy": pharmacy,
                "license_number": "PHARM-DEMO-001",
            },
        )

        laboratory_user = self._upsert_user(
            username="lab_demo",
            password="demo12345",
            role=UserRole.LABORATORY,
            first_name="مختبر",
            last_name="الجامعة",
            email="lab_demo@healthbridge.local",
            phone_number="+970599100105",
        )
        laboratory_provider = self._upsert_provider(
            provider_name="مختبر الجامعة",
            provider_type=ProviderType.LABORATORY,
            city="الخليل",
            address="جامعة بوليتكنك فلسطين - المبنى الصحي",
            phone="+97022990012",
            google_maps_url="https://maps.google.com/?q=Hebron+University+Lab",
            working_hours="08:00 - 15:00",
        )
        laboratory, _ = Laboratory.objects.update_or_create(
            user=laboratory_user,
            defaults={
                "provider": laboratory_provider,
                "license_number": "LAB-DEMO-001",
            },
        )

        imaging_user = self._upsert_user(
            username="imaging_demo",
            password="demo12345",
            role=UserRole.IMAGING_CENTER,
            first_name="مركز",
            last_name="التصوير",
            email="imaging_demo@healthbridge.local",
            phone_number="+970599100106",
        )
        imaging_provider = self._upsert_provider(
            provider_name="مركز التصوير الطبي الجامعي",
            provider_type=ProviderType.IMAGING_CENTER,
            city="الخليل",
            address="الخليل - المنطقة الطبية",
            phone="+97022990013",
            google_maps_url="https://maps.google.com/?q=Hebron+Imaging+Center",
            working_hours="09:00 - 16:00",
        )
        imaging_center, _ = MedicalImagingCenter.objects.update_or_create(
            user=imaging_user,
            defaults={
                "provider": imaging_provider,
                "license_number": "IMG-DEMO-001",
            },
        )

        medical_center_user = self._upsert_user(
            username="medical_center_demo",
            password="demo12345",
            role=UserRole.MEDICAL_CENTER,
            first_name="المركز",
            last_name="الطبي",
            email="medical_center_demo@healthbridge.local",
            phone_number="+970599100107",
        )
        medical_center_provider = self._upsert_provider(
            provider_name="المركز الطبي الجامعي",
            provider_type=ProviderType.MEDICAL_CENTER,
            city="الخليل",
            address="جامعة بوليتكنك فلسطين - المركز الطبي",
            phone="+97022990014",
            google_maps_url="https://maps.google.com/?q=Hebron+Medical+Center",
            working_hours="08:00 - 15:00",
        )
        medical_center, _ = MedicalCenter.objects.update_or_create(
            user=medical_center_user,
            defaults={
                "provider": medical_center_provider,
                "license_number": "MC-DEMO-001",
            },
        )

        services = {
            "consultation": self._upsert_service(
                service_name="استشارة طب أسرة",
                service_type=ServiceType.CONSULTATION,
                default_price=80,
                coverage_percentage=50,
                requires_insurance_approval=False,
                description="استشارة طبية للموظف أو المستفيد.",
            ),
            "medication": self._upsert_service(
                service_name="وصفة دوائية",
                service_type=ServiceType.MEDICATION,
                default_price=100,
                coverage_percentage=50,
                requires_insurance_approval=False,
                description="خدمة صرف وصفة دوائية.",
            ),
            "lab": self._upsert_service(
                service_name="فحص CBC",
                service_type=ServiceType.LAB_TEST,
                default_price=60,
                coverage_percentage=75,
                requires_insurance_approval=True,
                description="فحص مخبري أساسي.",
            ),
            "imaging": self._upsert_service(
                service_name="تصوير X-Ray",
                service_type=ServiceType.IMAGING,
                default_price=180,
                coverage_percentage=50,
                requires_insurance_approval=True,
                description="تصوير أشعة سينية.",
            ),
            "procedure": self._upsert_service(
                service_name="إجراء طبي بسيط",
                service_type=ServiceType.PROCEDURE,
                default_price=120,
                coverage_percentage=40,
                requires_insurance_approval=True,
                description="إجراء طبي داخل المركز الطبي.",
            ),
        }

        self._upsert_provider_service_price(pharmacy_provider, services["medication"], 100, 50, False)
        self._upsert_provider_service_price(laboratory_provider, services["lab"], 60, 75, True)
        self._upsert_provider_service_price(imaging_provider, services["imaging"], 180, 50, True)
        self._upsert_provider_service_price(medical_center_provider, services["procedure"], 120, 40, True)

        medications = {
            "باراسيتامول 500mg": self._upsert_medication(
                name="باراسيتامول",
                generic_name="Acetaminophen",
                strength="500mg",
                dosage_form="أقراص",
                manufacturer="الشركة الفلسطينية للأدوية",
                description="مسكن للآلام وخافض للحرارة.",
            ),
            "أموكسيسيلين 500mg": self._upsert_medication(
                name="أموكسيسيلين",
                generic_name="Amoxicillin",
                strength="500mg",
                dosage_form="كبسولات",
                manufacturer="بيت جالا للأدوية",
                description="مضاد حيوي واسع الاستخدام.",
            ),
            "أوميبرازول 20mg": self._upsert_medication(
                name="أوميبرازول",
                generic_name="Omeprazole",
                strength="20mg",
                dosage_form="كبسولات",
                manufacturer="دار الشفاء",
                description="لتخفيف حموضة المعدة والارتجاع.",
            ),
            "فيتامين د 50000IU": self._upsert_medication(
                name="فيتامين د",
                generic_name="Cholecalciferol",
                strength="50000IU",
                dosage_form="كبسولات",
                manufacturer="الشركة الوطنية للدواء",
                description="مكمل لعلاج نقص فيتامين د.",
            ),
        }

        approved_rx = self._upsert_prescription(
            prescription_number="RX-DEMO-001",
            employee=employee,
            doctor=doctor,
            beneficiary=None,
            provider=pharmacy_provider,
            service=services["medication"],
            service_type=ServiceType.MEDICATION,
            status=PrescriptionStatus.APPROVED,
            diagnosis="التهاب حلق بسيط مع حرارة خفيفة",
            notes="يمكن صرف الوصفة مباشرة بعد إبراز الرمز.",
            issued_at=now - timedelta(days=1),
            valid_until=now + timedelta(days=6),
            final_price=100,
            coverage_percentage=50,
            covered_amount=50,
            employee_share=50,
            requires_insurance_approval=False,
            items=[
                {
                    "medication": medications["أموكسيسيلين 500mg"],
                    "dosage_instructions": "كبسولة واحدة كل 8 ساعات بعد الطعام",
                    "quantity": "21 كبسولة",
                    "duration": "7 أيام",
                },
                {
                    "medication": medications["باراسيتامول 500mg"],
                    "dosage_instructions": "حبة واحدة عند اللزوم كل 8 ساعات",
                    "quantity": "10 أقراص",
                    "duration": "3 أيام",
                },
            ],
        )

        under_review_rx = self._upsert_prescription(
            prescription_number="RX-DEMO-002",
            employee=employee,
            doctor=doctor,
            beneficiary=dependent,
            provider=laboratory_provider,
            service=services["lab"],
            service_type=ServiceType.LAB_TEST,
            status=PrescriptionStatus.PENDING_INSURANCE_APPROVAL,
            diagnosis="تحسس موسمي وسعال خفيف",
            notes="تم إرسالها بانتظار قرار التأمين.",
            issued_at=now - timedelta(days=2),
            valid_until=now + timedelta(days=5),
            final_price=60,
            coverage_percentage=75,
            covered_amount=45,
            employee_share=15,
            requires_insurance_approval=True,
            items=[
                {
                    "medication": medications["أوميبرازول 20mg"],
                    "dosage_instructions": "كبسولة صباحًا قبل الطعام",
                    "quantity": "14 كبسولة",
                    "duration": "14 يومًا",
                },
            ],
        )

        dispensed_rx = self._upsert_prescription(
            prescription_number="RX-DEMO-003",
            employee=employee,
            doctor=doctor,
            beneficiary=None,
            provider=pharmacy_provider,
            service=services["medication"],
            service_type=ServiceType.MEDICATION,
            status=PrescriptionStatus.DISPENSED,
            diagnosis="نقص فيتامين د",
            notes="تم صرف الوصفة كاملة من صيدلية الجامعة.",
            issued_at=now - timedelta(days=7),
            valid_until=now + timedelta(days=23),
            final_price=100,
            coverage_percentage=50,
            covered_amount=50,
            employee_share=50,
            requires_insurance_approval=False,
            items=[
                {
                    "medication": medications["فيتامين د 50000IU"],
                    "dosage_instructions": "كبسولة واحدة أسبوعيًا",
                    "quantity": "4 كبسولات",
                    "duration": "4 أسابيع",
                },
            ],
        )

        submitted_rx = self._upsert_prescription(
            prescription_number="RX-DEMO-004",
            employee=employee,
            doctor=doctor,
            beneficiary=None,
            provider=pharmacy_provider,
            service=services["medication"],
            service_type=ServiceType.MEDICATION,
            status=PrescriptionStatus.SENT,
            diagnosis="صداع وإرهاق عام",
            notes="وصفة تم إرسالها حديثًا لإظهار سير العمل.",
            issued_at=now - timedelta(hours=6),
            valid_until=now + timedelta(days=4),
            final_price=100,
            coverage_percentage=50,
            covered_amount=50,
            employee_share=50,
            requires_insurance_approval=False,
            items=[
                {
                    "medication": medications["باراسيتامول 500mg"],
                    "dosage_instructions": "حبة واحدة بعد الطعام مرتين يوميًا",
                    "quantity": "6 أقراص",
                    "duration": "3 أيام",
                },
            ],
        )

        imaging_rx = self._upsert_prescription(
            prescription_number="IMG-DEMO-001",
            employee=employee,
            doctor=doctor,
            beneficiary=None,
            provider=imaging_provider,
            service=services["imaging"],
            service_type=ServiceType.IMAGING,
            status=PrescriptionStatus.APPROVED,
            diagnosis="ألم في اليد اليمنى بعد سقوط بسيط",
            notes="مطلوب تصوير أشعة لليد.",
            issued_at=now - timedelta(hours=10),
            valid_until=now + timedelta(days=7),
            final_price=180,
            coverage_percentage=50,
            covered_amount=90,
            employee_share=90,
            requires_insurance_approval=True,
            items=[],
        )

        procedure_rx = self._upsert_prescription(
            prescription_number="PROC-DEMO-001",
            employee=employee,
            doctor=doctor,
            beneficiary=dependent,
            provider=medical_center_provider,
            service=services["procedure"],
            service_type=ServiceType.PROCEDURE,
            status=PrescriptionStatus.PERFORMED,
            diagnosis="إجراء متابعة علاجية بسيط",
            notes="تم تنفيذ الإجراء داخل المركز الطبي.",
            issued_at=now - timedelta(days=3),
            valid_until=now + timedelta(days=1),
            final_price=120,
            coverage_percentage=40,
            covered_amount=48,
            employee_share=72,
            requires_insurance_approval=True,
            provider_notes="تم تنفيذ الإجراء بنجاح دون مضاعفات.",
            items=[],
        )

        approved_request = self._upsert_insurance_request(
            prescription=approved_rx,
            reviewed_by=officer,
            request_number="INSREQ-DEMO-001",
            status=InsuranceRequestStatus.APPROVED,
            submitted_at=now - timedelta(days=1),
            reviewed_at=now - timedelta(hours=20),
            response_notes="تمت الموافقة على التغطية حسب بنود الوثيقة.",
        )
        pending_request = self._upsert_insurance_request(
            prescription=under_review_rx,
            reviewed_by=officer,
            request_number="INSREQ-DEMO-002",
            status=InsuranceRequestStatus.PENDING,
            submitted_at=now - timedelta(days=2),
            reviewed_at=None,
            response_notes="الطلب قيد المراجعة من موظف التأمين.",
        )
        latest_request = self._upsert_insurance_request(
            prescription=submitted_rx,
            reviewed_by=None,
            request_number="INSREQ-DEMO-003",
            status=InsuranceRequestStatus.PENDING,
            submitted_at=now - timedelta(hours=5),
            reviewed_at=None,
            response_notes="تم استلام الطلب وسيتم الرد عليه قريبًا.",
        )
        imaging_request = self._upsert_insurance_request(
            prescription=imaging_rx,
            reviewed_by=officer,
            request_number="INSREQ-DEMO-004",
            status=InsuranceRequestStatus.APPROVED,
            submitted_at=now - timedelta(hours=9),
            reviewed_at=now - timedelta(hours=8),
            response_notes="تمت الموافقة على خدمة التصوير الطبي.",
        )
        procedure_request = self._upsert_insurance_request(
            prescription=procedure_rx,
            reviewed_by=officer,
            request_number="INSREQ-DEMO-005",
            status=InsuranceRequestStatus.APPROVED,
            submitted_at=now - timedelta(days=3),
            reviewed_at=now - timedelta(days=3) + timedelta(hours=2),
            response_notes="تمت الموافقة على الإجراء الطبي.",
        )

        self._upsert_dispense(
            prescription=dispensed_rx,
            pharmacist=pharmacist,
            dispense_number="DSP-DEMO-001",
            status=DispenseStatus.COMPLETED,
            dispensed_at=now - timedelta(days=6),
            notes="تم صرف العلاج كاملًا مع شرح التعليمات للمريض.",
        )

        self._upsert_notification(
            user=employee_user,
            notification_type=NotificationType.PRESCRIPTION_CREATED,
            title="وصفة جديدة بانتظار المتابعة",
            message="تم إنشاء الوصفة RX-DEMO-004 وإرسالها لمراجعة التأمين.",
            related_entity_type="Prescription",
            related_entity_id=submitted_rx.id,
        )
        self._upsert_notification(
            user=employee_user,
            notification_type=NotificationType.INSURANCE_UPDATED,
            title="تمت الموافقة على طلب التأمين",
            message="تمت الموافقة على تغطية الوصفة RX-DEMO-001 ويمكنك مراجعة الصيدلية.",
            related_entity_type="InsuranceRequest",
            related_entity_id=approved_request.id,
        )
        self._upsert_notification(
            user=doctor_user,
            notification_type=NotificationType.SYSTEM_ALERT,
            title="بيانات عرض الطبيب جاهزة",
            message="يمكنك تجربة إنشاء وصفة جديدة أو مراجعة الوصفات السابقة.",
            related_entity_type="Prescription",
            related_entity_id=approved_rx.id,
        )
        self._upsert_notification(
            user=pharmacist_user,
            notification_type=NotificationType.DISPENSE_UPDATED,
            title="وصفة جاهزة للصرف",
            message="الوصفة RX-DEMO-001 معتمدة وجاهزة للتسليم للموظف الجامعي.",
            related_entity_type="Prescription",
            related_entity_id=approved_rx.id,
        )
        self._upsert_notification(
            user=officer_user,
            notification_type=NotificationType.INSURANCE_UPDATED,
            title="طلبات تأمين جديدة",
            message="يوجد طلبان معلقان بانتظار المراجعة واتخاذ القرار.",
            related_entity_type="InsuranceRequest",
            related_entity_id=latest_request.id,
        )
        self._upsert_notification(
            user=laboratory_user,
            notification_type=NotificationType.PRESCRIPTION_CREATED,
            title="طلب مختبر جديد",
            message="تم توجيه طلب مختبر جديد إلى مختبر الجامعة.",
            related_entity_type="Prescription",
            related_entity_id=under_review_rx.id,
        )
        self._upsert_notification(
            user=imaging_user,
            notification_type=NotificationType.PRESCRIPTION_CREATED,
            title="طلب تصوير طبي جديد",
            message="تمت الموافقة على طلب تصوير جديد وهو جاهز للتنفيذ.",
            related_entity_type="Prescription",
            related_entity_id=imaging_rx.id,
        )
        self._upsert_notification(
            user=medical_center_user,
            notification_type=NotificationType.SYSTEM_ALERT,
            title="طلب طبي منفذ",
            message="يوجد طلب طبي تم تنفيذه ويحتاج مراجعة السجل.",
            related_entity_type="Prescription",
            related_entity_id=procedure_rx.id,
        )
        self._upsert_notification(
            user=admin_user,
            notification_type=NotificationType.SYSTEM_ALERT,
            title="نظام العرض جاهز",
            message="تم تجهيز الحسابات والبيانات الأساسية لعرض مشروع التخرج.",
        )

        self.stdout.write(self.style.SUCCESS("تم تجهيز بيانات العرض بنجاح."))
        self.stdout.write("Admin: admin_demo / admin12345")
        self.stdout.write("Doctor: doctor_demo / demo12345")
        self.stdout.write("Employee: patient_demo / demo12345")
        self.stdout.write("Pharmacist: pharmacist_demo / demo12345")
        self.stdout.write("Insurance Officer: insurance_demo / demo12345")
        self.stdout.write("Laboratory: lab_demo / demo12345")
        self.stdout.write("Imaging Center: imaging_demo / demo12345")
        self.stdout.write("Medical Center: medical_center_demo / demo12345")

    def _upsert_user(self, **defaults):
        username = defaults.pop("username")
        password = defaults.pop("password")
        defaults.setdefault("is_active", True)
        user, _ = User.objects.update_or_create(username=username, defaults=defaults)
        user.set_password(password)
        user.save()
        return user

    def _upsert_medication(self, **defaults):
        medication, _ = Medication.objects.update_or_create(
            name=defaults["name"],
            strength=defaults["strength"],
            defaults={
                "generic_name": defaults["generic_name"],
                "dosage_form": defaults["dosage_form"],
                "manufacturer": defaults["manufacturer"],
                "description": defaults["description"],
                "is_active": True,
            },
        )
        return medication

    def _upsert_prescription(
        self,
        *,
        prescription_number,
        employee,
        doctor,
        beneficiary,
        provider,
        service,
        service_type,
        status,
        diagnosis,
        notes,
        issued_at,
        valid_until,
        final_price,
        coverage_percentage,
        covered_amount,
        employee_share,
        requires_insurance_approval,
        provider_notes="",
        items,
    ):
        prescription, _ = Prescription.objects.update_or_create(
            prescription_number=prescription_number,
            defaults={
                "employee": employee,
                "doctor": doctor,
                "beneficiary": beneficiary,
                "provider": provider,
                "service": service,
                "service_type": service_type,
                "status": status,
                "requires_insurance_approval": requires_insurance_approval,
                "coverage_percentage": coverage_percentage,
                "covered_amount": covered_amount,
                "employee_share": employee_share,
                "final_price": final_price,
                "diagnosis": diagnosis,
                "notes": notes,
                "provider_notes": provider_notes,
                "issued_at": issued_at,
                "valid_until": valid_until,
            },
        )
        prescription.items.all().delete()
        for item in items:
            PrescriptionItem.objects.create(
                prescription=prescription,
                medication=item["medication"],
                dosage_instructions=item["dosage_instructions"],
                quantity=item["quantity"],
                duration=item["duration"],
                substitution_allowed=item.get("substitution_allowed", False),
            )
        return prescription

    def _upsert_insurance_request(
        self,
        *,
        prescription,
        reviewed_by,
        request_number,
        status,
        submitted_at,
        reviewed_at,
        response_notes,
    ):
        insurance_request, _ = InsuranceRequest.objects.update_or_create(
            prescription=prescription,
            defaults={
                "reviewed_by": reviewed_by,
                "request_number": request_number,
                "status": status,
                "submitted_at": submitted_at,
                "reviewed_at": reviewed_at,
                "response_notes": response_notes,
            },
        )
        return insurance_request

    def _upsert_dispense(
        self,
        *,
        prescription,
        pharmacist,
        dispense_number,
        status,
        dispensed_at,
        notes,
    ):
        Dispense.objects.update_or_create(
            dispense_number=dispense_number,
            defaults={
                "prescription": prescription,
                "pharmacist": pharmacist,
                "status": status,
                "dispensed_at": dispensed_at,
                "notes": notes,
            },
        )

    def _upsert_provider(
        self,
        *,
        provider_name,
        provider_type,
        city,
        address,
        phone,
        google_maps_url,
        working_hours,
    ):
        provider, _ = Provider.objects.update_or_create(
            provider_name=provider_name,
            provider_type=provider_type,
            defaults={
                "city": city,
                "address": address,
                "phone": phone,
                "google_maps_url": google_maps_url,
                "working_hours": working_hours,
                "contract_status": ContractStatus.ACTIVE,
            },
        )
        return provider

    def _upsert_service(
        self,
        *,
        service_name,
        service_type,
        default_price,
        coverage_percentage,
        requires_insurance_approval,
        description,
    ):
        service, _ = MedicalService.objects.update_or_create(
            service_name=service_name,
            service_type=service_type,
            defaults={
                "default_price": default_price,
                "coverage_percentage": coverage_percentage,
                "employee_share": default_price - ((default_price * coverage_percentage) / 100),
                "requires_insurance_approval": requires_insurance_approval,
                "description": description,
            },
        )
        return service

    def _upsert_provider_service_price(
        self,
        provider,
        service,
        price,
        coverage_percentage,
        requires_pre_approval,
    ):
        ProviderServicePrice.objects.update_or_create(
            provider=provider,
            service=service,
            defaults={
                "price": price,
                "coverage_percentage": coverage_percentage,
                "covered_amount_limit": (price * coverage_percentage) / 100,
                "employee_share": price - ((price * coverage_percentage) / 100),
                "is_available": True,
                "requires_pre_approval": requires_pre_approval,
            },
        )

    def _upsert_notification(
        self,
        *,
        user,
        notification_type,
        title,
        message,
        related_entity_type="",
        related_entity_id="",
    ):
        Notification.objects.update_or_create(
            user=user,
            title=title,
            defaults={
                "notification_type": notification_type,
                "message": message,
                "related_entity_type": related_entity_type,
                "related_entity_id": str(related_entity_id) if related_entity_id else "",
                "is_read": False,
                "read_at": None,
            },
        )
