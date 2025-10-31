// lib/src/screens/auth/register_screen.dart

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voley_app/providers/auth_provider.dart';
import 'package:voley_app/src/models/user.dart' as app_user;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  bool _obscurePassword = true;

  bool _obscureConfirmPassword = true;
  app_user.UserRole _selectedRole = app_user.UserRole.player;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();

    _passwordController.dispose();

    _confirmPasswordController.dispose();
    _nameController.text.trim();

    _selectedRole;

    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);

    final result = await authService.register(
      _emailController.text.trim(),

      _passwordController.text,

      _nameController.text.trim(),

      _selectedRole,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result == "success") {
      // Mostrar mensaje de éxito

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Registro exitoso! Bienvenido'),

          backgroundColor: Colors.green,
        ),
      );

      // La navegación se manejará automáticamente por el AuthWrapper
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ?? "Error al registrarse"),

          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,

        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),

          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),

            child: Form(
              key: _formKey,

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [
                  // Logo o título
                  Icon(
                    Icons.sports_volleyball,

                    size: 80,

                    color: Theme.of(context).primaryColor,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Crear Cuenta',

                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),

                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Regístrate para comenzar tu entrenamiento',

                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),

                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Campo de nombre
                  TextFormField(
                    controller: _nameController,

                    keyboardType: TextInputType.name,

                    decoration: InputDecoration(
                      labelText: 'Nombre completo',

                      prefixIcon: const Icon(Icons.person_outlined),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu nombre';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Campo de email
                  TextFormField(
                    controller: _emailController,

                    keyboardType: TextInputType.emailAddress,

                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',

                      prefixIcon: const Icon(Icons.email_outlined),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo';
                      }

                      if (!value.contains('@')) {
                        return 'Ingresa un correo válido';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Selector de rol
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),

                      borderRadius: BorderRadius.circular(12),
                    ),

                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Tipo de usuario',

                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 12),

                        RadioListTile<app_user.UserRole>(
                          title: const Text('Jugador'),

                          subtitle: const Text('Quiero entrenar y mejorar'),

                          value: app_user.UserRole.player,

                          groupValue: _selectedRole,

                          onChanged: (value) {
                            setState(() => _selectedRole = value!);
                          },

                          contentPadding: EdgeInsets.zero,
                        ),

                        RadioListTile<app_user.UserRole>(
                          title: const Text('Entrenador'),

                          subtitle: const Text('Quiero entrenar a jugadores'),

                          value: app_user.UserRole.coach,

                          groupValue: _selectedRole,

                          onChanged: (value) {
                            setState(() => _selectedRole = value!);
                          },

                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Campo de contraseña
                  TextFormField(
                    controller: _passwordController,

                    obscureText: _obscurePassword,

                    decoration: InputDecoration(
                      labelText: 'Contraseña',

                      prefixIcon: const Icon(Icons.lock_outlined),

                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),

                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa una contraseña';
                      }

                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Campo de confirmar contraseña
                  TextFormField(
                    controller: _confirmPasswordController,

                    obscureText: _obscureConfirmPassword,

                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',

                      prefixIcon: const Icon(Icons.lock_outlined),

                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),

                        onPressed: () {
                          setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          );
                        },
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor confirma tu contraseña';
                      }

                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Botón de registro
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,

                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    child: _isLoading
                        ? const SizedBox(
                            height: 20,

                            width: 20,

                            child: CircularProgressIndicator(
                              strokeWidth: 2,

                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Registrarse',

                            style: TextStyle(fontSize: 16),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Link a login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Text(
                        '¿Ya tienes cuenta? ',

                        style: TextStyle(color: Colors.grey[600]),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },

                        child: const Text(
                          'Inicia Sesión',

                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
