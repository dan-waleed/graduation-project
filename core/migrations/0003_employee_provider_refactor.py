from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0002_patient_and_dependent_updates"),
    ]

    operations = [
        migrations.RenameModel(
            old_name="Patient",
            new_name="Employee",
        ),
        migrations.AlterModelOptions(
            name="employee",
            options={
                "ordering": ["medical_record_number"],
                "verbose_name": "University employee",
                "verbose_name_plural": "University employees",
            },
        ),
        migrations.AlterField(
            model_name="employee",
            name="user",
            field=models.OneToOneField(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="employee_profile",
                to=settings.AUTH_USER_MODEL,
                verbose_name="User",
            ),
        ),
        migrations.RenameField(
            model_name="dependent",
            old_name="patient",
            new_name="employee",
        ),
        migrations.AlterModelOptions(
            name="dependent",
            options={
                "ordering": ["full_name"],
                "verbose_name": "Beneficiary",
                "verbose_name_plural": "Beneficiaries",
            },
        ),
        migrations.AlterField(
            model_name="dependent",
            name="employee",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="beneficiaries",
                to="core.employee",
                verbose_name="Employee",
            ),
        ),
        migrations.AlterField(
            model_name="dependent",
            name="relation",
            field=models.CharField(
                choices=[("son", "ابن"), ("daughter", "ابنة"), ("wife", "زوجة"), ("husband", "زوج")],
                max_length=20,
                verbose_name="Relation",
            ),
        ),
        migrations.RenameField(
            model_name="prescription",
            old_name="patient",
            new_name="employee",
        ),
        migrations.RenameField(
            model_name="prescription",
            old_name="dependent",
            new_name="beneficiary",
        ),
        migrations.AlterField(
            model_name="prescription",
            name="employee",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="medical_orders",
                to="core.employee",
                verbose_name="Employee",
            ),
        ),
        migrations.AlterField(
            model_name="prescription",
            name="beneficiary",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="medical_orders",
                to="core.dependent",
                verbose_name="Beneficiary",
            ),
        ),
        migrations.AlterField(
            model_name="user",
            name="role",
            field=models.CharField(
                choices=[
                    ("Admin", "Admin"),
                    ("Doctor", "Doctor"),
                    ("Employee", "Employee"),
                    ("Pharmacist", "Pharmacist"),
                    ("Laboratory", "Laboratory"),
                    ("ImagingCenter", "Medical Imaging Center"),
                    ("MedicalCenter", "Medical Center"),
                    ("InsuranceOfficer", "Insurance Officer"),
                ],
                max_length=32,
                verbose_name="Role",
            ),
        ),
        migrations.CreateModel(
            name="Provider",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True, verbose_name="Created at")),
                ("updated_at", models.DateTimeField(auto_now=True, verbose_name="Updated at")),
                ("provider_name", models.CharField(max_length=255, verbose_name="Provider name")),
                ("provider_type", models.CharField(choices=[("Doctor", "Doctor"), ("Pharmacy", "Pharmacy"), ("Lab", "Laboratory"), ("ImagingCenter", "Medical Imaging Center"), ("MedicalCenter", "Medical Center")], max_length=30, verbose_name="Provider type")),
                ("city", models.CharField(blank=True, max_length=100, verbose_name="City")),
                ("address", models.TextField(blank=True, verbose_name="Address")),
                ("phone", models.CharField(blank=True, max_length=20, verbose_name="Phone")),
                ("latitude", models.DecimalField(blank=True, decimal_places=7, max_digits=10, null=True, verbose_name="Latitude")),
                ("longitude", models.DecimalField(blank=True, decimal_places=7, max_digits=10, null=True, verbose_name="Longitude")),
                ("google_maps_url", models.URLField(blank=True, verbose_name="Google maps URL")),
                ("working_hours", models.CharField(blank=True, max_length=255, verbose_name="Working hours")),
                ("contract_status", models.CharField(choices=[("active", "Active"), ("inactive", "Inactive")], default="active", max_length=10, verbose_name="Contract status")),
            ],
            options={
                "verbose_name": "Provider",
                "verbose_name_plural": "Providers",
                "ordering": ["provider_type", "provider_name"],
            },
        ),
        migrations.CreateModel(
            name="MedicalService",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True, verbose_name="Created at")),
                ("updated_at", models.DateTimeField(auto_now=True, verbose_name="Updated at")),
                ("service_name", models.CharField(max_length=255, verbose_name="Service name")),
                ("service_type", models.CharField(choices=[("Medication", "Medication"), ("LabTest", "Lab Test"), ("Imaging", "Imaging"), ("Procedure", "Procedure"), ("Consultation", "Consultation")], max_length=20, verbose_name="Service type")),
                ("default_price", models.DecimalField(decimal_places=2, default=0, max_digits=10, verbose_name="Default price")),
                ("requires_insurance_approval", models.BooleanField(default=False, verbose_name="Requires insurance approval")),
                ("coverage_percentage", models.DecimalField(decimal_places=2, default=0, max_digits=5, verbose_name="Coverage percentage")),
                ("employee_share", models.DecimalField(decimal_places=2, default=0, max_digits=10, verbose_name="Employee share")),
                ("description", models.TextField(blank=True, verbose_name="Description")),
            ],
            options={
                "verbose_name": "Medical service",
                "verbose_name_plural": "Medical services",
                "ordering": ["service_type", "service_name"],
            },
        ),
        migrations.CreateModel(
            name="Laboratory",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True, verbose_name="Created at")),
                ("updated_at", models.DateTimeField(auto_now=True, verbose_name="Updated at")),
                ("license_number", models.CharField(max_length=50, unique=True, verbose_name="License number")),
                ("provider", models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name="laboratory_profile", to="core.provider", verbose_name="Provider")),
                ("user", models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name="laboratory_profile", to=settings.AUTH_USER_MODEL, verbose_name="User")),
            ],
            options={
                "verbose_name": "Laboratory",
                "verbose_name_plural": "Laboratories",
                "ordering": ["license_number"],
            },
        ),
        migrations.CreateModel(
            name="MedicalCenter",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True, verbose_name="Created at")),
                ("updated_at", models.DateTimeField(auto_now=True, verbose_name="Updated at")),
                ("license_number", models.CharField(max_length=50, unique=True, verbose_name="License number")),
                ("provider", models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name="medical_center_profile", to="core.provider", verbose_name="Provider")),
                ("user", models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name="medical_center_profile", to=settings.AUTH_USER_MODEL, verbose_name="User")),
            ],
            options={
                "verbose_name": "Medical center",
                "verbose_name_plural": "Medical centers",
                "ordering": ["license_number"],
            },
        ),
        migrations.CreateModel(
            name="MedicalImagingCenter",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True, verbose_name="Created at")),
                ("updated_at", models.DateTimeField(auto_now=True, verbose_name="Updated at")),
                ("license_number", models.CharField(max_length=50, unique=True, verbose_name="License number")),
                ("provider", models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name="imaging_center_profile", to="core.provider", verbose_name="Provider")),
                ("user", models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name="imaging_center_profile", to=settings.AUTH_USER_MODEL, verbose_name="User")),
            ],
            options={
                "verbose_name": "Medical imaging center",
                "verbose_name_plural": "Medical imaging centers",
                "ordering": ["license_number"],
            },
        ),
        migrations.CreateModel(
            name="ProviderServicePrice",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True, verbose_name="Created at")),
                ("updated_at", models.DateTimeField(auto_now=True, verbose_name="Updated at")),
                ("price", models.DecimalField(decimal_places=2, max_digits=10, verbose_name="Price")),
                ("coverage_percentage", models.DecimalField(decimal_places=2, default=0, max_digits=5, verbose_name="Coverage percentage")),
                ("covered_amount_limit", models.DecimalField(decimal_places=2, default=0, max_digits=10, verbose_name="Covered amount limit")),
                ("employee_share", models.DecimalField(decimal_places=2, default=0, max_digits=10, verbose_name="Employee share")),
                ("is_available", models.BooleanField(default=True, verbose_name="Is available")),
                ("requires_pre_approval", models.BooleanField(default=False, verbose_name="Requires pre approval")),
                ("provider", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="service_prices", to="core.provider", verbose_name="Provider")),
                ("service", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="provider_prices", to="core.medicalservice", verbose_name="Medical service")),
            ],
            options={
                "verbose_name": "Provider service price",
                "verbose_name_plural": "Provider service prices",
                "ordering": ["provider", "service"],
                "unique_together": {("provider", "service")},
            },
        ),
        migrations.AddField(
            model_name="doctor",
            name="clinic_address",
            field=models.TextField(blank=True, verbose_name="Clinic address"),
        ),
        migrations.AddField(
            model_name="doctor",
            name="consultation_price",
            field=models.DecimalField(decimal_places=2, default=0, max_digits=10, verbose_name="Consultation price"),
        ),
        migrations.AddField(
            model_name="doctor",
            name="contract_status",
            field=models.CharField(choices=[("active", "Active"), ("inactive", "Inactive")], default="active", max_length=10, verbose_name="Contract status"),
        ),
        migrations.AddField(
            model_name="doctor",
            name="provider",
            field=models.OneToOneField(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="doctor_profile", to="core.provider", verbose_name="Provider"),
        ),
        migrations.AddField(
            model_name="pharmacy",
            name="provider",
            field=models.OneToOneField(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="pharmacy_profile", to="core.provider", verbose_name="Provider"),
        ),
        migrations.AddField(
            model_name="prescription",
            name="covered_amount",
            field=models.DecimalField(decimal_places=2, default=0, max_digits=10, verbose_name="Covered amount"),
        ),
        migrations.AddField(
            model_name="prescription",
            name="employee_share",
            field=models.DecimalField(decimal_places=2, default=0, max_digits=10, verbose_name="Employee share"),
        ),
        migrations.AddField(
            model_name="prescription",
            name="final_price",
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=10, null=True, verbose_name="Final price"),
        ),
        migrations.AddField(
            model_name="prescription",
            name="performed_at",
            field=models.DateTimeField(blank=True, null=True, verbose_name="Performed at"),
        ),
        migrations.AddField(
            model_name="prescription",
            name="coverage_percentage",
            field=models.DecimalField(decimal_places=2, default=0, max_digits=5, verbose_name="Coverage percentage"),
        ),
        migrations.AddField(
            model_name="prescription",
            name="provider",
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="medical_orders", to="core.provider", verbose_name="Provider"),
        ),
        migrations.AddField(
            model_name="prescription",
            name="provider_notes",
            field=models.TextField(blank=True, verbose_name="Provider notes"),
        ),
        migrations.AddField(
            model_name="prescription",
            name="report_attachment_url",
            field=models.URLField(blank=True, verbose_name="Report attachment URL"),
        ),
        migrations.AddField(
            model_name="prescription",
            name="requires_insurance_approval",
            field=models.BooleanField(default=False, verbose_name="Requires insurance approval"),
        ),
        migrations.AddField(
            model_name="prescription",
            name="service",
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="medical_orders", to="core.medicalservice", verbose_name="Medical service"),
        ),
        migrations.AddField(
            model_name="prescription",
            name="service_type",
            field=models.CharField(choices=[("Medication", "Medication"), ("LabTest", "Lab Test"), ("Imaging", "Imaging"), ("Procedure", "Procedure"), ("Consultation", "Consultation")], default="Medication", max_length=20, verbose_name="Service type"),
        ),
        migrations.AlterField(
            model_name="prescription",
            name="status",
            field=models.CharField(
                choices=[
                    ("Draft", "Draft"),
                    ("Sent", "Sent"),
                    ("PendingEmployeeSelection", "Pending Employee Selection"),
                    ("PendingInsuranceApproval", "Pending Insurance Approval"),
                    ("Approved", "Approved"),
                    ("Rejected", "Rejected"),
                    ("Dispensed", "Dispensed"),
                    ("Performed", "Performed"),
                    ("Cancelled", "Cancelled"),
                    ("Expired", "Expired"),
                ],
                default="Draft",
                max_length=32,
                verbose_name="Status",
            ),
        ),
    ]
