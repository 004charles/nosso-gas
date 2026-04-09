from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import MotoqueiroProfile

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'phone', 'role')

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('phone', 'username', 'password', 'role')

    def create(self, validated_data):
        user = User.objects.create_user(
            phone=validated_data['phone'],
            username=validated_data['username'],
            password=validated_data['password'],
            role=validated_data.get('role', User.Role.CLIENTE)
        )
        # Se for motoqueiro, criar perfil
        if user.role == User.Role.MOTOQUEIRO:
            MotoqueiroProfile.objects.create(user=user)
        return user

class MotoqueiroProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    empresa_nome = serializers.ReadOnlyField(source='empresa.nome')
    
    class Meta:
        model = MotoqueiroProfile
        fields = '__all__'
