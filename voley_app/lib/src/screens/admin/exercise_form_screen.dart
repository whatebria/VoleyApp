import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/services.dart'; // Ya no es necesario
import 'package:voley_app/src/screens/admin/base/base_form_screen.dart';
// Ya no se usa el multi-selector, pero podrías re-implementarlo para 'tags' si lo deseas.
// import 'package:voley_app/src/widgets/firestore_multi_selector.dart';

class ExerciseFormScreen extends BaseFormScreen {
  ExerciseFormScreen({super.key, String? id, Map<String, dynamic>? existing})
      : super(
          // Apunta a la colección de ejercicios
          collectionRef: FirebaseFirestore.instance.collection('exercises'),
          id: id,
          existing: existing,
        );

  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends BaseFormScreenState<ExerciseFormScreen> {
  // --- Variables de Estado Locales (Alineadas con el Seeder) ---

  // Strings
  String name = '';
  String level = 'beginner'; // Valor por defecto
  String videoUrl = '';
  String equipment = '';
  String positionFocus = 'all'; // Valor por defecto

  // Controladores para listas (manejadas como texto separado por comas)
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _contraindicatedController = TextEditingController();

  @override
  void dispose() {
    // Limpieza de controladores
    _tagsController.dispose();
    _contraindicatedController.dispose();
    super.dispose();
  }

  @override
  String getScreenTitle() => "Agregar/Editar Ejercicio";

  @override
  void initializeData(Map<String, dynamic>? data) {
    if (data != null) {
      name = data['name'] ?? '';
      videoUrl = data['videoUrl'] ?? ''; // Campo de nivel superior
      equipment = data['equipment'] ?? '';

      // --- INICIO DE LA CORRECCIÓN PARA EL DROPDOWN 'level' ---
      // 1. Carga el valor de la base de datos (puede ser 'intermediate' o 'intermedio')
      level = data['level'] ?? 'beginner';

      // 2. Normaliza valores antiguos (español) a los nuevos valores (inglés)
      //    Esto da soporte a los datos creados con el formulario anterior.
      if (level == 'principiante') {
        level = 'beginner';
      } else if (level == 'intermedio') {
        level = 'intermediate';
      } else if (level == 'avanzado') {
        level = 'advanced';
      }
      // Si el valor ya es 'beginner', 'intermediate', o 'advanced' (del seeder),
      // se mantendrá y funcionará directamente con el Dropdown.
      // --- FIN DE LA CORRECCIÓN ---

      positionFocus = data['positionFocus'] ?? 'all';

      // Cargar listas y unirlas con ", " para mostrarlas en el TextField
      _tagsController.text = (List<String>.from(data['tags'] ?? [])).join(', ');
      _contraindicatedController.text =
          (List<String>.from(data['contraindicatedFor'] ?? [])).join(', ');
    }
  }

  @override
  Map<String, dynamic> buildDataMap() {
    // Función auxiliar para procesar los campos de texto de tags/contra
    List<String> _processTags(TextEditingController controller) {
      return controller.text
          .split(',') // Separa por comas
          .map((t) => t.trim()) // Quita espacios en blanco
          .where((t) => t.isNotEmpty) // Elimina strings vacíos
          .toList();
    }

    return {
      'name': name,
      'videoUrl': videoUrl,
      'equipment': equipment,
      'level': level, // Guarda el valor en inglés (ej. "intermediate")
      'positionFocus': positionFocus,

      // Convertir texto de controllers a List<String>
      'tags': _processTags(_tagsController),
      'contraindicatedFor': _processTags(_contraindicatedController),
    };
  }

  @override
  List<Widget> buildFormFields(BuildContext context) {
    return [
      // --- Campos de Texto ---
      TextFormField(
        initialValue: name,
        decoration: const InputDecoration(labelText: "Nombre del Ejercicio"),
        validator: (v) => v!.isEmpty ? "Campo requerido" : null,
        onSaved: (v) => name = v!,
      ),
      TextFormField(
        initialValue: videoUrl,
        decoration: const InputDecoration(labelText: "URL de Video (YouTube)"),
        onSaved: (v) => videoUrl = v!,
      ),
      TextFormField(
        initialValue: equipment,
        decoration: const InputDecoration(labelText: "Equipamiento"),
        onSaved: (v) => equipment = v!,
      ),

      // --- Nivel ---
      DropdownButtonFormField(
        value: level, // El valor ya fue normalizado en initializeData
        decoration: const InputDecoration(labelText: "Nivel (Level)"),
        items: const [
          DropdownMenuItem(
              value: "beginner", child: Text("Beginner (Principiante)")),
          DropdownMenuItem(
              value: "intermediate", child: Text("Intermediate (Intermedio)")),
          DropdownMenuItem(
              value: "advanced", child: Text("Advanced (Avanzado)")),
        ],
        onChanged: (val) => setState(() => level = val!),
      ),

      // --- Foco por Posición ---
      DropdownButtonFormField(
        value: positionFocus,
        decoration: const InputDecoration(labelText: "Foco por Posición"),
        items: const [
          DropdownMenuItem(value: "all", child: Text("Todas (All)")),
          DropdownMenuItem(value: "setter", child: Text("Armadora (Setter)")),
          DropdownMenuItem(value: "middle", child: Text("Central (Middle)")),
          DropdownMenuItem(value: "opposite", child: Text("Opuesta (Opposite)")),
          DropdownMenuItem(value: "libero", child: Text("Líbero")),
          DropdownMenuItem(value: "outside", child: Text("Punta (Outside)")),
        ],
        onChanged: (val) => setState(() => positionFocus = val!),
      ),

      const Divider(height: 30),

      // --- Campos de Listas (como texto) ---
      TextFormField(
        controller: _tagsController,
        decoration: const InputDecoration(
          labelText: "Tags (etiquetas)",
          hintText: "strength, lower_body, power...",
          helperText: "Separar con comas (,)",
        ),
      ),
      TextFormField(
        controller: _contraindicatedController,
        decoration: const InputDecoration(
          labelText: "Contraindicado Para",
          hintText: "knee_pain, low_back_pain...",
          helperText: "Separar con comas (,)",
        ),
      ),
    ];
  }
}

