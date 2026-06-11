from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0004_notification_related_entities"),
    ]

    operations = [
        migrations.CreateModel(
            name="SystemSettings",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("system_name", models.CharField(default="هيلث بريدج", max_length=255, verbose_name="System name")),
                ("organization_name", models.CharField(default="جامعة بوليتكنك فلسطين", max_length=255, verbose_name="Organization name")),
                (
                    "short_description",
                    models.TextField(
                        blank=True,
                        default="نظام إلكتروني لإدارة الوصفات الطبية والتأمين والصرف",
                        verbose_name="Short description",
                    ),
                ),
                ("notifications_enabled", models.BooleanField(default=True, verbose_name="Notifications enabled")),
                ("insurance_workflow_enabled", models.BooleanField(default=True, verbose_name="Insurance workflow enabled")),
                ("pharmacist_notes_required", models.BooleanField(default=False, verbose_name="Pharmacist notes required")),
                ("interface_language", models.CharField(default="العربية", max_length=32, verbose_name="Interface language")),
                ("session_timeout_minutes", models.PositiveIntegerField(default=30, verbose_name="Session timeout in minutes")),
                ("admin_notes", models.TextField(blank=True, default="", verbose_name="Administrative notes")),
                ("updated_at", models.DateTimeField(auto_now=True, verbose_name="Updated at")),
            ],
            options={
                "verbose_name": "System settings",
                "verbose_name_plural": "System settings",
            },
        ),
    ]
