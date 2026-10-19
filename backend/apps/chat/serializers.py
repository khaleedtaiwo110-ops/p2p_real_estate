from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Conversation, Message
from apps.properties.serializers import PropertySerializer # optional if you want nested property details

User = get_user_model()

class UserSimpleSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'email']

class MessageSerializer(serializers.ModelSerializer):
    sender_details = UserSimpleSerializer(source='sender', read_only=True)

    class Meta:
        model = Message
        fields = ['id', 'conversation', 'sender', 'sender_details', 'text', 'timestamp', 'is_read']
        read_only_fields = ['sender', 'conversation', 'timestamp']

class ConversationSerializer(serializers.ModelSerializer):
    buyer_details = UserSimpleSerializer(source='buyer', read_only=True)
    landlord_details = UserSimpleSerializer(source='landlord', read_only=True)
    messages = MessageSerializer(many=True, read_only=True)

    class Meta:
        model = Conversation
        fields = ['id', 'property', 'buyer', 'buyer_details', 'landlord', 'landlord_details', 'messages', 'created_at', 'updated_at']
        read_only_fields = ['buyer', 'created_at', 'updated_at']