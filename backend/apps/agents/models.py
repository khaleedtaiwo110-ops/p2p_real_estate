from django.db import models
from apps.properties.models import Property

class Agent(models.Model):
    name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=20)
    city_covered = models.CharField(max_length=100)
    is_available = models.BooleanField(default=True)

    def __str__(self):
        return f"Agent {self.name} - {self.city_covered}"

class AgentAssignment(models.Model):
    property = models.OneToOneField(Property, on_delete=models.CASCADE, related_name='agent_assignment')
    agent = models.ForeignKey(Agent, on_delete=models.CASCADE, related_name='assignments')
    assigned_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.agent.name} assigned to {self.property.title}"