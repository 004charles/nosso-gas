import requests
from django.conf import settings
from apps.users.models import MotoqueiroProfile
from .models import Order
from decimal import Decimal
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

class OrderDispatcher:
    @staticmethod
    def get_top_motoqueiros(order_lat, order_lng, radius_km=5):
        """
        Filtro matemático inicial para encontrar motoqueiros num raio X.
        """
        # Simplificação: Usar um bounding box rudimentar antes do Google Maps para economizar cota
        # 1 grau de latitude ~ 111km
        lat_delta = Decimal(radius_km) / Decimal(111.0)
        lng_delta = Decimal(radius_km) / Decimal(111.0) # Aproximação grosseira para Luanda

        candidates = MotoqueiroProfile.objects.filter(
            status=MotoqueiroProfile.Status.ONLINE,
            stock_count__gt=0,
            current_lat__range=(order_lat - lat_delta, order_lat + lat_delta),
            current_lng__range=(order_lng - lng_delta, order_lng + lng_delta)
        )[:10] # Top 10 para não estourar a API Matrix
        
        return candidates

    @staticmethod
    def assign_best_motoqueiro(order_id):
        order = Order.objects.get(id=order_id)
        candidates = OrderDispatcher.get_top_motoqueiros(order.delivery_lat, order.delivery_lng)

        if not candidates.exists():
            return None

        # Montar URL do Google Distance Matrix
        origins = "|".join([f"{c.current_lat},{c.current_lng}" for c in candidates])
        destinations = f"{order.delivery_lat},{order.delivery_lng}"
        url = f"https://maps.googleapis.com/maps/api/distancematrix/json?origins={origins}&destinations={destinations}&key={settings.GOOGLE_MAPS_API_KEY}"

        try:
            response = requests.get(url)
            data = response.json()

            if data['status'] == 'OK':
                results = data['rows'][0]['elements']
                
                best_index = -1
                min_duration = float('inf')

                for i, res in enumerate(results):
                    if res['status'] == 'OK':
                        duration = res['duration']['value'] # Segundos
                        if duration < min_duration:
                            min_duration = duration
                            best_index = i
                
                if best_index != -1:
                    best_moto = candidates[best_index].user
                    order.motoqueiro = best_moto
                    order.status = Order.Status.ASSIGNED
                    order.save()
                    
                    # Notificar via WebSocket
                    OrderDispatcher.send_notification(best_moto.id, order)
                    
                    return best_moto
        except Exception as e:
            print(f"Erro na atribuição via Google Maps: {e}")
            # Fallback: Atribuir ao primeiro da lista se a API falhar
            best_moto = candidates[0].user
            order.motoqueiro = best_moto
            order.status = Order.Status.ASSIGNED
            order.save()
            
            # Notificar via WebSocket
            OrderDispatcher.send_notification(best_moto.id, order)
            
            return best_moto

        return None

    @staticmethod
    def send_notification(user_id, order):
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f"moto_{user_id}",
            {
                "type": "order_notification",
                "message": "Você tem um novo pedido de gás!",
                "order_data": {
                    "id": order.id,
                    "address": order.delivery_address,
                    "lat": float(order.delivery_lat),
                    "lng": float(order.delivery_lng),
                }
            }
        )
