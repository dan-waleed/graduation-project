from django.urls import include, path

urlpatterns = [
    path("", include("core.api.urls.auth")),
    path("", include("core.api.urls.users")),
    path("", include("core.api.urls.providers")),
    path("", include("core.api.urls.catalog")),
    path("", include("core.api.urls.workflow")),
    path("", include("core.api.urls.system")),
]

