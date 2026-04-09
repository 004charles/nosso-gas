import random
import string
from django.db import models
from django.conf import settings

class Order(models.Model):
    class Status(models.TextChoices):
        WAITING = 'EM_ESPERA', 'Em Espera'
        ASSIGNED = 'ATRIBUIDO', 'Atribuído'
        ON_THE_WAY = 'A_CAMINHO', 'A Caminho'
        DELIVERED = 'ENTREGUE', 'Entregue'
        CANCELLED = 'CANCELADO', 'Cancelado'

    cliente = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='customer_orders'
    )
    motoqueiro = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='moto_orders'
    )

    status = models.CharField(
        max_length=20, 
        choices=Status.choices, 
        default=Status.WAITING
    )

    # Detalhes do Pedido
    brand = models.CharField(max_length=20, default='SONANGOL')
    quantity = models.PositiveIntegerField(default=1)

    # Localização da Entrega
    delivery_lat = models.DecimalField(max_digits=9, decimal_places=6)
    delivery_lng = models.DecimalField(max_digits=9, decimal_places=6)
    delivery_address = models.TextField()

    # Segurança
    pin_code = models.CharField(max_length=4, editable=False)
    
    # Datas
    created_at = models.DateTimeField(auto_now_add=True)
    assigned_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)

    from django.utils import timezone
    from datetime import timedelta

    @property
    def is_expired(self):
        # Pedidos em espera por mais de 10 minutos são considerados expirados
        if self.status == self.Status.WAITING:
            return timezone.now() > self.created_at + timedelta(minutes=10)
        return False

    def save(self, *args, **kwargs):
        if not self.pin_code:
            self.pin_code = ''.join(random.choices(string.digits, k=4))
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Pedido {self.id} - {self.status}"
