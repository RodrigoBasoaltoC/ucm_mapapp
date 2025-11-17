import 'package:latlong2/latlong.dart';

import 'coordenadas.dart';
import 'salas.dart';

class SectorModel {
  final int id;
  final String nombre;
  final String descripcion;
  final List<SalasModel> salas = [];
  final List<CoordenadaModel> coordenadasRaw = []; // raw objects with orden_punto
  List<LatLng> coordenadas = []; // sorted LatLng ready to draw

  SectorModel({required this.id, required this.nombre, required this.descripcion});
}