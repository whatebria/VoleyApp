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
    // --- MEJORA: Definimos los "resourceItems" con iconos ---
    final resourceItems = [
      {
        "title": "Ejercicios",
        "icon": Icons.fitness_center_outlined, // <-- ICONO
        "collection": FirebaseFirestore.instance.collection('exercises'),
        "formBuilder": ({doc}) => ExerciseFormScreen(
          id: doc?.id,
          existing: doc?.data() as Map<String, dynamic>?,
        ),
        "titleBuilder": (data) => Text(data['name'] ?? ''),
        "subtitleBuilder": (data) => Text('Nivel: ${data['level'] ?? 'N/A'}'),
      },
      {
        "title": "Lesiones (Catálogo)",
        "icon": Icons.medical_services_outlined, // <-- ICONO
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
        "icon": Icons.auto_graph_outlined, // <-- ICONO
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
        "icon": Icons.rule_outlined, // <-- ICONO
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
        "icon": Icons.label_outline, // <-- ICONO
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
      appBar: AppBar(
        title: const Text("Panel de Administrador"),
        // --- MEJORA: AppBar más limpia ---
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        // --- MEJORA: Padding general ---
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          // --- SECCIÓN 1: GESTIÓN DE ATLETAS ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
            child: Text("Gestión de Atletas",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          
          // --- MEJORA: ListTile envuelto en Card ---
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              // --- MEJORA: Icono ---
              leading: Icon(
                Icons.people_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              title: const Text("Atletas"),
              subtitle: const Text("Gestionar perfiles, evaluaciones y programas"),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey[600],
              ),
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
                      // --- MEJORA: Añadimos un leading a la lista de atletas ---
                      tileLeadingBuilder: (data) => CircleAvatar(
                        child: Text(data['name']?.substring(0, 1) ?? '?'),
                      ),
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
          ),
          
          const SizedBox(height: 24), // --- MEJORA: Más espacio entre secciones

          // --- SECCIÓN 2: GESTIÓN DE RECURSOS ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
            child: Text("Gestión de Recursos",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          
          // --- MEJORA: Card que agrupa todos los items de recursos ---
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              // --- MEJORA: Añade divisores automáticamente ---
              children: ListTile.divideTiles(
                context: context,
                tiles: resourceItems.map((item) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    // --- MEJORA: Icono ---
                    leading: Icon(
                      item["icon"] as IconData,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    title: Text(item["title"] as String),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.grey[600],
                    ),
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
                          ),
                        ),
                      );
                    },
                  );
                }),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}