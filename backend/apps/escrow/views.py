from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import EscrowTransaction
from .serializers import EscrowTransactionSerializer

class EscrowTransactionViewSet(viewsets.ModelViewSet):
    queryset = EscrowTransaction.objects.all()
    serializer_class = EscrowTransactionSerializer

    @action(detail=True, methods=['post'])
    def confirm_satisfaction(self, request, pk=None):
        """Client confirms satisfaction to release funds to landlord."""
        transaction = self.get_object()
        transaction.status = 'COMPLETED'
        transaction.save()
        return Response({'status': 'Funds released to landlord'}, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def dispute(self, request, pk=None):
        """Client flags non-satisfaction for refund review."""
        transaction = self.get_object()
        transaction.status = 'DISPUTED'
        transaction.save()
        return Response({'status': 'Dispute initiated. Pending admin review'}, status=status.HTTP_200_OK)