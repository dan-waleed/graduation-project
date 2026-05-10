from .base import *  # noqa: F401,F403


DEBUG = True
DEV_LAN_HOST = os.environ.get("DJANGO_DEV_LAN_HOST", "").strip()
USE_POSTGRES_IN_DEV = os.environ.get("DJANGO_USE_POSTGRES", "").strip().lower() in {
    "1",
    "true",
    "yes",
}

ALLOWED_HOSTS = [
    "127.0.0.1",
    "localhost",
    "0.0.0.0",
    "testserver",
]
if DEV_LAN_HOST:
    ALLOWED_HOSTS.append(DEV_LAN_HOST)

CORS_ALLOWED_ORIGINS = [
    "http://127.0.0.1:8000",
    "http://localhost:8000",
    "http://127.0.0.1",
    "http://localhost",
]
if DEV_LAN_HOST:
    CORS_ALLOWED_ORIGINS.extend(
        [
            f"http://{DEV_LAN_HOST}:8000",
            f"http://{DEV_LAN_HOST}",
        ]
    )

CORS_ALLOWED_ORIGIN_REGEXES = [
    r"^http://localhost(:\d+)?$",
    r"^http://127\.0\.0\.1(:\d+)?$",
]
if DEV_LAN_HOST:
    escaped_host = DEV_LAN_HOST.replace(".", r"\.")
    CORS_ALLOWED_ORIGIN_REGEXES.append(rf"^http://{escaped_host}(:\d+)?$")

if USE_POSTGRES_IN_DEV:
    DATABASES["default"]["NAME"] = os.environ.get("POSTGRES_DB", "healthbridge_dev")
    DATABASES["default"]["USER"] = os.environ.get("POSTGRES_USER", "postgres")
    DATABASES["default"]["PASSWORD"] = os.environ.get("POSTGRES_PASSWORD", "1234")
    DATABASES["default"]["HOST"] = os.environ.get("POSTGRES_HOST", "127.0.0.1")
    DATABASES["default"]["PORT"] = os.environ.get("POSTGRES_PORT", "5432")
    DATABASES["default"]["OPTIONS"] = {"sslmode": "disable"}
else:
    DATABASES["default"] = {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
