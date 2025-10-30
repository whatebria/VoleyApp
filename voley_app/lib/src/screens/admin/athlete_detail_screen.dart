// lib/screens/admin/athlete_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/models/athlete/athlete.dart';
import 'package:voley_app/src/models/evaluation.dart';
import 'package:voley_app/src/screens/admin/base/generic_list_screen.dart';
import 'package:voley_app/src/screens/admin/evaluation_form_screen.dart';
// (Importa los formularios de Program y Session cuando los tengas)
// import 'package:voley_app/src/screens/admin/forms/program_form_screen.dart';
// import 'package:voley_app/src/screens/admin/forms/session_form_screen.dart';

class AthleteDetailScreen extends StatelessWidget {
  final DocumentSnapshot athleteDoc;
  final Athlete athlete;

  // Recibe el snapshot del atleta y lo parsea
  AthleteDetailScreen({super.key, required this.athleteDoc})
      : athlete = Athlete.fromSnapshot(athleteDoc);

  @override
  Widget build(BuildContext context) {
    // Referencias a las sub-colecciones
    final evaluationsRef = athleteDoc.reference.collection('evaluations');
    final programsRef = athleteDoc.reference.collection('programs');
    final sessionsRef = athleteDoc.reference.collection('sessions');

    return Scaffold(
      appBar: AppBar(title: Text(athlete.name)),
      body: ListView(
        children: [
          // --- SECCIÓN DE INFORMACIÓN PERSONAL ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("Información Personal", style: Theme.of(context).textTheme.titleLarge),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(athlete.email),
            subtitle: const Text("Email"),
          ),
          ListTile(
            leading: const Icon(Icons.cake),
            title: Text(athlete.birthDate),
            subtitle: const Text("Fecha de Nacimiento"),
          ),
          ListTile(
            leading: const Icon(Icons.accessibility),
            title: Text("${athlete.height} m / ${athlete.weight} kg"),
            subtitle: const Text("Altura / Peso"),
          ),
          ListTile(
            leading: const Icon(Icons.sports_volleyball),
            title: Text(athlete.position),
            subtitle: const Text("Posición"),
          ),
          ListTile(
            leading: const Icon(Icons.star_border),
            title: Text(athlete.level),
            subtitle: const Text("Nivel"),
          ),
          
          // --- SECCIÓN DE PLANIFICACIÓN ---
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("Planificación", style: Theme.of(context).textTheme.titleLarge),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_view_week),
            title: Text("${athlete.availability.daysPerWeek} días por semana"),
            subtitle: Text("Disponibilidad: ${athlete.availability.preferredDays.join(', ')}"),
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: Text(athlete.goals.join(', ')),
            subtitle: const Text("Metas"),
          ),
          ListTile(
            leading: const Icon(Icons.priority_high),
            title: Text(athlete.priority),
            subtitle: const Text("Prioridad Actual"),
          ),
          
          // --- ESTADO ACTUAL ---
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("Estado Actual", style: Theme.of(context).textTheme.titleLarge),
          ),
          ListTile(
            leading: const Icon(Icons.run_circle_outlined),
            title: Text(athlete.currentPhase),
            subtitle: Text("Fase Actual (Programa: ${athlete.currentProgramId})"),
          ),
          ListTile(
            leading: const Icon(Icons.healing),
            title: Text(athlete.injuries.isEmpty 
              ? "Sin lesiones activas" 
              : athlete.injuries.map((e) => "${e.type} (${e.status})").join(', ')),
            subtitle: const Text("Lesiones"),
          ),
          if (athlete.hasTournamentSoon)
            ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.orange),
              title: const Text("Torneo Próximo"),
              subtitle: Text("Fecha: ${athlete.tournamentDate}"),
            ),
          
          // --- NAVEGACIÓN A SUB-COLECCIONES ---
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("Gestión", style: Theme.of(context).textTheme.titleLarge),
          ),
          ListTile(
            title: const Text("Gestionar Evaluaciones"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GenericListScreen(
                  collectionRef: evaluationsRef,
                  title: "Evaluaciones de ${athlete.name}",
                  fabLabel: "Nueva",
                  formBuilder: ({doc}) => EvaluationFormScreen(
                    collectionRef: evaluationsRef,
                    evaluation: doc != null ? Evaluation.fromSnapshot(doc) : null,
                  ),
                  tileTitleBuilder: (data) => Text("Fecha: ${data['date'] ?? 'N/A'}"),
                  tileSubtitleBuilder: (data) => Text("Prioridad: ${data['generatedPriority'] ?? 'N/A'}"),
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text("Programas"),
            trailing: const Icon(Icons.calendar_month),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GenericListScreen(
                  collectionRef: programsRef,
                  title: "Programas de ${athlete.name}",
                  fabLabel: "Nuevo",
                  formBuilder: ({doc}) {
                    // DEBES CREAR ESTE FORMULARIO
                    // return ProgramFormScreen(
                    //   collectionRef: programsRef,
                    //   program: doc != null ? Program.fromSnapshot(doc) : null,
                    // );
                    return const Scaffold(body: Center(child: Text("ProgramFormScreen no implementado")));
                  },
                  tileTitleBuilder: (data) => Text("Prioridad: ${data['priority'] ?? 'N/A'}"),
                  tileSubtitleBuilder: (data) => Text("Estado: ${data['status'] ?? 'N/A'}"),
                ),
              ),
            ),
          ),
          
          ListTile(
            title: const Text("Sesiones"),
            trailing: const Icon(Icons.fitness_center),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GenericListScreen(
                  collectionRef: sessionsRef,
                  title: "Sesiones de ${athlete.name}",
                  fabLabel: "Nueva",
                  formBuilder: ({doc}) {
                    // DEBES CREAR ESTE FORMULARIO
                    // return SessionFormScreen(
                    //   collectionRef: sessionsRef,
                    //   session: doc != null ? Session.fromSnapshot(doc) : null,
                    // );
                    return const Scaffold(body: Center(child: Text("SessionFormScreen no implementado")));
                  },
                  tileTitleBuilder: (data) => Text("Foco: ${data['focus'] ?? 'N/A'}"),
                  tileSubtitleBuilder: (data) => Text("Fecha: ${data['date'] ?? 'N/A'}"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}