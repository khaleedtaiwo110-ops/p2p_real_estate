from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import HttpResponse
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)


def api_root_view(request):
    return HttpResponse("Welcome, the P2P Real Estate Backend API is live! 🚀")

urlpatterns = [
    path('', api_root_view),
    path('admin/', admin.site.urls),
    path('api/auth/', include('apps.users.urls')),
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/agents/', include('apps.agents.urls')),
    path('api/alerts/', include('apps.alerts.urls')),
    path('api/escrow/', include('apps.escrow.urls')),
    path('api/properties/', include('apps.properties.urls')),
    path('api/chat/', include('apps.chat.urls')),
    path('api/explore/', include('apps.properties.urls')),
    path('api/my-listings/', include('apps.properties.urls')),
    path('api/properties/', include('apps.properties.urls')),
] 

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)