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

  // --- MEJORA: '_isLoading' ya no es necesario ---
  
  // Estado local solo para UI
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  app_user.UserRole _selectedRole = app_user.UserRole.player;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// --- MEJORA: La lógica se mueve al provider ---
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Llama al notifier para que haga el trabajo
    await ref.read(registerControllerProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: _selectedRole,
        );
  }

  @override
  Widget build(BuildContext context) {
    // --- MEJORA: Observa el estado del provider ---
    final registerState = ref.watch(registerControllerProvider);
    final theme = Theme.of(context);

    // --- MEJORA: Escucha el provider para mostrar errores o éxito ---
    ref.listen(registerControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
      if (next is AsyncData) {
        // Muestra el éxito. El AuthWrapper se encargará de la navegación.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Bienvenido'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        // El tema "Volt Pro" ya define esto
        backgroundColor: Colors.transparent,
        elevation: 0, 
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
                  // --- MEJORA DE DISEÑO: Icono "Volt Pro" ---
                  Icon(
                    Icons.sports_volleyball,
                    size: 80,
                    color: theme.colorScheme.primary, // Color Volt
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Crear Cuenta',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Regístrate para comenzar tu entrenamiento',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodySmall?.color, // Color del tema
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Campo de nombre (hereda el tema)
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de email (hereda el tema)
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
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

                  // --- MEJORA DE UI: Selector de rol como Card ---
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tipo de usuario',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          RadioListTile<app_user.UserRole>(
                            title: const Text('Jugador'),
                            subtitle: const Text('Quiero entrenar y mejorar'),
                            value: app_user.UserRole.player,
                            groupValue: _selectedRole,
                            onChanged: (value) {
                              setState(() => _selectedRole = value!);
                            },
                            // --- MEJORA DE DISEÑO ---
                            activeColor: theme.colorScheme.primary, // Volt
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
                            // --- MEJORA DE DISEÑO ---
                            activeColor: theme.colorScheme.primary, // Volt
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // --- FIN DE MEJORA DE UI ---

                  const SizedBox(height: 16),

                  // Campo de contraseña (hereda el tema)
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
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
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
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () {
                          setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          );
                        },
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
                    // --- MEJORA DE UX: Deshabilitado mientras carga ---
                    onPressed: registerState.isLoading ? null : _handleRegister,
                    // Estilo heredado del tema global
                    child: registerState.isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary, // Texto oscuro
                              ),
                            ),
                          )
                        : const Text(
                            'Registrarse',
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Link a login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes cuenta? ',
                        style: TextStyle(color: theme.textTheme.bodySmall?.color),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).maybePop();
                        },
                        // Estilo heredado del tema global
                        child: const Text('Inicia Sesión'),
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