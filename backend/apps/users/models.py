from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import MinValueValidator

class Empresa(models.Model):
    nome = models.CharField(max_length=100)
    endereco = models.CharField(max_length=255)
    contato = models.CharField(max_length=20)
    email = models.EmailField()

    def __str__(self):
        return self.nome

class User(AbstractUser):
    class Role(models.TextChoices):
        CLIENTE = 'CLIENTE', 'Cliente'
        MOTOQUEIRO = 'MOTOQUEIRO', 'Motoqueiro'
        ADMIN = 'ADMIN', 'Administrador'

    role = models.CharField(max_length=20, choices=Role.choices, default=Role.CLIENTE)
    phone = models.CharField(max_length=20, unique=True) # Identificador principal em Luanda

    USERNAME_FIELD = 'phone' # Define telefone como login
    REQUIRED_FIELDS = ['username'] # Username ainda pode ser usado para exibição

    def __str__(self):
        return f"{self.phone} ({self.role})"

class MotoqueiroProfile(models.Model):
    class Status(models.TextChoices):
        ONLINE = 'ONLINE', 'Online'
        OFFLINE = 'OFFLINE', 'Offline'
        OCUPADO = 'OCUPADO', 'Ocupado'

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='motoqueiro_profile')
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.OFFLINE)
    
    # Empresa / Distribuidora
    empresa = models.ForeignKey(Empresa, on_delete=models.SET_NULL, null=True, blank=True, related_name='motoqueiros')
    
    # Estoque detalhado
    stock_sonangol = models.PositiveIntegerField(default=0)
    stock_canata = models.PositiveIntegerField(default=0)
    
    # Localização em tempo real
    current_lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    current_lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    last_location_update = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Motoqueiro: {self.user.username} - {self.status}"
