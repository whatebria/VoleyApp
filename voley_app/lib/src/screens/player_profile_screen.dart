// lib/src/screens/player_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart'; // Importa 'ownProfileProvider'
import 'package:intl/intl.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart'; // Importa el modelo

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observa el FutureProvider reactivo
    final profileAsync = ref.watch(ownProfileProvider);
    final theme = Theme.of(context);

    return profileAsync.when(
      // --- ESTADO DE CARGA ---
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      
      // --- ESTADO DE ERROR ---
      error: (e, s) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error al cargar tu perfil: $e', textAlign: TextAlign.center),
          ),
        ),
      ),

      // --- ESTADO DE DATOS (Éxito) ---
      data: (profile) {
        if (profile == null) {
          // --- MEJORA DE UX: "Empty State" Motivacional ---
          return _buildEmptyState(context, theme);
        } else {
          // --- MEJORA DE UI: El "Panel de Atleta" ---
          return _buildProfileView(context, theme, profile);
        }
      },
    );
  }

  /// --- MEJORA DE UI/UX: El "Panel de Atleta" ---
  Widget _buildProfileView(BuildContext context, ThemeData theme, PlayerProfile profile) {
    // Separa las estadísticas clave de las demás
    final keyStats = profile.evaluation.testScores;
    // (Opcional: puedes definir una lista de "stats clave" y filtrar)

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        tooltip: 'Editar Evaluación',
        onPressed: () {
          Navigator.pushNamed(context, '/player_evaluation');
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Padding inferior para el FAB
        children: [
          // --- 1. Tarjeta "Héroe" (Quién soy) ---
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: theme.colorScheme.primary, // Volt
                    child: Text(
                      profile.name.isNotEmpty ? profile.name.substring(0, 2).toUpperCase() : '??',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary, // Texto oscuro
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.position} | ${profile.level.isNotEmpty ? profile.level[0].toUpperCase() + profile.level.substring(1) : ""}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.secondary), // Azul Pro
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- 2. Sección "Estadísticas Clave" (Mis números) ---
          Text(
            'Mis Estadísticas Clave',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 16),
          if (keyStats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'Aún no tienes tests registrados.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodySmall?.color),
                ),
              ),
            )
          else
            // --- MEJORA DE UI: Grid escaneable ---
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5, // Más anchas que altas
              children: keyStats.entries.map((test) {
                return _buildStatCard(
                  theme,
                  title: test.key, // "Salto Vertical"
                  value: test.value.toString(),
                  unit: 'cm', // (Necesitarías un modelo de "unidad" aquí, por ahora es fijo)
                );
              }).toList(),
            ),
          
          const SizedBox(height: 24),

          // --- 3. Sección "Estado Actual" (Mi logística) ---
          Text(
            'Mi Estado',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 16),
          _InfoRow(
            theme,
            icon: Icons.healing_outlined,
            title: 'Lesiones',
            value: profile.injuries.isEmpty ? 'Ninguna' : profile.injuries.join(', '),
          ),
          _InfoRow(
            theme,
            icon: Icons.calendar_today_outlined,
            title: 'Días Disponibles',
            value: profile.availability.trainingDays.isEmpty
                ? 'No especificado'
                : profile.availability.trainingDays.join(', '),
          ),
          _InfoRow(
            theme,
            icon: Icons.timer_outlined,
            title: 'Duración de Sesión',
            value: '${profile.availability.sessionMinutes} minutos',
          ),
          
          const SizedBox(height: 24),

          // --- 4. Sección "Historial" (Mis logros) ---
          if (profile.tournaments.isNotEmpty) ...[
            Text(
              'Historial de Torneos',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),
            ...profile.tournaments.map(
              (t) => ListTile(
                leading: Icon(Icons.emoji_events_outlined, color: theme.colorScheme.secondary),
                title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(t.date)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// --- MEJORA DE UX: "Empty State" Motivacional ---
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assessment_outlined, // Icono más relevante
                size: 80,
                color: theme.colorScheme.primary, // Color Volt
              ),
              const SizedBox(height: 24),
              Text(
                '¡Tu viaje comienza ahora!', // Header motivacional
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Completa tu evaluación inicial para desbloquear tu perfil, descubrir tus estadísticas y recibir tu plan de entrenamiento.', // El "Por qué"
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Completar Evaluación'),
                style: ElevatedButton.styleFrom(
                  // El botón ya usa el color 'primary' (Volt) del tema
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/player_evaluation');
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  /// --- NUEVO WIDGET: Tarjeta de Estadística para el Grid ---
  Widget _buildStatCard(ThemeData theme,
      {required String title, required String value, String? unit}) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary, // Volt
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.8),
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// --- NUEVO WIDGET: Fila de Información (para listas) ---
  Widget _InfoRow(ThemeData theme,
      {required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 20), // Azul Pro
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}