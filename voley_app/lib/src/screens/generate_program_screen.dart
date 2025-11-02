// lib/screens/generate_program_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';

class GenerateProgramScreen extends ConsumerWidget {
  const GenerateProgramScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observamos el provider. Su valor es un AsyncValue.
    final profileAsync = ref.watch(playerProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Generador Automático')),
      body: Center(
        // 2. Usamos .when() para reaccionar a los diferentes estados
        child: profileAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, s) => Text('Error al cargar el perfil: $e'),
          data: (profile) {
            // 3. Manejamos el caso donde el perfil (data) es nulo
            //    (p.ej., un jugador logueado sin evaluación)
            if (profile == null) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No se encontró tu perfil de jugador. '
                  'Por favor, completa tu evaluación primero.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            // 4. Si profile NO es nulo, mostramos el botón.
            //    Pasamos el objeto 'profile' válido.
            return _GenerateButtonView(profile: profile);
          },
        ),
      ),
    );
  }
}

/// Widget auxiliar para separar la lógica del botón.
/// Solo se renderiza cuando sabemos que tenemos un perfil válido.
class _GenerateButtonView extends ConsumerWidget {
  final PlayerProfile profile;

  const _GenerateButtonView({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 5. Leemos la acción (solo la necesitamos al presionar)
    final generateAction = ref.read(programGeneratorAction);
    
    // 6. [REFACTOR] Observamos el estado de carga que ya tenías
    //    definido en tus providers.
    final isGenerating = ref.watch(isGeneratingProgramProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Generar programa para ${profile.name}'),
        const SizedBox(height: 12),
        ElevatedButton(
          // 7. Deshabilitamos el botón si 'isGenerating' es true
          onPressed: isGenerating
              ? null
              : () async {
                  // 8. Ponemos el estado de carga en true
                  ref.read(isGeneratingProgramProvider.notifier).state = true;

                  try {
                    // 9. [CORREGIDO] Pasamos el objeto 'profile' (no el AsyncValue)
                    await generateAction(profile);

                    // 10. Navegamos a la pantalla del programa.
                    //     Usamos 'pushReplacement' para que el usuario no
                    //     pueda "volver" a la pantalla de generar.
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/program');
                    }
                  } catch (e) {
                    // Muestra un error si la Cloud Function falló
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al generar: $e')),
                      );
                    }
                  } finally {
                    // 11. Siempre ponemos el estado de carga en false al terminar
                    ref.read(isGeneratingProgramProvider.notifier).state = false;
                  }
                },
          // 12. Mostramos un indicador de carga dentro del botón
          child: isGenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Generar'),
        ),
      ],
    );
  }
}