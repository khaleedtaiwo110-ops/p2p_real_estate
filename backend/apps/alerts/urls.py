from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import LocationAlertViewSet

router = DefaultRouter()
router.register(r'location-alerts', LocationAlertViewSet, basename='location-alert')

urlpatterns = [
    path('', include(router.urls)),
]