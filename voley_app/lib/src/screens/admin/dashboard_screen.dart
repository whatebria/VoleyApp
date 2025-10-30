import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/models/athlete/athlete.dart';
import 'package:voley_app/src/screens/admin/athlete_detail_screen.dart';
import 'package:voley_app/src/screens/admin/athlete_form_screen.dart';
import 'package:voley_app/src/screens/admin/exercise_form_screen.dart';
import 'package:voley_app/src/screens/admin/base/generic_list_screen.dart';
import 'package:voley_app/src/screens/admin/injury_form_screen.dart';
import 'package:voley_app/src/screens/admin/objective_form_screen.dart';
import 'package:voley_app/src/screens/admin/progression_type_form_screen.dart';
import 'package:voley_app/src/screens/admin/test_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos la "configuración" para las colecciones de Recursos
    final resourceItems = [
      {
        "title": "Ejercicios",
        "collection": FirebaseFirestore.instance.collection('exercises'),
        "formBuilder": ({doc}) => ExerciseFormScreen(
          // Asume que ExerciseFormScreen extiende BaseFormScreen
          // y ha sido actualizado para tomar `doc`
          id: doc?.id,
          existing: doc?.data() as Map<String, dynamic>?,
        ),
        "titleBuilder": (data) => Text(data['name'] ?? ''),
        "subtitleBuilder": (data) => Text('Nivel: ${data['level'] ?? 'N/A'}'),
      },
      {
        "title": "Lesiones (Catálogo)",
        "collection": FirebaseFirestore.instance.collection('injuries'),
        "formBuilder": ({doc}) => InjuryFormScreen(
          id: doc?.id,
          existing: doc?.data() as Map<String, dynamic>?,
        ),
        "titleBuilder": (data) => Text(data['name'] ?? ''),
        "subtitleBuilder": (data) => Text('Duración: ${data['duration'] ?? 0} sem.'),
      },
      {
        "title": "Tipos de Progresión",
        "collection": FirebaseFirestore.instance.collection('progression_types'),
        "formBuilder": ({doc}) => ProgressionTypeFormScreen(
          id: doc?.id,
          existing: doc?.data() as Map<String, dynamic>?,
        ),
        "titleBuilder": (data) => Text(data['name'] ?? ''),
        "subtitleBuilder": (data) => Text(data['description'] ?? '', overflow: TextOverflow.ellipsis),
      },
      {
        "title": "Tests (Catálogo)",
        "collection": FirebaseFirestore.instance.collection('tests'),
        "formBuilder": ({doc}) => TestFormScreen(
          id: doc?.id,
          existing: doc?.data() as Map<String, dynamic>?,
        ),
        "titleBuilder": (data) => Text(data['name'] ?? ''),
        "subtitleBuilder": (data) => Text('Medida: ${data['measure'] ?? 'N/A'}'),
      },
      {
      "title": "Objetivos (Tags)",
      "collection": FirebaseFirestore.instance.collection('tags'),
      "formBuilder": ({doc}) => ObjectiveFormScreen(
        id: doc?.id,
        existing: doc?.data() as Map<String, dynamic>?,
      ),
      "titleBuilder": (data) => Text(data['name'] ?? ''),
      "subtitleBuilder": (data) => Text('Categoría: ${data['category'] ?? 'N/A'}'),
    },
    ];

    resourceItems.sort((a, b) => (a['title'] as String).compareTo(b['title'] as String));

    return Scaffold(
      appBar: AppBar(title: const Text("Panel de Administrador")),
      body: ListView(
        children: [
          // --- SECCIÓN 1: GESTIÓN DE ATLETAS ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Gestión de Atletas", style: Theme.of(context).textTheme.titleLarge),
          ),
          ListTile(
            title: const Text("Atletas"),
            subtitle: const Text("Gestionar perfiles, evaluaciones y programas"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GenericListScreen(
                    collectionRef: FirebaseFirestore.instance.collection('athletes'),
                    title: "Atletas",
                    fabLabel: "Nuevo",
                    formBuilder: ({doc}) => AthleteFormScreen(
                      athlete: doc != null ? Athlete.fromSnapshot(doc) : null,
                    ),
                    tileTitleBuilder: (data) => Text(data['name'] ?? 'Sin Nombre'),
                    tileSubtitleBuilder: (data) => Text(data['email'] ?? 'Sin Email'),
                    // Al tocar un atleta, vamos a sus detalles
                    onItemTap: (doc) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AthleteDetailScreen(athleteDoc: doc),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          const Divider(),

          // --- SECCIÓN 2: GESTIÓN DE RECURSOS ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Gestión de Recursos", style: Theme.of(context).textTheme.titleLarge),
          ),
          ...resourceItems.map((item) {
            return ListTile(
              title: Text(item["title"] as String),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GenericListScreen(
                      title: item["title"] as String,
                      collectionRef: item["collection"] as CollectionReference,
                      fabLabel: "Nuevo",
                      formBuilder: item["formBuilder"] as FormWidgetBuilder,
                      tileTitleBuilder: item["titleBuilder"] as TileContentBuilder,
                      tileSubtitleBuilder: item["subtitleBuilder"] as TileContentBuilder,
                      // No hay onItemTap, así que la acción por defecto es editar
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}