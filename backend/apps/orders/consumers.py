import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from decimal import Decimal

class OrderConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope["user"]
        
        # Só aceita se estiver autenticado (simplificação para teste: aceitar todos e usar grupo motorista)
        # O ideal seria verificar se o user é um motoqueiro
        if self.user.is_authenticated:
            self.room_group_name = f"moto_{self.user.id}"

            # Join room group
            await self.channel_layer.group_add(
                self.room_group_name,
                self.channel_name
            )

            await self.accept()
        else:
            # Para testes sem auth complexa via WS agora, podemos permitir a conexão 
            # ou rejeitar. Vamos permitir se houver um query param 'user_id'
            query_params = self.scope.get('query_string', b'').decode()
            if 'user_id=' in query_params:
                user_id = query_params.split('user_id=')[1].split('&')[0]
                self.room_group_name = f"moto_{user_id}"
                await self.channel_layer.group_add(
                    self.room_group_name,
                    self.channel_name
                )
                await self.accept()
            else:
                await self.close()

    async def receive(self, text_data):
        data = json.loads(text_data)
        if data.get('type') == 'location_update':
            lat = data.get('lat')
            lng = data.get('lng')
            user_id = data.get('user_id')
            if lat and lng and user_id:
                await self.update_motoqueiro_location(user_id, lat, lng)

    @database_sync_to_async
    def update_motoqueiro_location(self, user_id, lat, lng):
        from apps.users.models import MotoqueiroProfile
        MotoqueiroProfile.objects.filter(user_id=user_id).update(
            current_lat=Decimal(str(lat)),
            current_lng=Decimal(str(lng))
        )

    async def disconnect(self, close_code):
        if hasattr(self, 'room_group_name'):
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )

    # Receive message from room group
    async def order_notification(self, event):
        message = event['message']
        order_data = event['order_data']

        # Send message to WebSocket
        await self.send(text_data=json.dumps({
            'type': 'new_order',
            'message': message,
            'order': order_data
        }))
