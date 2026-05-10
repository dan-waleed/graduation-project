from django.conf import settings
from django.db.models.signals import post_save
from django.dispatch import receiver
from rest_framework.authtoken.models import Token


@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_auth_token(sender, instance, created, **kwargs):
    """Create a token for new users so API login/testing is smoother in development."""

    if created:
        Token.objects.get_or_create(user=instance)
