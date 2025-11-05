// lib/screens/profile_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  Future<void> _confirmAndSignOut(BuildContext context, WidgetRef ref) async {

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar tu sesión en este dispositivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Opción A: cerrar sesión con FirebaseAuth directo
      await FirebaseAuth.instance.signOut();

      // Opción B (si tu AuthService tiene signOut):
      // await ref.read(authServiceProvider).signOut();

      // (Opcional) invalidar providers que dependan del usuario
      // ref.invalidate(playerProfileProvider);
      // ref.invalidate(exercisesProvider);
      // ref.invalidate(currentUserProvider);

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cerrar sesión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Perfil'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmAndSignOut(context, ref),
          ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text('Evaluación y Métricas'),
          ),
          ListTile(
            leading: const Icon(Icons.assessment_outlined),
            title: const Text('Mi Evaluación Física'),
            subtitle: const Text('Actualizar mis tests y métricas'),
            onTap: () => Navigator.pushNamed(context, '/player_evaluation'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Información Básica'),
            subtitle: const Text('Nombre, posición, nivel, etc.'),
            onTap: () => Navigator.pushNamed(context, '/edit_basic_info'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text('Planificación'),
          ),
          ListTile(
            leading: const Icon(Icons.track_changes_outlined),
            title: const Text('Mis Objetivos'),
            onTap: () => Navigator.pushNamed(context, '/edit_goals'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Disponibilidad y Estado'),
            subtitle: const Text('Días de entreno, lesiones'),
            onTap: () => Navigator.pushNamed(context, '/edit_availability'),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Fechas Clave'),
            onTap: () => Navigator.pushNamed(context, '/edit_key_events'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text('Historial'),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Historial de Torneos'),
            onTap: () => Navigator.pushNamed(context, '/edit_tournaments'),
          ),
          const Divider(),

          // --- Cuenta ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text('Cuenta'),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Cerrar sesión',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _confirmAndSignOut(context, ref),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
