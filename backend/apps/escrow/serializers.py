from rest_framework import serializers
from .models import EscrowTransaction

class EscrowTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = EscrowTransaction
        fields = '__all__'