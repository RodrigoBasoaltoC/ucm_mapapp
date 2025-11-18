import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../firestore.dart';
import '../modelos/app_user.dart';
import '../servicios/auth_service.dart';
import 'login.dart';
import 'main_map_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData) {
          return const SignInPage();
        }

        // Si el usuario ha iniciado sesión, nos aseguramos de que sus datos estén en Firestore
        // y LUEGO mostramos el mapa. Esto funciona para CUALQUIER proveedor.
        final user = snapshot.data!;
        return FutureBuilder(
          future: FirestoreService().setUser(
            AppUser(
              uid: user.uid,
              email: user.email,
              username: user.displayName,
            ),
          ),
          builder: (context, futureSnapshot) {
            // Mientras se guardan los datos, mostramos una pantalla de carga
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // Una vez guardados los datos, mostramos el mapa
            return const MainMapPage();
          },
        );
      },
    );
  }
}