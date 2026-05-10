from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="patient",
            name="gender",
            field=models.CharField(blank=True, max_length=20, verbose_name="Gender"),
        ),
        migrations.AddField(
            model_name="patient",
            name="insurance_number",
            field=models.CharField(blank=True, default="", max_length=50, verbose_name="Insurance number"),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name="patient",
            name="national_id",
            field=models.CharField(blank=True, default="", max_length=32, verbose_name="National ID"),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name="patient",
            name="university_id",
            field=models.CharField(blank=True, default="", max_length=50, verbose_name="University ID"),
            preserve_default=False,
        ),
        migrations.RenameField(
            model_name="dependent",
            old_name="relationship",
            new_name="relation",
        ),
        migrations.AlterField(
            model_name="dependent",
            name="relation",
            field=models.CharField(
                choices=[("son", "ابن"), ("daughter", "ابنة"), ("wife", "زوجة")],
                max_length=20,
                verbose_name="Relation",
            ),
        ),
        migrations.AddField(
            model_name="dependent",
            name="is_active",
            field=models.BooleanField(default=True, verbose_name="Is active"),
        ),
        migrations.AddField(
            model_name="dependent",
            name="national_id",
            field=models.CharField(blank=True, default="", max_length=32, verbose_name="National ID"),
            preserve_default=False,
        ),
    ]
