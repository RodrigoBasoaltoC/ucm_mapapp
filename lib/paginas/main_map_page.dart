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
import '../themes/theme_model.dart';
//import 'login_page.dart';

class MainMapPage extends StatefulWidget {
  const MainMapPage({super.key});

  @override
  State<MainMapPage> createState() => _MainMapPageState();
}

class _MainMapPageState extends State<MainMapPage> {
  // Scaffold key para abrir endDrawer de los marcadores
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService (); // Instancia del servicio de autenticación

  // Controlador de mapas y centro
  final MapController _mapController = MapController();
  final LatLng _campusCenter = LatLng(-35.435352, -71.620956);

  // Los contenedores de los datos
  List<SectorModel> _sectores = [];
  List<SalasModel> _salas = [];
  List<CoordenadaModel> _coordenadas = [];

  // estado UI
  bool _loading = true;
  String? _errorMessage; // if not null show a banner but keep map usable
  SectorModel? _sectorSeleccionado;

  // Endpoints
  final String _urlSalas = 'http://ckestreltesting.alwaysdata.net/api/salas/';
  final String _urlSectores = 'http://ckestreltesting.alwaysdata.net/api/sectores/';
  final String _urlCoordenadas = 'http://ckestreltesting.alwaysdata.net/api/sector_coordenadas/';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // fetch paralelo
      final responses = await Future.wait([
        http.get(Uri.parse(_urlSectores)),
        http.get(Uri.parse(_urlSalas)),
        http.get(Uri.parse(_urlCoordenadas)),
      ]);

      // validar respuestas
      if (responses.any((r) => r.statusCode != 200)) {
        throw Exception('One or more endpoints returned non-200 status.');
      }

      // Parse JSON
      final List<dynamic> jsonSectores = jsonDecode(responses[0].body);
      final List<dynamic> jsonSalas = jsonDecode(responses[1].body);
      final List<dynamic> jsonCoords = jsonDecode(responses[2].body);

      // Crear lista de sectores (sin coordenadas ni salas todavía)
      final Map<int, SectorModel> sectoresMap = {};
      for (final s in jsonSectores) {
        final id = (s['id'] is int) ? s['id'] as int : int.parse('${s['id']}');
        final nombre = s['nombre']?.toString() ?? '';
        final descripcion = s['descripcion']?.toString() ?? '';
        sectoresMap[id] = SectorModel(id: id, nombre: nombre, descripcion: descripcion);
      }

      // Parse salas y asignar a sector correcto en base a id_sector
      _salas = jsonSalas.map((e) {
        final id = (e['id'] is int) ? e['id'] as int : int.parse('${e['id']}');
        final idSector = (e['id_sector'] is int) ? e['id_sector'] as int : int.parse('${e['id_sector']}');
        final nombre = e['nombre']?.toString() ?? '';
        final piso = (e['piso'] is int) ? e['piso'] as int : int.parse('${e['piso']}');
        final sala = SalasModel(id: id, idSector: idSector, nombre: nombre, piso: piso);
        // assign to sector
        final sector = sectoresMap[idSector];
        if (sector != null) sector.salas.add(sala);
        return sala;
      }).toList();

      // Parse coordenadas y asignar; mantener orden_punto para ordenar después
      _coordenadas = jsonCoords.map((e) {
        final id = (e['id'] is int) ? e['id'] as int : int.parse('${e['id']}');
        final idSector = (e['id_sector'] is int) ? e['id_sector'] as int : int.parse('${e['id_sector']}');
        final lat = (e['latitud'] is num) ? (e['latitud'] as num).toDouble() : double.parse('${e['latitud']}');
        final lng = (e['longitud'] is num) ? (e['longitud'] as num).toDouble() : double.parse('${e['longitud']}');
        final orden = (e['orden_punto'] is int) ? e['orden_punto'] as int : int.parse('${e['orden_punto']}');
        final coord = CoordenadaModel(id: id, idSector: idSector, latitud: lat, longitud: lng, ordenPunto: orden);
        // assign to sector
        final sector = sectoresMap[idSector];
        if (sector != null) sector.coordenadasRaw.add(coord);
        return coord;
      }).toList();

      // Para cada sector, sort coordenadasRaw por ordenPunto y crear lista LatLng
      for (final sector in sectoresMap.values) {
        sector.coordenadasRaw.sort((a, b) => a.ordenPunto.compareTo(b.ordenPunto));
        sector.coordenadas = sector.coordenadasRaw.map((c) => LatLng(c.latitud, c.longitud)).toList();
      }

      // Guardar sectores en el estado (list)
      setState(() {
        _sectores = sectoresMap.values.toList();
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      // Mostrar mensaje de error dejando el mapa vacio pero usable
      setState(() {
        _loading = false;
        _errorMessage = 'Error cargando datos: ${e.toString()}';
        _sectores = []; // keep empty so map is usable
      });
    }
  }

  // Centroide del poligono para colocar el marcador
  LatLng _centroid(List<LatLng> poly) {
    if (poly.isEmpty) return _campusCenter;
    double lat = 0, lng = 0;
    for (final p in poly) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / poly.length, lng / poly.length);
  }

  //Pisos para sector seleccionado (ordenados de forma descendente)
  List<int> _getPisos(SectorModel sector) {
    final floors = sector.salas.map((s) => s.piso).toSet().toList();
    floors.sort((a, b) => b.compareTo(a));
    return floors;
  }

  Widget _buildAppDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF003B73),
            ),
            child: Text(
              'UCM MapApp',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Datos de Usuario'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          // Botón para cambiar el tema
          Consumer<ThemeModel>(
            builder: (context, themeNotifier, child) => ListTile(
              leading: Icon(themeNotifier.isDark ? Icons.nightlight_round : Icons.wb_sunny),
              title: Text(themeNotifier.isDark ? 'Modo Oscuro' : 'Modo Claro'),
              onTap: () {
                themeNotifier.isDark = !themeNotifier.isDark;
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () {
              _authService.signOut();
              // La navegación ahora la maneja AuthGate después de que el estado cambia
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Construir lista de poligonos a partir de _sectores
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
        .map((s) {
      final c = _centroid(s.coordenadas);
      return Marker(
        point: c,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _sectorSeleccionado = s;
            });
            _scaffoldKey.currentState?.openEndDrawer();
          },
          child: Container(
            width:  38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.indigo,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
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
        title: const Text('UCM MapApp'),
        actions: [
          /*IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage())),
            icon: const Icon(Icons.login),
          ),*/
          IconButton(
            onPressed: () => _cargarDatos(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar datos',
          ),
        ],
      ),
      drawer: _buildAppDrawer(context),
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
                maxZoom: 22,
                maxNativeZoom: 19,
              ),
              if (polygons.isNotEmpty)
                PolygonLayer(polygons: polygons),
              if (markers.isNotEmpty)
                MarkerLayer(markers: markers),
            ],
          ),

          // Cargar overlay durante la busqueda para una mejor UX
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.7),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),

          // banner de error arriba, mapa aun es usable
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
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
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
          // Centrar mapa a la universidad
          _mapController.move(_campusCenter, 17.5);
        },
        backgroundColor: const Color(0xFF003B73),
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildEndDrawer(BuildContext context) {
    if (_sectorSeleccionado == null) {
      return const Drawer(child: Center(child: Text('No hay sector seleccionado')));
    }

    final sector = _sectorSeleccionado!;
    final floors = _getPisos(sector);

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
                    child: Text(
                      sector.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() => _sectorSeleccionado = null);
                    },
                  ),
                ],
              ),
            ),
            if (sector.descripcion.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(sector.descripcion, style: const TextStyle(color: Colors.black54)),
              ),
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
                      children: rooms
                          .map((r) => ListTile(
                        title: Text(r.nombre),
                        leading: const Icon(Icons.meeting_room, color: Color(0xFF003B73)),
                        onTap: () {
                          // Ejemplo: mostrar snackbar (reemplazar con comportamiento deseado)
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seleccionada ${r.nombre}')));
                        },
                      ))
                          .toList(),
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