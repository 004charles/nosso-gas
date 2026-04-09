from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from .serializers import RegisterSerializer, UserSerializer, MotoqueiroProfileSerializer
from .models import MotoqueiroProfile

User = get_user_model()

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = RegisterSerializer

class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_object(self):
        return self.request.user

class MotoqueiroProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = MotoqueiroProfileSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_object(self):
        return getattr(self.request.user, 'motoqueiro_profile', None)
