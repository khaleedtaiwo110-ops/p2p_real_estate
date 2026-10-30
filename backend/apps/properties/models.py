import uuid
from django.db import models  # type: ignore[import-not-found]
from django.conf import settings  # Import settings  # type: ignore[import-not-found]

class Property(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    STATUS_CHOICES = (
        ('PENDING', 'Pending Review (Locked)'),
        ('ACTIVE', 'Active (Unlocked & Public)'),
        ('REJECTED', 'Rejected'),
    )

    INTENT_CHOICES = (
        ('rent', 'For Rent'),
        ('own', 'For Sale'),
    )

    # Basic Info
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    price = models.DecimalField(max_digits=12, decimal_places=2)
    
    # Category / Subtype
    intent = models.CharField(max_length=20, choices=INTENT_CHOICES, default='rent')
    subtype = models.CharField(max_length=50, blank=True, null=True)
    tenant_preference = models.CharField(max_length=100, blank=True, null=True)
    
    # Location
    address = models.CharField(max_length=255, blank=True, null=True)
    city = models.CharField(max_length=100, blank=True, null=True)
    state = models.CharField(max_length=100, blank=True, null=True)

    # Status & Assignment
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    requires_agent = models.BooleanField(default=False)
    
    # Ownership: Use settings.AUTH_USER_MODEL
    landlord = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='properties',
        null=True, 
        blank=True
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.title} [{self.status}]"

    units_left = models.IntegerField(default=1)    


class PropertyImage(models.Model):
    property = models.ForeignKey(Property, on_delete=models.CASCADE, related_name='images')
    image = models.URLField(max_length=500)  # Expanded to support long cloud storage URLs
    uploaded_at = models.DateTimeField(auto_now_add=True)

class PropertyReview(models.Model):
    property = models.ForeignKey('Property', on_delete=models.CASCADE, related_name='reviews')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    rating = models.IntegerField(choices=[(i, i) for i in range(1, 6)])  # 1 to 5 stars
    comment = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('property', 'user')  # Prevents duplicate reviews by the same user
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.rating}★ by {self.user} for {self.property.title}"    