from django.db import models

class LocationAlert(models.Model):
    user_email = models.EmailField()
    desired_city = models.CharField(max_length=100)
    max_price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Alert for {self.user_email} in {self.desired_city}"