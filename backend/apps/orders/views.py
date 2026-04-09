from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Order
from .serializers import OrderSerializer
from .services import OrderDispatcher

class OrderViewSet(viewsets.ModelViewSet):
    queryset = Order.objects.all()
    serializer_class = OrderSerializer

    def perform_create(self, serializer):
        # Salvar o pedido inicialmente como 'EM_ESPERA'
        order = serializer.save(cliente=self.request.user)
        # Por agora mantemos o manual, mas o dispatcher pode rodar em background
        return order

    @action(detail=True, methods=['post'])
    def accept_order(self, request, pk=None):
        order = self.get_object()
        if order.status != 'EM_ESPERA':
            return Response({'error': 'Pedido já atribuído ou finalizado'}, status=status.HTTP_400_BAD_REQUEST)
        
        order.motoqueiro = request.user
        order.status = 'ATRIBUIDO'
        order.save()
        
        return Response({'message': 'Pedido aceite com sucesso', 'status': order.status})
