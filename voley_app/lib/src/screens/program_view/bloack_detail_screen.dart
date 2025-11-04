import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importado para ConsumerStatefulWidget
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/mesocycles.dart';
import 'package:voley_app/src/models/program/microcicle.dart';
import 'package:voley_app/src/screens/program_view/week_detail_screen.dart'; // Importa la siguiente pantalla
import 'package:voley_app/src/screens/program_view/create_block_screen.dart'; // Importa la pantalla de edición

/// Muestra los Microciclos (Semanas) de un Mesociclo (Bloque)
/// AÑADIDO: Convertido a ConsumerStatefulWidget para manejar la edición
class BlockDetailScreen extends ConsumerStatefulWidget {
  final Mesocycle mesocycle;
  final PlayerProfile profile;

  const BlockDetailScreen({
    super.key,
    required this.mesocycle,
    required this.profile,
  });

  @override
  _BlockDetailScreenState createState() => _BlockDetailScreenState();
}

class _BlockDetailScreenState extends ConsumerState<BlockDetailScreen> {
  // --- AÑADIDO: Estado local para el mesociclo ---
  // Esto permite que la pantalla se actualice si el bloque es editado
  late Mesocycle _currentMeso;

  @override
  void initState() {
    super.initState();
    _currentMeso = widget.mesocycle;
  }

  // --- AÑADIDO: Navegación para Editar el Bloque ---
  void _navigateToEditBlock(BuildContext context) async {
    final updatedMeso = await Navigator.push<Mesocycle>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBlockScreen(
          profile: widget.profile,
          mesoToEdit: _currentMeso, // <-- Pasa el bloque a editar
        ),
      ),
    );

    if (updatedMeso != null && mounted) {
      // Actualiza la UI de esta pantalla con los datos modificados
      setState(() {
        _currentMeso = updatedMeso;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        // --- CAMBIO: Título usa el estado local ---
        title: Text(_currentMeso.name),
        actions: [
          // --- AÑADIDO: Botón de Editar ---
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Bloque',
            onPressed: () => _navigateToEditBlock(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Mostrar el objetivo del bloque
          // --- CAMBIO: Usa el estado local ---
          if (_currentMeso.objective.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OBJETIVO DEL BLOQUE:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary.withOpacity(0.8) // voltNeon
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentMeso.objective,
                    style: theme.textTheme.bodyMedium
                  ),
                ],
              ),
            ),
          
          // Título de la lista de semanas
          Text(
            'Semanas',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),

          // Lista de Semanas (Microciclos)
          // --- CAMBIO: Usa el estado local ---
          ..._currentMeso.microcycles.map((micro) {
            return _buildMicrocycleTile(context, theme, micro, widget.profile);
          })
        ],
      ),
    );
  }

  /// Construye el ListTile para una Semana (Microciclo)
  Widget _buildMicrocycleTile(
    BuildContext context, 
    ThemeData theme, 
    Microcycle micro,
    PlayerProfile profile,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: theme.colorScheme.surface, // grisPro
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondary, // azulPro
          foregroundColor: theme.colorScheme.onSecondary, // blancoNeutro
          radius: 15,
          child: Text(
            '${micro.weekNumber}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('Semana ${micro.weekNumber}'),
        subtitle: Text('${micro.sessions.length} sesiones'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navega a la pantalla de detalle de la semana
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WeekDetailScreen(
                microcycle: micro,
                profile: profile, // Pasa el perfil
              ),
            ),
          );
        },
      ),
    );
  }
}

