import os

from .base import *  # noqa: F401,F403


DEBUG = False
ALLOWED_HOSTS = os.environ.get("DJANGO_ALLOWED_HOSTS", "").split(",") if os.environ.get("DJANGO_ALLOWED_HOSTS") else ["localhost"]

SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")

DATABASES["default"]["NAME"] = os.environ["POSTGRES_DB"]
DATABASES["default"]["USER"] = os.environ["POSTGRES_USER"]
DATABASES["default"]["PASSWORD"] = os.environ["POSTGRES_PASSWORD"]
DATABASES["default"]["HOST"] = os.environ.get("POSTGRES_HOST", "127.0.0.1")
DATABASES["default"]["PORT"] = os.environ.get("POSTGRES_PORT", "5432")
DATABASES["default"]["OPTIONS"] = {
    "sslmode": os.environ.get("POSTGRES_SSLMODE", "require"),
}
