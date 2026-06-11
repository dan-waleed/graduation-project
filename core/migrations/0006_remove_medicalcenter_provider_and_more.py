from django.db import migrations, models


def purge_legacy_provider_data(apps, schema_editor):
    User = apps.get_model("core", "User")
    Provider = apps.get_model("core", "Provider")
    MedicalService = apps.get_model("core", "MedicalService")
    Prescription = apps.get_model("core", "Prescription")
    Laboratory = apps.get_model("core", "Laboratory")
    MedicalCenter = apps.get_model("core", "MedicalCenter")
    MedicalImagingCenter = apps.get_model("core", "MedicalImagingCenter")

    legacy_roles = ["Laboratory", "ImagingCenter", "MedicalCenter"]
    legacy_provider_types = ["Lab", "ImagingCenter", "MedicalCenter"]
    legacy_service_types = ["LabTest", "Imaging", "Procedure"]

    Prescription.objects.filter(service_type__in=legacy_service_types).delete()
    MedicalService.objects.filter(service_type__in=legacy_service_types).delete()
    Laboratory.objects.all().delete()
    MedicalCenter.objects.all().delete()
    MedicalImagingCenter.objects.all().delete()
    Provider.objects.filter(provider_type__in=legacy_provider_types).delete()
    User.objects.filter(role__in=legacy_roles).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0005_systemsettings'),
    ]

    operations = [
        migrations.RunPython(purge_legacy_provider_data, migrations.RunPython.noop),
        migrations.RemoveField(
            model_name='medicalcenter',
            name='provider',
        ),
        migrations.RemoveField(
            model_name='medicalcenter',
            name='user',
        ),
        migrations.RemoveField(
            model_name='medicalimagingcenter',
            name='provider',
        ),
        migrations.RemoveField(
            model_name='medicalimagingcenter',
            name='user',
        ),
        migrations.AlterField(
            model_name='medicalservice',
            name='service_type',
            field=models.CharField(choices=[('Medication', 'Medication'), ('Consultation', 'Consultation')], max_length=20, verbose_name='Service type'),
        ),
        migrations.AlterField(
            model_name='prescription',
            name='service_type',
            field=models.CharField(choices=[('Medication', 'Medication'), ('Consultation', 'Consultation')], default='Medication', max_length=20, verbose_name='Service type'),
        ),
        migrations.AlterField(
            model_name='provider',
            name='provider_type',
            field=models.CharField(choices=[('Doctor', 'Doctor'), ('Pharmacy', 'Pharmacy')], max_length=30, verbose_name='Provider type'),
        ),
        migrations.AlterField(
            model_name='user',
            name='role',
            field=models.CharField(choices=[('Admin', 'Admin'), ('Doctor', 'Doctor'), ('Employee', 'Employee'), ('Pharmacist', 'Pharmacist'), ('InsuranceOfficer', 'Insurance Officer')], max_length=32, verbose_name='Role'),
        ),
        migrations.DeleteModel(
            name='Laboratory',
        ),
        migrations.DeleteModel(
            name='MedicalCenter',
        ),
        migrations.DeleteModel(
            name='MedicalImagingCenter',
        ),
    ]
