import 'dart:async'; // Para TimeoutException
import 'dart:convert'; // Para json.decode
import 'dart:io'; // Para SocketException
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapDisplayScreen extends StatefulWidget {
  final LatLng initialStoreLocation;
  final String initialStoreName;

  const MapDisplayScreen({
    super.key,
    required this.initialStoreLocation,
    required this.initialStoreName,
  });

  @override
  State<MapDisplayScreen> createState() => _MapDisplayScreenState();
}

class _MapDisplayScreenState extends State<MapDisplayScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentUserLocation;
  late LatLng _storeLocation;
  late String _storeName;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String _loadingMessage = "Cargando mapa...";
  bool _routeError = false; // Para indicar si hubo un error al obtener la ruta

  // ¡¡¡IMPORTANTE!!! REEMPLAZA ESTA CADENA CON TU API KEY REAL DE GOOGLE MAPS
  final String _apiKey = "AIzaSyBIZrptkE0IGakPhzMzMpq4PaW_gw_D1vk";
  // Asegúrate de tener habilitadas "Maps SDK for Android/iOS" y "Directions API" en Google Cloud.

  @override
  void initState() {
    super.initState();
    _storeLocation = widget.initialStoreLocation;
    _storeName = widget.initialStoreName;
    _initializeMapData();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating, // Hace que el SnackBar flote
        ),
      );
    }
  }

  Future<void> _initializeMapData() async {
    if (mounted) setState(() => _loadingMessage = "Obteniendo tu ubicación...");

    _addMarker(_storeLocation, 'storeLocation', _storeName, BitmapDescriptor.hueViolet); // Marcador de tienda

    await _getCurrentUserLocation();

    if (_currentUserLocation != null) {
      if (mounted) setState(() => _loadingMessage = "Calculando ruta...");
      await _getDirections();
    } else {
      // Si no se pudo obtener la ubicación del usuario, ya se habrá mostrado un SnackBar desde _getCurrentUserLocation
      // y se establecerá _loadingMessage. Solo marcamos que hubo error para la ruta.
      if (mounted) setState(() => _routeError = true);
    }

    if (mounted) setState(() => _isLoading = false);
    _updateCameraToBounds(); // Ajustar cámara después de todo
  }

  Future<void> _getCurrentUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar("Servicio de ubicación desactivado. Por favor, actívalo.");
      if (mounted) setState(() => _loadingMessage = "Activa la ubicación");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar("Permiso de ubicación denegado.");
        if (mounted) setState(() => _loadingMessage = "Permiso denegado");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar("Permiso de ubicación denegado permanentemente. Ve a configuración de la app.");
      if (mounted) setState(() => _loadingMessage = "Permiso denegado permanentemente");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20), // Aumentar un poco el timeout
      );
      if (mounted) {
        _currentUserLocation = LatLng(position.latitude, position.longitude);
        _addMarker(_currentUserLocation!, 'userLocation', 'Tu Ubicación', BitmapDescriptor.hueAzure);
        debugPrint("Ubicación actual del usuario: $_currentUserLocation");
      }
    } on TimeoutException {
      _showErrorSnackBar("Tiempo agotado al obtener tu ubicación. Intenta de nuevo.");
      if (mounted) setState(() => _loadingMessage = "No se pudo obtener ubicación");
    } catch (e) {
      _showErrorSnackBar("Error al obtener tu ubicación: ${e.toString()}");
      if (mounted) setState(() => _loadingMessage = "Error de ubicación");
      debugPrint("Error obteniendo ubicación del usuario: $e");
    }
  }

  Future<void> _getDirections() async {
    if (_currentUserLocation == null) {
      if (mounted) setState(() => _routeError = true); // Asegurarse de marcar error si no hay ubicación
      return;
    }

    String origin = "${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}";
    String destination = "${_storeLocation.latitude},${_storeLocation.longitude}";
    String url = "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$_apiKey&mode=driving";
    debugPrint("Directions API URL: $url"); // Útil para depurar la URL

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));

      if (mounted) { // Verificar antes de cualquier setState o SnackBar
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          String apiStatus = data['status'];

          if (apiStatus == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
            String points = data['routes'][0]['overview_polyline']['points'];
            List<LatLng> polylineCoordinates = _decodePolyline(points);
            setState(() {
              _polylines.add(
                Polyline(
                  polylineId: const PolylineId('route'),
                  color: Colors.deepPurpleAccent, // Color de la ruta
                  width: 6, // Grosor de la ruta
                  points: polylineCoordinates,
                ),
              );
              _routeError = false;
            });
          } else {
            debugPrint("API de Direcciones devolvió estado: $apiStatus. Mensaje: ${data['error_message'] ?? 'N/A'}");
            _showErrorSnackBar('No se pudo calcular la ruta: ${translateGoogleApiStatus(apiStatus)}');
            setState(() => _routeError = true);
          }
        } else {
          debugPrint("Error en solicitud HTTP a API de Direcciones: ${response.statusCode}, Body: ${response.body}");
          _showErrorSnackBar('Error de red al obtener ruta (${response.statusCode}).');
          setState(() => _routeError = true);
        }
      }
    } on TimeoutException {
      if (mounted) {
        _showErrorSnackBar('Tiempo agotado al solicitar la ruta. Verifica tu conexión.');
        setState(() => _routeError = true);
      }
    } on SocketException {
      if (mounted) {
        _showErrorSnackBar('Sin conexión a internet para obtener la ruta.');
        setState(() => _routeError = true);
      }
    } catch (e) {
      if (mounted) {
        debugPrint("Excepción no controlada al obtener la ruta: $e");
        _showErrorSnackBar('Error inesperado al obtener la ruta.');
        setState(() => _routeError = true);
      }
    }
  }

  String translateGoogleApiStatus(String status) {
    switch (status) {
      case 'NOT_FOUND': return 'Una de las ubicaciones no es válida.';
      case 'ZERO_RESULTS': return 'No se encontró ruta entre los puntos.';
      case 'MAX_WAYPOINTS_EXCEEDED': return 'Demasiados puntos.';
      case 'MAX_ROUTE_LENGTH_EXCEEDED': return 'Ruta demasiado larga.';
      case 'INVALID_REQUEST': return 'Solicitud inválida.';
      case 'OVER_DAILY_LIMIT': return 'Límite de API excedido por hoy.';
      case 'OVER_QUERY_LIMIT': return 'Límite de API excedido.';
      case 'REQUEST_DENIED': return 'Solicitud denegada (API Key o servicio).';
      case 'UNKNOWN_ERROR': return 'Error desconocido del servidor de mapas.';
      default: return status;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  void _addMarker(LatLng position, String markerId, String title, double hue) {
    final newMarker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(title: title),
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
    );
    if (mounted) {
      setState(() {
        _markers.add(newMarker);
      });
    }
  }

  void _updateCameraToBounds() {
    if (_mapController == null || _markers.isEmpty) return;

    if (_markers.length == 1) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_markers.first.position, 15.0));
      return;
    }

    // Calcular bounds para todos los marcadores presentes
    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (var marker in _markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }
    
    // Evitar que LatLngBounds falle si todos los puntos son iguales
    if (minLat == maxLat && minLng == maxLng && _markers.length > 1) {
       _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(minLat, minLng), 15.0));
       return;
    }


    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70.0)); // 70.0 es el padding
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ruta a: $_storeName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), // Icono de iOS más común
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _storeLocation, // Centrar inicialmente en la tienda
              zoom: 13, // Un zoom un poco más alejado al inicio
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              // La cámara se ajustará mejor en _initializeMapData -> _updateCameraToBounds
              // una vez que tengamos más información (ubicación del usuario, ruta)
              // Pero podemos hacer un ajuste inicial si solo tenemos la tienda
              if(!_isLoading && _markers.length == 1) _updateCameraToBounds();
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false, // Gestionamos nuestro propio marcador de ubicación
            myLocationButtonEnabled: false, // El botón por defecto
            zoomControlsEnabled: true,
            padding: const EdgeInsets.only(bottom: 80), // Padding para que el Card de error no tape controles
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6), // Un poco más oscuro para mejor contraste
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _loadingMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          if (!_isLoading && _routeError && _currentUserLocation != null) // Mostrar solo si tenemos ubicación de usuario
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                color: Colors.redAccent.shade100.withOpacity(0.95), // Un rojo más suave
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.black87, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No se pudo mostrar la ruta. Verifica tu conexión e inténtalo de nuevo.',
                          style: TextStyle(color: Colors.black.withOpacity(0.8), fontWeight: FontWeight.w500),
                          softWrap: true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.black54),
                        tooltip: "Reintentar obtener ruta",
                        onPressed: () {
                           if (mounted) {
                            setState(() {
                              _isLoading = true;
                              _loadingMessage = "Reintentando calcular ruta...";
                              _polylines.clear(); // Limpiar ruta anterior
                              _routeError = false; // Resetear estado de error
                            });
                            // Volver a llamar a _getDirections, y luego actualizar isLoading
                            _getDirections().then((_) {
                                if(mounted) {
                                  setState(() => _isLoading = false);
                                  _updateCameraToBounds(); // Ajustar cámara después del reintento
                                }
                            });
                          }
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}