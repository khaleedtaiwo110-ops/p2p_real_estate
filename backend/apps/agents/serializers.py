from rest_framework import serializers
from .models import Agent, AgentAssignment

class AgentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Agent
        fields = '__all__'

class AgentAssignmentSerializer(serializers.ModelSerializer):
    agent_details = AgentSerializer(source='agent', read_only=True)

    class Meta:
        model = AgentAssignment
        fields = '__all__'