from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.authentication import JWTAuthentication

from .models import Property, PropertyReview
from .serializers import PropertySerializer, PropertyReviewSerializer
from apps.chat.models import Conversation
from apps.chat.serializers import ConversationSerializer


# 1. Public Explore Feed - CBV (generics.ListAPIView)
class ExplorePropertiesView(generics.ListAPIView):
    """
    Public feed: displays ACTIVE properties.
    Supports simple title search via ?search= keyword.
    """
    serializer_class = PropertySerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        queryset = Property.objects.filter(status='ACTIVE')
        search = self.request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(title__icontains=search)
        return queryset


# 2. Landlord Dashboard - CBV (generics.ListCreateAPIView)
class LandlordPropertiesView(generics.ListCreateAPIView):
    serializer_class = PropertySerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Only return properties belonging to the logged-in user
        return Property.objects.filter(landlord=self.request.user).order_by('-created_at')

    def get_serializer_context(self):
            context = super().get_serializer_context()
            context['request'] = self.request
            return context

    def perform_create(self, serializer):
        # Automatically bind the property to the authenticated user and set to PENDING
        serializer.save(
            landlord=self.request.user,
            status='PENDING'
        )    

# 3. Admin Approval View - CBV (APIView)
class ApprovePropertyView(APIView):
    """
    Admin-only endpoint to approve and activate a pending property listing.
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAdminUser]

    def patch(self, request, pk):
        try:
            prop = Property.objects.get(pk=pk)
            prop.status = 'ACTIVE'
            prop.save()
            return Response({'message': 'Property approved and unlocked!'}, status=status.HTTP_200_OK)
        except Property.DoesNotExist:
            return Response({'error': 'Property not found'}, status=status.HTTP_404_NOT_FOUND)


# 4. Main Property Listing API - CBV (generics.ListCreateAPIView)
class PropertyListAPIView(generics.ListCreateAPIView):
    """
    Main listing endpoint supporting filters, search, ordering, 
    and custom status=ALL logic.
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.AllowAny]
    
    queryset = Property.objects.all()
    serializer_class = PropertySerializer
    
    filter_backends = [
        filters.SearchFilter,
        filters.OrderingFilter,
    ]
    
    search_fields = [
        'title',
        'description',
        'address',
        'city',
        'state',
    ]
    
    ordering_fields = ['price', 'created_at']
    ordering = ['-created_at']

    def get_queryset(self):
        queryset = Property.objects.all()

        for field in ('intent', 'subtype', 'requires_agent'):
            value = self.request.query_params.get(field)
            if value is not None:
                queryset = queryset.filter(**{field: value})

        status_param = self.request.query_params.get('status', None)

        if status_param:
            status_param_upper = status_param.upper()
            if status_param_upper != 'ALL':
                queryset = queryset.filter(status=status_param_upper)
        else:
            # Default for unauthenticated users / public feed
            if not (self.request.user and getattr(self.request.user, 'is_staff', False)):
                queryset = queryset.filter(status='ACTIVE')

        return queryset

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context    

    def perform_create(self, serializer):
        landlord_user = self.request.user if self.request.user.is_authenticated else None

        serializer.save(
            landlord=landlord_user,
            status='PENDING'
        )


# 5. Property Reviews
class PropertyReviewListCreateView(generics.ListCreateAPIView):
    serializer_class = PropertyReviewSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        property_id = self.kwargs['property_id']
        return PropertyReview.objects.filter(property_id=property_id)

    def perform_create(self, serializer):
        property_id = self.kwargs['property_id']
        serializer.save(user=self.request.user, property_id=property_id)       


# 6. Functional View - Update Units Left
@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_units_left(request, pk):
    try:
        property_obj = Property.objects.get(pk=pk, landlord=request.user)
        units = request.data.get('units_left')
        if units is not None:
            property_obj.units_left = int(units)
            property_obj.save()
            return Response({'message': 'Units updated successfully', 'units_left': property_obj.units_left}, status=status.HTTP_200_OK)
        return Response({'error': 'Invalid payload'}, status=status.HTTP_400_BAD_REQUEST)
    except Property.DoesNotExist:
        return Response({'error': 'Property not found or unauthorized'}, status=status.HTTP_404_NOT_FOUND)


# 7. CBV - Update Units Left API
class PropertyUpdateUnitsAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def patch(self, request, pk):
        property_obj = get_object_or_404(Property, pk=pk)
        units_left = request.data.get('units_left')

        if units_left is None:
            return Response({'error': 'units_left field is required.'}, status=status.HTTP_400_BAD_REQUEST)

        property_obj.units_left = units_left
        property_obj.save(update_fields=['units_left'])
        
        return Response({'status': 'success', 'units_left': property_obj.units_left}, status=status.HTTP_200_OK)

class InitiateOrGetChatView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        property_id = request.data.get('property_id')
        landlord_id = request.data.get('landlord_id')
        buyer = request.user

        # 1. Validate required fields exist in payload
        if not property_id or not landlord_id:
            return Response(
                {"error": "Both 'property_id' and 'landlord_id' are required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 2. Prevent self-chatting
        if str(buyer.id) == str(landlord_id):
            return Response(
                {"error": "You cannot start a chat with yourself."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 3. Fetch or create conversation thread safely
        try:
            conversation, created = Conversation.objects.get_or_create(
                property_id=property_id,
                buyer=buyer,
                landlord_id=landlord_id
            )
        except Exception as e:
            return Response(
                {"error": f"Failed to resolve conversation: {str(e)}"},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = ConversationSerializer(conversation, context={'request': request})
        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK
        )