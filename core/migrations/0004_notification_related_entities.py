from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0003_employee_provider_refactor"),
    ]

    operations = [
        migrations.AddField(
            model_name="notification",
            name="related_entity_id",
            field=models.CharField(blank=True, max_length=100, verbose_name="Related entity ID"),
        ),
        migrations.AddField(
            model_name="notification",
            name="related_entity_type",
            field=models.CharField(blank=True, max_length=100, verbose_name="Related entity type"),
        ),
    ]
