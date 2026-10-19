from rest_framework import serializers
from .models import LocationAlert

class LocationAlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = LocationAlert
        fields = '__all__'