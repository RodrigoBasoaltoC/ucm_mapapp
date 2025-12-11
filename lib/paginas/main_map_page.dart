import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import '../modelos/coordenadas.dart';
import '../modelos/salas.dart';
import '../modelos/sector.dart';
import '../servicios/auth_service.dart';
import '../servicios/location_service.dart';
import '../servicios/routing_service.dart';
import '../themes/theme_model.dart';
//import 'login_page.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
//import '../services/routing_service.dart';
//import '../services/location_service.dart';

class MainMapPage extends StatefulWidget {
  final bool isGuest;
  const MainMapPage({super.key, this.isGuest = false});

  @override
  State<MainMapPage> createState() => _MainMapPageState();
}

class _MainMapPageState extends State<MainMapPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  final LatLng _campusCenter = LatLng(-35.435352, -71.620956);

  // Datos
  List<SectorModel> _sectores = [];
  List<SalasModel> _salas = [];
  List<CoordenadaModel> _coordenadas = [];

  // Estado UI
  bool _loading = true;
  String? _errorMessage;
  SectorModel? _sectorSeleccionado;

  // Búsqueda
  final TextEditingController _searchController = TextEditingController();
  List<SalasModel> _searchResults = [];
  Timer? _debounce;

  // Rutas
  List<LatLng>? _ruta; // polyline points
  LatLng? _rutaDestinoCentroide; // destino de la ruta (centroide de sector)
  LatLng? _userLocation;

  // Endpoints (ajusta si cambian)
  final String _urlSalas = 'http://ckestreltesting.alwaysdata.net/api/salas/';
  final String _urlSectores = 'http://ckestreltesting.alwaysdata.net/api/sectores/';
  final String _urlCoordenadas = 'http://ckestreltesting.alwaysdata.net/api/sector_coordenadas/';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final responses = await Future.wait([
        http.get(Uri.parse(_urlSectores)),
        http.get(Uri.parse(_urlSalas)),
        http.get(Uri.parse(_urlCoordenadas)),
      ]);

      if (responses.any((r) => r.statusCode != 200)) {
        throw Exception('One or more endpoints returned non-200 status.');
      }

      final List<dynamic> jsonSectores = jsonDecode(responses[0].body);
      final List<dynamic> jsonSalas = jsonDecode(responses[1].body);
      final List<dynamic> jsonCoords = jsonDecode(responses[2].body);

      // Construir map de sectores
      final Map<int, SectorModel> sectoresMap = {};
      for (final s in jsonSectores) {
        final id = (s['id'] is int) ? s['id'] as int : int.parse('${s['id']}');
        final nombre = s['nombre']?.toString() ?? '';
        final descripcion = s['descripcion']?.toString() ?? '';
        sectoresMap[id] = SectorModel(id: id, nombre: nombre, descripcion: descripcion);
      }

      // Parse salas
      _salas = jsonSalas.map((e) {
        final id = (e['id'] is int) ? e['id'] as int : int.parse('${e['id']}');
        final idSector = (e['id_sector'] is int) ? e['id_sector'] as int : int.parse('${e['id_sector']}');
        final nombre = e['nombre']?.toString() ?? '';
        final piso = (e['piso'] is int) ? e['piso'] as int : int.parse('${e['piso']}');
        final sala = SalasModel(id: id, idSector: idSector, nombre: nombre, piso: piso);
        final sector = sectoresMap[idSector];
        if (sector != null) sector.salas.add(sala);
        return sala;
      }).toList();

      // Parse coordenadas
      _coordenadas = jsonCoords.map((e) {
        final id = (e['id'] is int) ? e['id'] as int : int.parse('${e['id']}');
        final idSector = (e['id_sector'] is int) ? e['id_sector'] as int : int.parse('${e['id_sector']}');
        final lat = (e['latitud'] is num) ? (e['latitud'] as num).toDouble() : double.parse('${e['latitud']}');
        final lng = (e['longitud'] is num) ? (e['longitud'] as num).toDouble() : double.parse('${e['longitud']}');
        final orden = (e['orden_punto'] is int) ? e['orden_punto'] as int : int.parse('${e['orden_punto']}');
        final coord = CoordenadaModel(id: id, idSector: idSector, latitud: lat, longitud: lng, ordenPunto: orden);
        final sector = sectoresMap[idSector];
        if (sector != null) sector.coordenadasRaw.add(coord);
        return coord;
      }).toList();

      // Ordenar y convertir coordenadas
      for (final sector in sectoresMap.values) {
        sector.coordenadasRaw.sort((a, b) => a.ordenPunto.compareTo(b.ordenPunto));
        sector.coordenadas = sector.coordenadasRaw.map((c) => LatLng(c.latitud, c.longitud)).toList();
      }

      setState(() {
        _sectores = sectoresMap.values.toList();
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Error cargando datos: ${e.toString()}';
        _sectores = [];
      });
    }
  }

  // Centroid calc
  LatLng _centroid(List<LatLng> poly) {
    if (poly.isEmpty) return _campusCenter;
    double lat = 0, lng = 0;
    for (final p in poly) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / poly.length, lng / poly.length);
  }

  // Buscar sala (filtrado simple)
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      final q = value.trim().toLowerCase();
      if (q.isEmpty) {
        setState(() {
          _searchResults = [];
        });
        return;
      }
      final results = _salas.where((s) => s.nombre.toLowerCase().contains(q)).toList();
      setState(() {
        _searchResults = results;
      });
    });
  }

  // Cuando seleccionas una sala de los resultados
  void _onSalaSelected(SalasModel sala) {
    final sector = _sectores.firstWhere((s) => s.id == sala.idSector, orElse: () => throw Exception('Sector no encontrado'));
    final centro = _centroid(sector.coordenadas);

    // centrar y abrir drawer del sector
    _mapController.move(centro, 18.0);
    setState(() {
      _sectorSeleccionado = sector;
      _searchResults = [];
      _searchController.text = sala.nombre;
    });
    //_scaffoldKey.currentState?.openEndDrawer();

    // Mostrar opción rápida de ruta (BottomSheet)
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sala seleccionada: ${sala.nombre}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.directions),
                  label: const Text('Mostrar ruta desde mi ubicación'),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _crearRutaHaciaSector(sector);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Crear ruta: obtiene ubicación, pide ruta a ORS y dibuja polyline
  Future<void> _crearRutaHaciaSector(SectorModel sector) async {
    setState(() {
      _loading = true;
    });

    try {
      final destino = _centroid(sector.coordenadas);
      // obtener ubicación del usuario
      final userPos = await LocationService.obtenerUbicacionActual();
      _userLocation = userPos;
      // pedir ruta a ORS
      final ruta = await RoutingService.obtenerRutaORS(origen: userPos, destino: destino);

      // actualizar estado para dibujar ruta
      setState(() {
        _ruta = ruta;
        _rutaDestinoCentroide = destino;
        _loading = false;
        _sectorSeleccionado = sector; // mantener seleccionado
      });

      // centrar mapa para que ruta sea visible (mover al centro de la ruta)
      final mid = ruta[ruta.length ~/ 2];
      _mapController.move(mid, 17.5);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo crear ruta: ${e.toString()}')));
    }
  }

  void _clearRuta() {
    setState(() {
      _ruta = null;
      _rutaDestinoCentroide = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final polygons = _sectores
        .where((s) => s.coordenadas.isNotEmpty)
        .map((s) => Polygon(
      points: s.coordenadas,
      borderColor: Colors.indigo.shade700,
      color: Colors.indigo.withOpacity(0.18),
      borderStrokeWidth: 2,
    ))
        .toList();

    final markers = _sectores
        .where((s) => s.coordenadas.isNotEmpty)
        .map<Marker>((s) {
      final c = _centroid(s.coordenadas);

      return Marker(
        point: c,
        width: 38,
        height: 38,
        child: GestureDetector(
          onTap: () {
            setState(() => _sectorSeleccionado = s);
            _scaffoldKey.currentState?.openEndDrawer();
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.indigo,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_city, color: Colors.white, size: 18),
          ),
        ),
      );
    })
        .toList();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Image.asset(
          'assets/imagenes/UCMMAPAPP2.png',
          height:70,
        ),
        toolbarHeight: 80,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _cargarDatos,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar datos',
          ),
          if (_ruta != null)
            IconButton(
              onPressed: _clearRuta,
              icon: const Icon(Icons.clear),
              tooltip: 'Quitar ruta',
            ),
        ],
          backgroundColor: Color(0xFF003B73)
      ),
      endDrawerEnableOpenDragGesture: false,
      endDrawer: _buildEndDrawer(context),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(center: _campusCenter, zoom: 17.5, minZoom: 15.0, maxZoom: 19.5),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ucm_mapapp',
              ),

              // Polygons (sectores)
              if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),

              // Ruta (polyline) si existe
              if (_ruta != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _ruta!,
                      strokeWidth: 5.0,
                      color: Colors.red,
                    ),
                  ],
                ),

              // Markers (centroides)
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
            ],
          ),

          // Search bar positioned at top
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _buildSearchBar(),
          ),

          // Search suggestions dropdown
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 68,
              left: 12,
              right: 12,
              child: _buildSearchResults(),
            ),

          // Loading overlay
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.7),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),

          if (_errorMessage != null)
            Positioned(
              left: 8,
              right: 8,
              top: 12,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Colors.orange.shade700,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _errorMessage = null),
                        child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.move(_campusCenter, 17.5);
          _mapController.rotate(0);
        },
        backgroundColor: const Color(0xFF003B73),
        child: const Icon(Icons.explore),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(30),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar sala (ej: J101)',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchResults = []);
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  SectorModel? _getSectorById(int id) {
    try {
      return _sectores.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  Widget _buildSearchResults() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        children: _searchResults.map((sala) {
          final SectorModel? sector = _getSectorById(sala.idSector);

          final subtitle = sector != null ? sector.nombre : 'Sector desconocido';

          return ListTile(
            title: Text(sala.nombre),
            subtitle: Text(subtitle),
            trailing: IconButton(
              icon: const Icon(
                  Icons.directions,
                  //color: Colors.green,
              ),
              onPressed: () async {
                if (sector != null) {
                  await _crearRutaHaciaSector(sector);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sector no disponible')),
                  );
                }
              },
            ),
            onTap: () => _onSalaSelected(sala),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEndDrawer(BuildContext context) {
    if (_sectorSeleccionado == null) {
      return const Drawer(child: Center(child: Text('No hay sector seleccionado')));
    }

    final sector = _sectorSeleccionado!;
    final floors = sector.salas.map((c) => c.piso).toSet().toList()..sort((a,b) => b.compareTo(a));

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: const Color(0xFF003B73),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(sector.nombre, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () {
                    Navigator.of(context).pop();
                    setState(() => _sectorSeleccionado = null);
                  }),
                ],
              ),
            ),
            if (sector.descripcion.isNotEmpty)
              Padding(padding: const EdgeInsets.all(12.0), child: Text(sector.descripcion, style: const TextStyle(color: Colors.black54))),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: floors.map((floor) {
                  final rooms = sector.salas.where((r) => r.piso == floor).toList();
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: ExpansionTile(
                      leading: const Icon(Icons.layers, color: Color(0xFF003B73)),
                      title: Text('Piso $floor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      children: rooms.map((r) {
                        return ListTile(
                          title: Text(r.nombre),
                          leading: const Icon(Icons.meeting_room, color: Color(0xFF003B73)),
                          trailing: IconButton(
                            icon: const Icon(Icons.directions),
                            onPressed: () async {
                              // Crear ruta hacia la sala (usa el centroide del sector)
                              await _crearRutaHaciaSector(sector);
                            },
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seleccionada ${r.nombre}')));
                          },
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}