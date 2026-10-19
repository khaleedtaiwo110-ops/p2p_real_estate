from django.db import models
from apps.properties.models import Property

class EscrowTransaction(models.Model):
    STATUS_CHOICES = (
        ('HELD', 'Funds Held in Escrow'),
        ('COMPLETED', 'Funds Released to Landlord'),
        ('DISPUTED', 'Dispute Initiated'),
        ('REFUNDED', 'Funds Refunded to Buyer'),
    )

    property = models.ForeignKey(Property, on_delete=models.CASCADE, related_name='escrow_transactions')
    buyer_email = models.EmailField()
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='HELD')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=False, auto_now_add=False, null=True, blank=True)

    def __str__(self):
        return f"Escrow #{self.id} - {self.property.title} ({self.status})"