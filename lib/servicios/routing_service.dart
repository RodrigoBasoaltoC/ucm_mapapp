// lib/services/routing_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  // Reemplazar con clave OpenRouteService


  /// Obtiene una ruta peatonal (foot-walking) entre origen y destino usando
  /// OpenRouteService Directions API. Devuelve una lista de LatLng.
  static Future<List<LatLng>> obtenerRutaORS({
    required LatLng origen,
    required LatLng destino,
  }) async {
    final url = Uri.parse('https://api.openrouteservice.org/v2/directions/foot-walking/geojson');

    final body = jsonEncode({
      "coordinates": [
        [origen.longitude, origen.latitude],
        [destino.longitude, destino.latitude]
      ]
    });

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _apiKey,
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('Error en ORS: ${resp.statusCode} ${resp.body}');
    }

    final Map<String, dynamic> data = jsonDecode(resp.body);
    final coords = data['features'][0]['geometry']['coordinates'] as List<dynamic>;

    final List<LatLng> ruta = coords.map<LatLng>((c) {
      final double lng = (c[0] as num).toDouble();
      final double lat = (c[1] as num).toDouble();
      return LatLng(lat, lng);
    }).toList();

    return ruta;
  }
}