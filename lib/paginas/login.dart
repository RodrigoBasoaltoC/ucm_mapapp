import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider, AuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import '../firestore.dart';


const googleClientId = "887776342207-m9q6beik9f3u1jh1udj8s0fcasdjbtb1.apps.googleusercontent.com";

// Se mantiene la lista de providers para las pantallas de registro y perfil
final List<AuthProvider> providers = [
  EmailAuthProvider(),
  GoogleProvider(clientId: googleClientId),
];

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!mounted) return;
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce email y contraseña.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // La navegación es manejada por AuthGate
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de inicio de sesión: ${e.message}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: size.width,
          height: size.height,
          padding: EdgeInsets.only(left: 20, right: 20, bottom: size.height * 0.1, top: size.height * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Hola,\nbienvenido de nuevo",
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 50,),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColorLight,
                        borderRadius: const BorderRadius.all(Radius.circular(20))
                    ),
                    child: TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Email"
                      ),
                    ),
                  ),
                  const SizedBox(height: 20,),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColorLight,
                        borderRadius: const BorderRadius.all(Radius.circular(20))
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Contraseña"
                      ),
                    ),
                  ),
                  const SizedBox(height: 20,),
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordScreen(
                              email: _emailController.text,
                            ),
                          ),
                        );
                      },
                      child: Text("¿Olvidaste tu contraseña?", style: Theme.of(context).textTheme.bodyLarge,)
                  )
                ],
              ),
              Column(
                children: [
                  MaterialButton(
                    onPressed: _isLoading ? null : _signInWithEmail,
                    elevation: 0,
                    padding: const EdgeInsets.all(18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)
                    ),
                    color: Colors.blue,
                    child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Iniciar sesión", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),)),
                  ),
                  const SizedBox(height: 30,),
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomRegisterScreen(),
                          ),
                        );
                      },
                      child: Text("Crear cuenta", style: Theme.of(context).textTheme.bodyLarge)
                  ),
                  const SizedBox(height: 30,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OAuthProviderButton(
                        provider: GoogleProvider(clientId: googleClientId),
                        action: AuthAction.signIn,
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Nueva pantalla de registro personalizada
class CustomRegisterScreen extends StatefulWidget {
  const CustomRegisterScreen({super.key});

  @override
  State<CustomRegisterScreen> createState() => _CustomRegisterScreenState();
}

class _CustomRegisterScreenState extends State<CustomRegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerWithEmail() async {
    if (!mounted) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // La navegación es manejada por AuthGate, por lo que no se necesita hacer nada aquí.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de registro: ${e.message}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrarse')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  "¿Ya tienes una cuenta?",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context), // Vuelve a la pantalla de login
                  child: Text(
                    'Iniciar sesión',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
            ),
            const SizedBox(height: 40),
            MaterialButton(
              onPressed: _isLoading ? null : _registerWithEmail,
              elevation: 0,
              padding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: Colors.deepPurple,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Crear cuenta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            // SOLUCIÓN: Usar el botón pre-construido de Firebase UI
            OAuthProviderButton(
              provider: GoogleProvider(clientId: googleClientId),
              // Por defecto, este botón ya tiene el estilo de OutlinedButton
              // y se encarga de toda la lógica de autenticación.
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return ProfileScreen(
      providers: providers,
      actions: [
        SignedOutAction((context) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }),
        AccountDeletedAction((context, user) async {
          final navigator = Navigator.of(context);
          await firestoreService.deleteUser(user.uid);
          // Corrección: se debe usar context.mounted
          if (!context.mounted) return;
          navigator.popUntil((route) => route.isFirst);
        }),
      ],
    );
  }
}