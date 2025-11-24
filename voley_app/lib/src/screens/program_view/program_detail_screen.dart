import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/mesocycle.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/screens/program_view/bloack_detail_screen.dart';
import 'package:voley_app/src/screens/program_view/create_block_screen.dart';

/// Muestra los Mesociclos (Bloques) de un Programa
// --- CAMBIO: Convertido a ConsumerWidget ---
class ProgramDetailScreen extends ConsumerWidget {
  final Program program;
  final PlayerProfile profile;

  const ProgramDetailScreen({
    super.key, 
    required this.program,
    required this.profile,
  });

  // --- AÑADIDO: Lógica para editar el título ---
  Future<void> _showTitleDialog(BuildContext context, WidgetRef ref, Program currentProgram) async {
    final newTitle = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => _ProgramTitleEditScreen(initialValue: currentProgram.title),
      ),

    );

    if (newTitle != null && newTitle != currentProgram.title) {
      // --- CAMBIO: Llama al provider para actualizar el estado ---
      ref.read(programEditorProvider.notifier).updateTitle(newTitle);
    }
  }
  
  // --- AÑADIDO: Navegación para Añadir Bloque ---
  void _navigateToAddBlock(BuildContext context, WidgetRef ref) async {
    final newMeso = await Navigator.push<Mesocycle>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBlockScreen(profile: profile),
      ),
    );

    if (newMeso != null) {
      // --- CAMBIO: Llama al provider para añadir el bloque ---
      ref.read(programEditorProvider.notifier).addBlock(newMeso);
    }
  }

  // --- AÑADIDO: Lógica de navegación para Editar Bloque ---
  void _navigateToEditBlock(BuildContext context, WidgetRef ref, Mesocycle mesoToEdit) async {
    final updatedMeso = await Navigator.push<Mesocycle>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBlockScreen(
          profile: profile,
          mesoToEdit: mesoToEdit, // <-- Pasa el bloque a editar
        ),
      ),
    );

    if (updatedMeso != null) {
      // --- CAMBIO: Llama al provider para actualizar el bloque ---
      ref.read(programEditorProvider.notifier).updateBlock(updatedMeso);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // --- CAMBIO: Observa el provider ---
    // Usamos `watch` para que la UI reaccione a los cambios.
    final programState = ref.watch(programEditorProvider);

    // --- CAMBIO: Lógica de inicialización ---
    // Si el estado del provider está vacío (o es un programa diferente),
    // lo inicializamos con el programa que nos pasaron.
    // Usamos un PostFrameCallback para no modificar el estado durante el build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(programEditorProvider) == null || ref.read(programEditorProvider)!.id != program.id) {
        ref.read(programEditorProvider.notifier).init(program, profile.id);
      }
    });

    // --- CAMBIO: Muestra un loader si el estado no está listo ---
    if (programState == null || programState.id != program.id) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // --- CAMBIO: Título reactivo ---
        title: Text(programState.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Título',
            onPressed: () => _showTitleDialog(context, ref, programState),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        // --- CAMBIO: Lista reactiva ---
        itemCount: programState.mesocycles.length,
        itemBuilder: (context, index) {
          final mesocycle = programState.mesocycles[index];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            color: theme.colorScheme.surface, // grisPro
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              leading: Icon(Icons.timeline, color: theme.colorScheme.secondary, size: 32), // azulPro
              title: Text(
                mesocycle.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text('${mesocycle.weeks} Semanas • Foco: ${mesocycle.focus}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- AÑADIDO: Botón de Editar Bloque ---
                  IconButton(
                    icon: Icon(Icons.edit, color: theme.colorScheme.secondary),
                    tooltip: 'Editar Bloque',
                    onPressed: () => _navigateToEditBlock(context, ref, mesocycle),
                  ),
                  // --- AÑADIDO: Botón de Eliminar Bloque ---
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    tooltip: 'Eliminar Bloque',
                    onPressed: () {
                      // Llama al provider para eliminar
                      ref.read(programEditorProvider.notifier).deleteBlock(mesocycle);
                    },
                  ),
                ],
              ),
              onTap: () {
                // Navega a BlockDetailScreen (esta pantalla no necesita ser modificada)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlockDetailScreen(
                      mesocycle: mesocycle,
                      profile: profile,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      // --- AÑADIDO: Floating Action Button ---
      floatingActionButton: FloatingActionButton(
        tooltip: 'Añadir Bloque',
        onPressed: () => _navigateToAddBlock(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProgramTitleEditScreen extends StatefulWidget {
  final String initialValue;

  const _ProgramTitleEditScreen({required this.initialValue});

  @override
  State<_ProgramTitleEditScreen> createState() => _ProgramTitleEditScreenState();
}

class _ProgramTitleEditScreenState extends State<_ProgramTitleEditScreen> {
  late final TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Nombre del Programa')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre del Programa'),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _titleCtrl.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
