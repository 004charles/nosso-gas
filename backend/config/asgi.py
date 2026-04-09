import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

# Inicializa a aplicação HTTP do Django primeiro
django_asgi_app = get_asgi_application()

# Importar o roteamento de WebSockets apenas após o get_asgi_application
# (Isso ajuda a evitar problemas de carregamento de apps)
import apps.orders.routing

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AuthMiddlewareStack(
        URLRouter(
            apps.orders.routing.websocket_urlpatterns
        )
    ),
})
