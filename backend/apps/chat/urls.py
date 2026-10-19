from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ConversationListView,
    InitiateOrGetChatView,
    MessageListCreateView,
)
from apps.escrow.views import EscrowTransactionViewSet

router = DefaultRouter()
router.register(r'transactions', EscrowTransactionViewSet, basename='escrow-transaction')

urlpatterns = [
    path('conversations/', ConversationListView.as_view(), name='conversation-list'),
    path('initiate/', InitiateOrGetChatView.as_view(), name='initiate-chat'),
    path('conversations/<int:conversation_id>/messages/', MessageListCreateView.as_view(), name='message-list-create'),
]
