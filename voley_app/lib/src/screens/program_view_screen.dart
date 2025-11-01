// lib/screens/program_view_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';

class ProgramViewScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 'progAsync' ahora es un AsyncValue<Program?>
    final progAsync = ref.watch(generatedProgramProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Programa')),
      // 2. Usamos .when() para manejar los 3 estados del StreamProvider
      body: progAsync.when(
        
        // --- Estado de Carga ---
        // Esto se mostrará mientras la Cloud Function trabaja
        // y Firestore aún no tiene el programa.
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Generando tu programa en la nube...'),
            ],
          ),
        ),

        // --- Estado de Error ---
        error: (e, s) => Center(child: Text('Error al cargar el programa: $e')),
        
        // --- Estado de Datos (Éxito) ---
        data: (prog) {
          // 3. 'prog' es el objeto Program? (puede ser nulo)
          if (prog == null) {
            return const Center(child: Text('No hay programa generado'));
          }

          // 4. A partir de aquí, tu lógica de UI original es válida
          return ListView.builder(
            itemCount: prog.mesocycles.length,
            itemBuilder: (context, i) {
              final m = prog.mesocycles[i];
              return ExpansionTile(
                title: Text('${m.name} — ${m.weeks} semanas — ${m.focus}'),
                children: m.microcycles.map((mc) {
                  return ListTile(
                    title: Text('Semana ${mc.weekNumber}'),
                    subtitle: Text('Sesiones: ${mc.sessions.length}'),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) {
                          return ListView(
                            children: mc.sessions.map((s) {
                              return ListTile(
                                title: Text('${s.day} — ${s.objective}'),
                                // 5. Corregí esto para que use 's.exercises.map'
                                subtitle: Text(
                                    'Carga: ${s.load} — Ej: ${s.exercises.map((e) => e.name).join(', ')}'),
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}