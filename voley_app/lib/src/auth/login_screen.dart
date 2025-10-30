import 'package:flutter/material.dart';
import 'package:voley_app/src/screens/admin/dashboard_screen.dart';
import '../auth/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final auth = AuthService();
  bool _isLoading = false;

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await auth.login(emailCtrl.text.trim(), passCtrl.text.trim());
    setState(() => _isLoading = false);

    if (result == "success") {
      _showSnack("Inicio de sesión exitoso", success: true);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      }
    } else {
      _showSnack(result ?? "Error desconocido");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 100),
              const Text("Iniciar sesión", textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Ingrese su correo";
                  if (!v.contains('@')) return "Correo no válido";
                  return null;
                },
              ),
              TextFormField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Ingrese su contraseña";
                  return null;
                },
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Entrar", style: TextStyle(fontSize: 18)),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text("¿No tienes cuenta? Crear una"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
