import 'package:flutter/material.dart';
import 'package:voley_app/src/screens/admin/dashboard_screen.dart';
import '../auth/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await auth.register(emailCtrl.text.trim(), passCtrl.text.trim());
    setState(() => _isLoading = false);

    if (result == "success") {
      _showSnack("Cuenta creada exitosamente 🎉", success: true);
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
              const Text("Crear cuenta", textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
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
                  if (v.length < 6) return "Debe tener al menos 6 caracteres";
                  return null;
                },
              ),
              TextFormField(
                controller: pass2Ctrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
                validator: (v) {
                  if (v != passCtrl.text) return "Las contraseñas no coinciden";
                  return null;
                },
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Registrar", style: TextStyle(fontSize: 18)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("¿Ya tienes cuenta? Iniciar sesión"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
