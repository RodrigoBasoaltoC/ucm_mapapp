import 'package:flutter/material.dart';
import 'main_map_page.dart';

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