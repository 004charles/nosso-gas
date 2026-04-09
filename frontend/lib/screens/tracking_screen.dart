import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'dart:async';
import '../services/order_websocket_service.dart';
import '../core/theme.dart';

class TrackingScreen extends StatefulWidget {
  final int orderId;
  const TrackingScreen({super.key, required this.orderId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late GoogleMapController _mapController;
  final OrderWebSocketService _socketService = OrderWebSocketService();
  LatLng? _driverLocation;
  final Set<Marker> _markers = {};

  void _connectWebSocket() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.user?['id'];
    if (userId != null) {
      _socketService.connect(userId);
    }
    _socketService.stream.listen((data) {
      if (data['type'] == 'location_update') {
        setState(() {
          _driverLocation = LatLng(data['lat'], data['lng']);
          _updateMarkers();
          _animateToLocation();
        });
      }
    });
  }

  void _updateMarkers() {
    if (_driverLocation == null) return;
    
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId("driver"),
        position: _driverLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: "O teu Gás"),
      ),
    );
  }

  void _animateToLocation() {
    if (_driverLocation == null) return;
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_driverLocation!, 16),
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Pedido #${widget.orderId}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-8.8390, 13.2894), // Luanda Default
              zoom: 13,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            myLocationEnabled: true,
            style: _mapStyle, // Estilo Dark
          ),
          
          // Painel Inferior de Info
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGrey,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                children: [
                   const CircleAvatar(
                    backgroundColor: AppTheme.primaryOrange,
                    radius: 25,
                    child: Icon(Icons.motorcycle, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("O Seu Gás está a caminho", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          _driverLocation != null ? "A chegar em breve..." : "A aguardar sinal do motoqueiro...",
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  final String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#212121"}]
    },
    {
      "elementType": "labels.icon",
      "stylers": [{"visibility": "off"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#303030"}]
    }
  ]
  ''';
}
