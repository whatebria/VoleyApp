// lib/screens/program_view_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';

class ProgramViewScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prog = ref.watch(generatedProgramProvider);
    if (prog == null) {
      return Scaffold(appBar: AppBar(title: Text('Programa')), body: Center(child: Text('No hay programa generado')));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Programa: ${prog.id}')),
      body: ListView.builder(
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
                  // abrir detalle de la semana
                  showModalBottomSheet(context: context, builder: (_) {
                    return ListView(
                      children: mc.sessions.map((s) {
                        return ListTile(
                          title: Text('${s.day} — ${s.objective}'),
                          subtitle: Text('Carga: ${s.load} — Ejercicios: ${s.exercises.map((e) => e.name).join(', ')}'),
                        );
                      }).toList(),
                    );
                  });
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
