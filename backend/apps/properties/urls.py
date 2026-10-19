from django.urls import path  # pyright: ignore[reportMissingImports]
from .views import (
    ExplorePropertiesView,
    LandlordPropertiesView,
    ApprovePropertyView,
    PropertyListAPIView,
    PropertyReviewListCreateView,
    PropertyUpdateUnitsAPIView,
)

urlpatterns = [
    # Specific route paths
    path('explore/', ExplorePropertiesView.as_view(), name='explore-properties'),
    path('my-listings/', LandlordPropertiesView.as_view(), name='landlord-properties'),
    path('<int:pk>/approve/', ApprovePropertyView.as_view(), name='approve-property'),
    
    # Updated path: Removed leading '/' and added '<int:pk>' parameter
    path('<int:pk>/update-units/', PropertyUpdateUnitsAPIView.as_view(), name='update-units'),
    
    path('<int:pk>/reviews/', PropertyReviewListCreateView.as_view(), name='property-reviews'),
    path('my-properties/', LandlordPropertiesView.as_view(), name='landlord-properties'),
    
    path('', PropertyListAPIView.as_view(), name='property-list'),
]
