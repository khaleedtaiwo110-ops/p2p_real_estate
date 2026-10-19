from rest_framework import status, generics, permissions
from rest_framework.response import Response
from django.contrib.auth import get_user_model

User = get_user_model()

class RegisterView(generics.CreateAPIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        email = request.data.get('email')
        username = request.data.get('username', email)
        password = request.data.get('password')
        full_name = request.data.get('full_name', '')
        role = request.data.get('role', 'tenant')

        if not email or not password:
            return Response({'detail': 'Email and password are required.'}, status=status.HTTP_400_BAD_REQUEST)

        if User.objects.filter(username=username).exists() or User.objects.filter(email=email).exists():
            return Response({'detail': 'A user with this email/username already exists.'}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            first_name=full_name
        )
        # Store custom fields like role if implemented on your custom User model

        return Response({'message': 'User registered successfully!'}, status=status.HTTP_201_CREATED)