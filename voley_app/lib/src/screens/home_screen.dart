// lib/src/screens/home_screen.dart

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voley_app/providers/auth_provider.dart';
import 'package:voley_app/src/screens/user_management_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VolleyPro Trainer'),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),

            tooltip: 'Cerrar Sesión',

            onPressed: () async {
              final authService = ref.read(authServiceProvider);

              await authService.logout();

              // El AuthWrapper redirigirá automáticamente al LoginScreen
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // Bienvenida
            Text(
              '¡Bienvenido!',

              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              user?.email ?? 'Usuario',

              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),

            const SizedBox(height: 32),

            // Opciones principales
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,

                crossAxisSpacing: 16,

                mainAxisSpacing: 16,

                children: [
                  _buildMenuCard(
                    context,

                    icon: Icons.assessment,

                    title: 'Nueva Evaluación',

                    subtitle: 'Evaluar jugador',

                    color: Colors.blue,

                    onTap: () {
                      Navigator.pushNamed(context, '/evaluation');
                    },
                  ),

                  _buildMenuCard(
                    context,

                    icon: Icons.fitness_center,

                    title: 'Generar Programa',

                    subtitle: 'Crear programa',

                    color: Colors.green,

                    onTap: () {
                      Navigator.pushNamed(context, '/generate');
                    },
                  ),

                  _buildMenuCard(
                    context,

                    icon: Icons.list_alt,

                    title: 'Ver Programa',

                    subtitle: 'Programa actual',

                    color: Colors.orange,

                    onTap: () {
                      Navigator.pushNamed(context, '/program');
                    },
                  ),

                  _buildMenuCard(
                    context,

                    icon: Icons.person,

                    title: 'User Management',

                    subtitle: 'Manage users',

                    color: Colors.teal,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserManagementScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {

    required IconData icon,

    required String title,

    required String subtitle,

    required Color color,

    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(16),

        child: Padding(
          padding: const EdgeInsets.all(16.0),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(icon, size: 48, color: color),

              const SizedBox(height: 12),

              Text(
                title,

                textAlign: TextAlign.center,

                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,

                textAlign: TextAlign.center,

                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}