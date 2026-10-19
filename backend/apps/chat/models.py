from django.db import models
from django.contrib.auth import get_user_model
from apps.properties.models import Property  # adjust import path if needed

User = get_user_model()

class Conversation(models.Model):
    property = models.ForeignKey(Property, on_delete=models.CASCADE, related_name='conversations')
    buyer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='buyer_conversations')
    landlord = models.ForeignKey(User, on_delete=models.CASCADE, related_name='landlord_conversations')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('property', 'buyer', 'landlord')

    def __str__(self):
        return f"Chat for {self.property.title} between {self.buyer.username} & {self.landlord.username}"

class Message(models.Model):
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE)
    text = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    class Meta:
        ordering = ['timestamp']

    def __str__(self):
        return f"{self.sender.username}: {self.text[:20]}"