from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EscrowTransactionViewSet

router = DefaultRouter()
router.register(r'transactions', EscrowTransactionViewSet, basename='escrow-transaction')

urlpatterns = [
    path('', include(router.urls)),
]