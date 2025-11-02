// lib/src/screens/create_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/providers/auth_provider.dart';
import 'package:voley_app/src/models/user.dart' as app_user;

class CreatePlayerScreen extends ConsumerStatefulWidget {
  const CreatePlayerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreatePlayerScreen> createState() => _CreatePlayerScreenState();
}

class _CreatePlayerScreenState extends ConsumerState<CreatePlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createPlayer() async {
    if (!_formKey.currentState!.validate()) return;
    
    final coachId = ref.read(currentUserAppUserProvider).valueOrNull?.id;
    if (coachId == null) {
      _showError('No se pudo identificar al coach.');
      return;
    }

    ref.read(isCreatingPlayerProvider.notifier).state = true;

    try {
      final authService = ref.read(authServiceProvider);
      
      final result = await authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        app_user.UserRole.player,
        coachId: coachId,
      );

      if (!mounted) return;

      if (result == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Jugador creado y vinculado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // --- MEJORA DE UX: Invalida el provider y cierra la pantalla ---
        ref.invalidate(coachPlayersProvider); // Refresca la lista en la pantalla anterior
        Navigator.pop(context); // Vuelve a la lista de gestión

      } else {
        _showError(result ?? 'Error al crear jugador');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        ref.read(isCreatingPlayerProvider.notifier).state = false;
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCreating = ref.watch(isCreatingPlayerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Jugador'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos del Jugador',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    validator: (value) => (value?.isEmpty ?? true) ? 'Ingresa el nombre' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa el correo';
                      if (!value.contains('@')) return 'Ingresa un correo válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña inicial',
                      prefixIcon: Icon(Icons.lock_outlined),
                      helperText: 'El jugador podrá cambiarla después',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa una contraseña';
                      if (value.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isCreating ? null : _createPlayer,
                      icon: isCreating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.person_add),
                      label: const Text('Crear Jugador'),
                    ),
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