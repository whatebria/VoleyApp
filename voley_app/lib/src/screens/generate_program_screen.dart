// lib/screens/generate_program_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';

class GenerateProgramScreen extends ConsumerWidget {
  const GenerateProgramScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Solo necesitamos el perfil y la acción
    final profile = ref.watch(playerProfileProvider);
    final generateAction = ref.read(programGeneratorAction);

    return Scaffold(
      appBar: AppBar(title: const Text('Generador Automático')),
      body: Center(
        child: profile == null
            ? const Text('Por favor completa la evaluación primero')
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Generar programa para ${profile.name}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      // Muestra un indicador de carga MIENTRAS se dispara la función
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => 
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        // 2. Llama a la Cloud Function SÓLO con el perfil
                        //    No se pasan ejercicios.
                        await generateAction(profile);

                        // Cierra el indicador de carga
                        if (context.mounted) Navigator.pop(context); 
                        
                        // 3. Navega a la pantalla del programa.
                        //    El StreamProvider se encargará de mostrar la carga allí.
                        if (context.mounted) Navigator.pushNamed(context, '/program');

                      } catch (e) {
                         // Cierra el indicador de carga
                        if (context.mounted) Navigator.pop(context); 
                        // Muestra un error si la Cloud Function falló
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al generar: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Generar'),
                  ),
                ],
              ),
      ),
    );
  }
}