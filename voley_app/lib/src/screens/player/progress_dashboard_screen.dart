// lib/screens/progress_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// (Importa tus providers y modelos)
// import 'package:voley_app/providers.dart'; 
// (Importa un paquete de gráficos)
// import 'package:fl_chart/fl_chart.dart';

class ProgressDashboardScreen extends ConsumerWidget {
  const ProgressDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Asumimos que el provider nos da el perfil (con historial)
    // final profileAsync = ref.watch(playerProfileProvider);
    final theme = Theme.of(context);

    // Esta pantalla DEBE tener su propio Scaffold
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Progreso'),
      ),
      // Usamos un ListView para el dashboard escaneable
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Tarjeta 1: El Héroe
          _buildHeroCard(context, theme, 'Salto Vertical', '42.5 cm', '+1.5 cm'),
          const SizedBox(height: 16),
          
          // Tarjeta 2: Adherencia
          _buildAdherenceCard(context, theme, 3, 5),
          const SizedBox(height: 16),

          // Tarjeta 3: Gráficos de Métricas
          _buildMetricsChartCard(context, theme),
          const SizedBox(height: 16),

          // Tarjeta 4: Récords Personales
          _buildPersonalBestsCard(context, theme),

          // (Opcional: Tarjeta de Objetivos)
        ],
      ),
    );
  }

  /// 1. El Héroe de Progreso (El Gancho)
  Widget _buildHeroCard(BuildContext context, ThemeData theme, String metric,
      String value, String change) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  change,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: Colors.greenAccent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Aquí iría el mini-gráfico (Sparkline)
            Container(
              height: 50,
              alignment: Alignment.center,
              child: Text(
                '[Sparkline Chart Placeholder]',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
              // child: LineChart(...), // (de fl_chart)
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Adherencia Semanal (La Tarea Inmediata)
  Widget _buildAdherenceCard(
      BuildContext context, ThemeData theme, int completed, int total) {
    final progress = (total > 0) ? (completed / total) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adherencia Semanal',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completed de $total entrenamientos completados',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Gráficos de Métricas Clave (La Prueba)
  Widget _buildMetricsChartCard(BuildContext context, ThemeData theme) {
    // Esta tarjeta tendría su propio State (TickerProvider) para el TabBar
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolución de Métricas',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Aquí iría el TabBar + TabBarView
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Text(
                '[TabBar + Line Charts Placeholder]',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
              // child: ... (DefaultTabController con LineCharts)
            ),
          ],
        ),
      ),
    );
  }

  /// 5. Récords Personales (La Vitrina)
  Widget _buildPersonalBestsCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Récords Personales (PBs)',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Estos serían generados dinámicamente
            _buildPBRow(
                theme, 'Salto Vertical Máx.', '82.5 cm', '04/11/2025'),
            const Divider(height: 16),
            _buildPBRow(
                theme, 'T-Test Mínimo', '9.1 seg', '01/11/2025'),
            const Divider(height: 16),
            _buildPBRow(
                theme, 'Velocidad 20m', '2.7 seg', '01/11/2025'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPBRow(ThemeData theme, String metric, String value, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(metric, style: theme.textTheme.bodyLarge),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                date,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}