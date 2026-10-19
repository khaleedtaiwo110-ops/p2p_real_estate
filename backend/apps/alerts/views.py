from rest_framework import viewsets
from .models import LocationAlert
from .serializers import LocationAlertSerializer

class LocationAlertViewSet(viewsets.ModelViewSet):
    queryset = LocationAlert.objects.all().order_by('-created_at')
    serializer_class = LocationAlertSerializer