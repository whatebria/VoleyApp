// lib/screens/admin/forms/injury_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:voley_app/src/screens/admin/base/base_form_screen.dart';
import 'package:voley_app/src/widgets/firestore_multi_selector.dart';

class InjuryFormScreen extends BaseFormScreen {
  InjuryFormScreen({super.key, super.id, super.existing})
      : super(
          collectionRef: FirebaseFirestore.instance.collection('injuries'),
        );

  @override
  State<InjuryFormScreen> createState() => _InjuryFormScreenState();
}

class _InjuryFormScreenState extends BaseFormScreenState<InjuryFormScreen> {
  // --- Variables locales (adaptadas al modelo simple) ---
  String name = '';
  String notes = '';
  
  // Controlador para el número (duration)
  final TextEditingController _durationController = TextEditingController();

  // Listas de IDs (usando los nombres del modelo)
  List<String> excludeTags = [];
  List<String> recommendTags = [];

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  @override
  String getScreenTitle() => "Agregar/Editar Lesión";

  @override
  void initializeData(Map<String, dynamic>? data) {
    if (data != null) {
      name = data['name'] ?? '';
      notes = data['notes'] ?? ''; // Campo 'notes' del modelo
      _durationController.text = data['duration']?.toString() ?? '0'; // Campo 'duration' del modelo
      
      // Carga las listas de IDs (usando los nombres del modelo)
      excludeTags = List<String>.from(data['excludeTags'] ?? []);
      recommendTags = List<String>.from(data['recommendTags'] ?? []);
    }
  }

  @override
  Map<String, dynamic> buildDataMap() {
    return {
      'name': name,
      'notes': notes,
      'duration': int.tryParse(_durationController.text) ?? 0,
      'excludeTags': excludeTags,
      'recommendTags': recommendTags,
    };
  }

  @override
  List<Widget> buildFormFields(BuildContext context) {
    return [
      TextFormField(
        initialValue: name,
        decoration: const InputDecoration(labelText: "Nombre de la Lesión"),
        validator: (v) => v!.isEmpty ? "Campo requerido" : null,
        onSaved: (v) => name = v!,
      ),
      
      // Campo 'notes' (String)
      TextFormField(
        initialValue: notes,
        decoration: const InputDecoration(labelText: "Notas"),
        maxLines: 3,
        onSaved: (v) => notes = v!,
      ),
      
      // Campo 'duration' (int)
      TextFormField(
        controller: _durationController,
        decoration: const InputDecoration(labelText: "Duración (semanas)"),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      
      const Divider(height: 30),

      // --- Selectores de Tags ---
      // (Asumiendo que 'excludeTags' y 'recommendTags' siguen siendo IDs 
      // de la colección 'objectives' como en nuestra arquitectura)

      FirestoreMultiSelector(
        label: "Tags a Excluir (Qué evitar)",
        collectionRef: FirebaseFirestore.instance.collection('tags'),
        filterCategory: "Condición", // Asigna la categoría correcta
        selectedIds: excludeTags,
        onUpdate: (newList) => setState(() => excludeTags = newList),
      ),
      
      FirestoreMultiSelector(
        label: "Tags Recomendados (Priorizar)",
        collectionRef: FirebaseFirestore.instance.collection('tags'),
        filterCategory: "Terapéutico", // Asigna la categoría correcta
        selectedIds: recommendTags,
        onUpdate: (newList) => setState(() => recommendTags = newList),
      ),
    ];
  }
}