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
    Medication,
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

IMPORTED_DOCTORS = [
    {
        "full_name": "شريف الطردة",
        "specialization": "طب عام",
        "clinic_name": "عيادات الشريف",
        "clinic_address": "تفوح",
        "phone_number": "0599340234",
    },
    {
        "full_name": "جهاد العويوي",
        "specialization": "طب عام",
        "clinic_name": "عيادة جهاد العويوي",
        "clinic_address": "باب الزاوية",
        "phone_number": "022229645",
    },
    {
        "full_name": "محمود سليمان الطيطي",
        "specialization": "طب عام",
        "clinic_name": "عيادة محمود سليمان الطيطي",
        "clinic_address": "الخليل",
        "phone_number": "0599887000",
    },
    {
        "full_name": "احمد ابوميالة",
        "specialization": "طب عام",
        "clinic_name": "عيادة احمد ابوميالة",
        "clinic_address": "مفرق العجوري",
        "phone_number": "0599759517",
    },
    {
        "full_name": "منتصر عبد الرحيم القواسمي",
        "specialization": "طب عام",
        "clinic_name": "عيادة منتصر عبد الرحيم القواسمي",
        "clinic_address": "أبو كتيلة",
        "phone_number": "0598502501",
    },
    {
        "full_name": "جهاد شاور",
        "specialization": "جراحة",
        "clinic_name": "عيادة جهاد شاور",
        "clinic_address": "عمارة ستي سنتر",
        "phone_number": "0599873535",
    },
    {
        "full_name": "رفيق سلهب",
        "specialization": "جراحة",
        "clinic_name": "عيادة رفيق سلهب",
        "clinic_address": "عمارة ابو ارميلة",
        "phone_number": "0599840836",
    },
    {
        "full_name": "محمد جميل الهشلمون",
        "specialization": "جراحة",
        "clinic_name": "عيادة محمد جميل الهشلمون",
        "clinic_address": "عمارة البدر",
        "phone_number": "022256777",
    },
    {
        "full_name": "رشاد مرشد الزرو",
        "specialization": "جراحة",
        "clinic_name": "عيادة رشاد مرشد الزرو",
        "clinic_address": "عمارة طيبة",
        "phone_number": "0599368123",
    },
    {
        "full_name": "وسام المحتسب",
        "specialization": "جراحة",
        "clinic_name": "عيادة وسام المحتسب",
        "clinic_address": "طلعة عالية",
        "phone_number": "0599311545",
    },
    {
        "full_name": "أحمد القواسمي",
        "specialization": "أطفال",
        "clinic_name": "عيادة أحمد القواسمي",
        "clinic_address": "مفرق الجامعة",
        "phone_number": "022229144",
    },
    {
        "full_name": "بسام مرقه",
        "specialization": "أطفال",
        "clinic_name": "عيادة بسام مرقه",
        "clinic_address": "باب الزاوية",
        "phone_number": "022226479",
    },
    {
        "full_name": "مهند ابو ساكور",
        "specialization": "أطفال",
        "clinic_name": "عيادة مهند ابو ساكور",
        "clinic_address": "ترقوميا",
        "phone_number": "0599884443",
    },
    {
        "full_name": "فواز العويوي",
        "specialization": "أطفال",
        "clinic_name": "عيادة فواز العويوي",
        "clinic_address": "وادي التفاح",
        "phone_number": "022225176",
    },
    {
        "full_name": "احمد محمود ابو اسعد",
        "specialization": "أطفال",
        "clinic_name": "عيادة احمد محمود ابو اسعد",
        "clinic_address": "اذنا",
        "phone_number": "0599759521",
    },
    {
        "full_name": "خليل العبد",
        "specialization": "باطني",
        "clinic_name": "عيادة خليل العبد",
        "clinic_address": "باب الزاوية",
        "phone_number": "022225434",
    },
    {
        "full_name": "سمير القاضي",
        "specialization": "باطني",
        "clinic_name": "عيادة سمير القاضي",
        "clinic_address": "عمارة الرشاد",
        "phone_number": "022251444",
    },
    {
        "full_name": "ماجد الدويك",
        "specialization": "باطني",
        "clinic_name": "عيادة ماجد الدويك",
        "clinic_address": "المستشفى الاهلي - العيادات الخارجية",
        "phone_number": "022220353",
    },
    {
        "full_name": "صبحي ارشيد",
        "specialization": "باطني",
        "clinic_name": "عيادة صبحي ارشيد",
        "clinic_address": "مجمع الواحة",
        "phone_number": "0599733799",
    },
    {
        "full_name": "جميل عبد الحافظ الزرو",
        "specialization": "باطني",
        "clinic_name": "عيادة جميل عبد الحافظ الزرو",
        "clinic_address": "مجمع تبارك",
        "phone_number": "0599759085",
    },
]

IMPORTED_PHARMACIES = [
    {"name": "صيدلية الجامعة", "address": "مفرق الجامعة", "phone_number": "022229301"},
    {"name": "البشير و القدس و صلاح الدين", "address": "باب الزاوية وراس الجورة", "phone_number": "022228878"},
    {"name": "صيدلية الانصار", "address": "مقابل محطة الانصار", "phone_number": "022252632"},
    {"name": "صيدلية الكوثر و المدينة المنورة", "address": "واد التفاح", "phone_number": "022229572"},
    {"name": "صيدلية الجزيرة", "address": "المناره", "phone_number": "022222237"},
    {"name": "صيدلية الرحمة", "address": "الشلالة", "phone_number": "022228287"},
    {"name": "صيدلية السيد", "address": "باب الزاوية", "phone_number": "022220538"},
    {"name": "صيدلية الشفاء و القواسمي", "address": "باب الزاوية/وادي التفاح", "phone_number": "022228221"},
    {"name": "صيدلية الرازي", "address": "باب الزاوية", "phone_number": "022229791"},
    {"name": "صيدلية الفردوس", "address": "الحاووز/ السلام", "phone_number": "022226999"},
    {"name": "صيدلية البوليتكنك", "address": "واد الهريا", "phone_number": "022234965"},
    {"name": "صيدلية النجاح", "address": "الحرس", "phone_number": "022212470"},
    {"name": "صيدلية الايمان", "address": "نمره", "phone_number": "022228210"},
    {"name": "صيدلية بلسم", "address": "حلحول", "phone_number": "022227476"},
    {"name": "صيدلية البدر", "address": "الخليل - الجلده - مفرق وادي الكرم", "phone_number": "022229727"},
    {"name": "صيدلية شروق", "address": "بجانب الرابطة", "phone_number": "022225058"},
    {"name": "صيدلية الحرية", "address": "وادي الهرية", "phone_number": "022234210"},
    {"name": "صيدلية ناصر", "address": "دورا", "phone_number": "022280065"},
    {"name": "صيدلية ابو الفيلات", "address": "بجانب صالة الخيام", "phone_number": "022290464"},
    {"name": "صيدلية نمره", "address": "حبايل الرياح", "phone_number": "022221749"},
]

FAKE_EMPLOYEE_NAMES = [
    "لؤي ناصر التميمي",
    "سجى عارف الجعبري",
    "محمود يوسف الرجبي",
    "ديما سامي القواسمي",
    "حمزة خالد الشرباتي",
    "تالا نضال المحتسب",
    "عمر وائل ابو سنينة",
    "ريم احمد زلوم",
    "معاذ فادي زغير",
    "ياسمين رائد التكروري",
    "كرم اياد النتشة",
    "بيان رامي السلايمة",
    "أوس عبد الرحمن ابو عيشة",
    "لين محمد الهيموني",
    "أنس مروان القفيشة",
    "سارة مؤمن الحلايقة",
    "باسل طارق دعنا",
    "هديل مازن الجلدة",
    "علي أمين نيروخ",
    "رند بشار مسودة",
]


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
                "clinic_name": "العيادة الطبية",
                "clinic_address": "الخليل - المبنى الطبي",
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
            provider_name="العيادة الطبية",
            provider_type=ProviderType.DOCTOR,
            city="الخليل",
            address="الخليل - المبنى الطبي",
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
                "name": "صيدلية المشروع",
                "address": "الخليل - شارع الجامعة",
                "phone_number": "+97022990011",
                "is_active": True,
            },
        )
        pharmacy_provider = self._upsert_provider(
            provider_name="صيدلية المشروع",
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
        }

        self._upsert_provider_service_price(pharmacy_provider, services["medication"], 100, 50, False)

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

        approved_request = self._upsert_insurance_request(
            prescription=approved_rx,
            reviewed_by=officer,
            request_number="INSREQ-DEMO-001",
            status=InsuranceRequestStatus.APPROVED,
            submitted_at=now - timedelta(days=1),
            reviewed_at=now - timedelta(hours=20),
            response_notes="تمت الموافقة على التغطية حسب بنود الوثيقة.",
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
            user=admin_user,
            notification_type=NotificationType.SYSTEM_ALERT,
            title="نظام العرض جاهز",
            message="تم تجهيز الحسابات والبيانات الأساسية لعرض مشروع التخرج.",
        )

        imported_doctors = self._seed_imported_doctors()
        imported_pharmacies = self._seed_imported_pharmacies()
        fake_employees = self._seed_fake_employees()

        self.stdout.write(self.style.SUCCESS("تم تجهيز بيانات العرض بنجاح."))
        self.stdout.write("Admin: admin_demo / admin12345")
        self.stdout.write("Doctor: doctor_demo / demo12345")
        self.stdout.write("Employee: patient_demo / demo12345")
        self.stdout.write("Pharmacist: pharmacist_demo / demo12345")
        self.stdout.write("Insurance Officer: insurance_demo / demo12345")
        self.stdout.write(f"Imported doctors from insurance.ppu.edu: {imported_doctors}")
        self.stdout.write(f"Imported pharmacies from insurance.ppu.edu: {imported_pharmacies}")
        self.stdout.write(f"Fake employees added: {fake_employees}")
        self.stdout.write("Extra login 1: employee_01 / employee123")
        self.stdout.write("Extra login 2: employee_02 / employee123")
        self.stdout.write("Extra login 3: employee_03 / employee123")

    def _upsert_user(self, **defaults):
        username = defaults.pop("username")
        password = defaults.pop("password")
        defaults.setdefault("is_active", True)
        email = defaults.get("email", "")
        user = User.objects.filter(username=username).first()
        if user is None and email:
            user = User.objects.filter(email=email).first()

        if user is None:
            user = User(username=username)

        user.username = username
        for attr, value in defaults.items():
            setattr(user, attr, value)
        user.set_password(password)
        user.save()
        return user

    def _split_full_name(self, full_name):
        parts = [part for part in full_name.split() if part]
        if not parts:
            return "", ""
        if len(parts) == 1:
            return parts[0], ""
        return parts[0], " ".join(parts[1:])

    def _seed_imported_doctors(self):
        created = 0
        for index, doctor_data in enumerate(IMPORTED_DOCTORS, start=1):
            first_name, last_name = self._split_full_name(doctor_data["full_name"])
            user = self._upsert_user(
                username=f"ppu_doctor_{index:02d}",
                password="doctor123",
                role=UserRole.DOCTOR,
                first_name=first_name,
                last_name=last_name,
                email=f"ppu_doctor_{index:02d}@healthbridge.local",
                phone_number=doctor_data["phone_number"],
            )
            provider = self._upsert_provider(
                provider_name=doctor_data["clinic_name"],
                provider_type=ProviderType.DOCTOR,
                city="الخليل",
                address=doctor_data["clinic_address"],
                phone=doctor_data["phone_number"],
                google_maps_url="",
                working_hours="09:00 - 17:00",
            )
            Doctor.objects.update_or_create(
                license_number=f"DOC-PPU-{index:03d}",
                defaults={
                    "user": user,
                    "provider": provider,
                    "specialization": doctor_data["specialization"],
                    "clinic_name": doctor_data["clinic_name"],
                    "clinic_address": doctor_data["clinic_address"],
                    "consultation_price": 70 + (index % 4) * 10,
                    "contract_status": ContractStatus.ACTIVE,
                },
            )
            created += 1
        return created

    def _seed_imported_pharmacies(self):
        created = 0
        for index, pharmacy_data in enumerate(IMPORTED_PHARMACIES, start=1):
            provider = self._upsert_provider(
                provider_name=pharmacy_data["name"],
                provider_type=ProviderType.PHARMACY,
                city="الخليل",
                address=pharmacy_data["address"],
                phone=pharmacy_data["phone_number"],
                google_maps_url="",
                working_hours="08:00 - 22:00",
            )
            Pharmacy.objects.update_or_create(
                name=pharmacy_data["name"],
                defaults={
                    "license_number": f"PHA-PPU-{index:03d}",
                    "name": pharmacy_data["name"],
                    "provider": provider,
                    "address": pharmacy_data["address"],
                    "phone_number": pharmacy_data["phone_number"],
                    "is_active": True,
                },
            )
            created += 1
        return created

    def _seed_fake_employees(self):
        created = 0
        for index, full_name in enumerate(FAKE_EMPLOYEE_NAMES, start=1):
            first_name, last_name = self._split_full_name(full_name)
            user = self._upsert_user(
                username=f"employee_{index:02d}",
                password="employee123",
                role=UserRole.EMPLOYEE,
                first_name=first_name,
                last_name=last_name,
                email=f"employee_{index:02d}@healthbridge.local",
                phone_number=f"+97059920{index:04d}",
            )
            Employee.objects.update_or_create(
                user=user,
                defaults={
                    "national_id": f"90000000{index:03d}",
                    "university_id": f"PPU-EMP-{index:04d}",
                    "insurance_number": f"INS-EMP-{index:04d}",
                    "medical_record_number": f"MRN-EMP-{index:04d}",
                    "date_of_birth": f"{1982 + (index % 15)}-{((index % 12) + 1):02d}-{((index % 28) + 1):02d}",
                    "gender": "ذكر" if index % 2 else "أنثى",
                    "address": f"الخليل - موظف تجريبي رقم {index}",
                    "insurance_provider": "التأمين الصحي - جامعة بوليتكنك فلسطين",
                },
            )
            created += 1
        return created

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
