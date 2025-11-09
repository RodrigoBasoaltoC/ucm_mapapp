import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const UCMMapApp());
}

class UCMMapApp extends StatelessWidget {
  const UCMMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCM MapApp (UI)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003B73),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003B73),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003B73),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// ---------------- SPLASH SCREEN -----------------

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2080FE),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/imagenes/UCMMAPAPP2.png', height: 362, width: 348),
            const SizedBox(height: 1),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainMapPage()),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(180, 50)),
              child: const Text("Bienvenido",
                style: TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- MAIN MAP PAGE -----------------
class MainMapPage extends StatefulWidget {
  const MainMapPage({super.key});

  @override
  State<MainMapPage> createState() => _MainMapPageState();
}

class _MainMapPageState extends State<MainMapPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Sector? sectorSeleccionado;

  final List<Sector> demoSectores = [
    Sector(
      id: 1,
      nombre: "Edificio J",
      salas: [
        Salas("J101", 1),
        Salas("J102", 1),
        Salas("J201", 2),
      ],
      posicion: LatLng(-35.435352, -71.620956),
    ),
    Sector(
      id: 1,
      nombre: "Edificio F",
      salas: [
        Salas("F101", 1),
        Salas("F102", 1),
        Salas("F201", 2),
      ],
      posicion: LatLng(-35.434793, -71.617857),
    ),

  ];

  //-35.434793, -71.617857
  void _onSectorTap(Sector sector) {
    setState(() => sectorSeleccionado = sector);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('UCM MapApp'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LoginPage()));
            },
            icon: const Icon(Icons.login, color: Colors.white),
            label: Text("Login",
                style: TextStyle(color: Colors.white)
            ),
          ),
        ],
      ),
      endDrawerEnableOpenDragGesture: false,
      endDrawer: _buildEndDrawer(context),
      body: Container(
        color: const Color(0xFFF8FAFD),
        child: FlutterMap(
          options: MapOptions(
            center: LatLng(-35.435352, -71.620956),
            zoom: 18.0,
            maxZoom: 20,
            minZoom: 16,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.ucm_mapapp',
            ),
            MarkerLayer(
              markers: demoSectores.map((sector) {
                return Marker(
                  width: 50,
                  height: 50,
                  point: sector.posicion,
                  builder: (ctx) => GestureDetector(
                    onTap: () => _onSectorTap(sector),
                    child: Tooltip(
                      message: sector.nombre,
                      child: const Icon(
                        Icons.location_city,
                        color: Color(0xFF003B73),
                        size: 36,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndDrawer(BuildContext context) {
    if (sectorSeleccionado == null) {
      return const SizedBox.shrink();
    }

    final floors = sectorSeleccionado!.getPisos();

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
                      sectorSeleccionado!.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: floors.map((floor) {
                  final floorClassrooms = sectorSeleccionado!.salas
                      .where((c) => c.piso == floor)
                      .toList();
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: ExpansionTile(
                      leading: const Icon(Icons.layers, color: Color(0xFF003B73)),
                      title: Text(
                        "Piso $floor",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      children: floorClassrooms
                          .map((room) => ListTile(
                        title: Text(room.nombre),
                        leading: const Icon(Icons.meeting_room,
                            color: Color(0xFF003B73)),
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

// ---------------- Pagina Login -----------------
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      backgroundColor: const Color(0xFFEFF4FB),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("¡Hola!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const TextField(
              decoration: InputDecoration(
                labelText: "Usuario",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Contraseña",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Modelos de datos -----------------
class Sector {
  final int id;
  final String nombre;
  final List<Salas> salas;
  final LatLng posicion;

  Sector({
    required this.id,
    required this.nombre,
    required this.salas,
    required this.posicion,
  });

  List<int> getPisos() {
    final floors = salas.map((c) => c.piso).toSet().toList();
    floors.sort();
    return floors;
  }
}

class Salas {
  final String nombre;
  final int piso;
  Salas(this.nombre, this.piso);
}
