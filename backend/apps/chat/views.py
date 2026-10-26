from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.authentication import JWTAuthentication
from django.contrib.auth import get_user_model
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import Conversation, Message
from .serializers import ConversationSerializer, MessageSerializer
from apps.properties.models import Property

User = get_user_model()

class ConversationListView(generics.ListAPIView):
    serializer_class = ConversationSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        queryset = Conversation.objects.filter(Q(buyer=user) | Q(landlord=user))
        
        property_id = self.request.query_params.get('property_id')
        if property_id:
            queryset = queryset.filter(property_id=property_id)
            
        return queryset.order_by('-updated_at')


class InitiateOrGetChatView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        # Support both snake_case, camelCase, and nested structures
        property_id = (
            request.data.get('property_id') or 
            request.data.get('propertyId') or 
            request.data.get('property')
        )
        
        landlord_id = (
            request.data.get('landlord_id') or 
            request.data.get('landlordId') or 
            request.data.get('landlord')
        )

        buyer = request.user

        # If property is an object/dict containing an id
        if isinstance(property_id, dict):
            property_id = property_id.get('id')

        # If landlord is an object/dict containing an id
        if isinstance(landlord_id, dict):
            landlord_id = landlord_id.get('id')

        if not property_id or not landlord_id:
            return Response(
                {"error": f"Both 'property_id' and 'landlord_id' are required. Received data: {request.data}"},
                status=status.HTTP_400_BAD_REQUEST
            )
        

class MessageListCreateView(generics.ListCreateAPIView):
    serializer_class = MessageSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        conversation_id = self.kwargs['conversation_id']
        # Ensure the user is either the buyer or landlord of this conversation
        user = self.request.user
        conversation = get_object_or_404(Conversation, id=conversation_id)
        
        if conversation.buyer != user and conversation.landlord != user:
            return Message.objects.none()
            
        return Message.objects.filter(conversation_id=conversation_id).order_by('timestamp')

    def perform_create(self, serializer):
        conversation = get_object_or_404(Conversation, id=self.kwargs['conversation_id'])
        serializer.save(sender=self.request.user, conversation=conversation)
        
        # Force updated_at timestamp change on parent conversation
        conversation.updated_at = timezone.now()
        conversation.save(update_fields=['updated_at'])      