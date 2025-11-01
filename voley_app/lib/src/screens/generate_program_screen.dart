// lib/screens/generate_program_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';

class GenerateProgramScreen extends ConsumerWidget {
  const GenerateProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Ya no necesitamos 'exercisesAsync'
    final profile = ref.watch(playerProfileProvider);
    final generateAction = ref.read(programGeneratorAction);

    return Scaffold(
      appBar: AppBar(title: const Text('Generador Automático')),
      body: Center(
        child: profile == null
            // 2. Si no hay perfil, mostramos el error
            ? Text('Por favor completa la evaluación primero')
            
            // 3. Si hay perfil, mostramos el botón. 
            //    Ya no necesitamos el .when() de 'exercisesAsync'
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Generar programa para ${profile.name}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      // Muestra un indicador de carga
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => 
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        // 4. Llama a la acción SÓLO con el perfil
                        //    La Cloud Function se encarga del resto.
                        await generateAction(profile);

                        // Cierra el indicador de carga
                        Navigator.pop(context); 
                        
                        // 5. Navega a la pantalla del programa.
                        //    El StreamProvider se encargará de mostrar la carga.
                        Navigator.pushNamed(context, '/program');

                      } catch (e) {
                         // Cierra el indicador de carga
                        Navigator.pop(context); 
                        // Muestra un error si la Cloud Function falló
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al generar: $e')),
                        );
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