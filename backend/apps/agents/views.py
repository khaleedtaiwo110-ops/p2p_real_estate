from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Agent, AgentAssignment
from .serializers import AgentSerializer, AgentAssignmentSerializer
from apps.properties.models import Property

class AgentViewSet(viewsets.ModelViewSet):
    queryset = Agent.objects.all()
    serializer_class = AgentSerializer

    @action(detail=False, methods=['post'])
    def auto_assign(self, request):
        property_id = request.data.get('property_id')
        try:
            property_obj = Property.objects.get(id=property_id)
        except Property.DoesNotExist:
            return Response({'error': 'Property not found'}, status=status.HTTP_404_NOT_FOUND)

        # Find an available agent in the property's city
        agent = Agent.objects.filter(city_covered__iexact=property_obj.city, is_available=True).first()

        if not agent:
            # Fallback to any available agent
            agent = Agent.objects.filter(is_available=True).first()

        if not agent:
            return Response({'error': 'No agents available at this moment'}, status=status.HTTP_404_NOT_FOUND)

        assignment, created = AgentAssignment.objects.get_or_create(property=property_obj, defaults={'agent': agent})
        serializer = AgentAssignmentSerializer(assignment)
        return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)