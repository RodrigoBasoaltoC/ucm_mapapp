import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ucm_mapp_app/paginas/login.dart';
import 'package:ucm_mapp_app/paginas/main_map_page.dart';
//import 'package:ucm_mapp_app/paginas/splash_screen.dart';
import 'package:ucm_mapp_app/themes/dark_theme.dart';
import 'package:ucm_mapp_app/themes/light_theme.dart';
import 'package:ucm_mapp_app/themes/theme_model.dart';
import 'firebase_options.dart';
import 'paginas/authgate.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeModel(),
      child: const UCMMapApp(),
    ),
  );
}

class UCMMapApp extends StatelessWidget {
  const UCMMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModel>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'UCM MapApp (UI)',
          theme: lightTheme, // Tema claro
          darkTheme: darkTheme, // Tema oscuro
          themeMode: themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: const AuthGate(),
          routes: {
            // La ruta '/' es manejada por home, por lo que se elimina de aquí.
            '/sign-in': (context) => const SignInPage(),
            '/map': (context) => const MainMapPage(),
            '/profile': (context) => const ProfilePage(),
          },
        );
      },
    );
  }
}


