// lib/screens/admin/forms/test_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/screens/admin/base/base_form_screen.dart';
import 'package:voley_app/src/widgets/firestore_multi_selector.dart';

class TestFormScreen extends BaseFormScreen {
  TestFormScreen({super.key, String? id, Map<String, dynamic>? existing})
      : super(
          collectionRef: FirebaseFirestore.instance.collection('tests'),
          id: id,
          existing: existing,
        );

  @override
  State<TestFormScreen> createState() => _TestFormScreenState();
}

class _TestFormScreenState extends BaseFormScreenState<TestFormScreen> {
  // --- Variables locales ---
  String name = '';
  String instructions = '';
  String measure = '';
  String good = '';
  String average = '';
  String weak = '';
  List<String> measuresObjectiveIds = [];
  List<String> improvementObjectiveIds = [];

  @override
  String getScreenTitle() => "Agregar/Editar Test";

  @override
  void initializeData(Map<String, dynamic>? data) {
    if (data != null) {
      name = data['name'] ?? '';
      instructions = data['instructions'] ?? '';
      measure = data['measure'] ?? '';
      good = data['good'] ?? '';
      average = data['average'] ?? '';
      weak = data['weak'] ?? '';
      measuresObjectiveIds = List<String>.from(data['measuresObjectiveIds'] ?? []);
      improvementObjectiveIds = List<String>.from(data['improvementObjectiveIds'] ?? []);
    }
  }

  @override
  Map<String, dynamic> buildDataMap() {
    return {
      'name': name,
      'instructions': instructions,
      'measure': measure,
      'good': good,
      'average': average,
      'weak': weak,
      'measuresObjectiveIds': measuresObjectiveIds,
      'improvementObjectiveIds': improvementObjectiveIds,
    };
  }

  @override
  List<Widget> buildFormFields(BuildContext context) {
    return [
      TextFormField(
        initialValue: name,
        decoration: const InputDecoration(labelText: "Nombre"),
        validator: (v) => v!.isEmpty ? "Campo requerido" : null,
        onSaved: (v) => name = v!,
      ),
      TextFormField(
        initialValue: instructions,
        decoration: const InputDecoration(labelText: "Instrucciones"),
        maxLines: 8,
        onSaved: (v) => instructions = v!,
      ),
      TextFormField(
        initialValue: measure,
        decoration: const InputDecoration(labelText: "Medida (cm, s, kg)"),
        onSaved: (v) => measure = v!,
      ),
      TextFormField(
        initialValue: good,
        decoration: const InputDecoration(labelText: "Resultado Bueno"),
        onSaved: (v) => good = v!,
      ),
      TextFormField(
        initialValue: average,
        decoration: const InputDecoration(labelText: "Resultado Promedio"),
        onSaved: (v) => average = v!,
      ),
      TextFormField(
        initialValue: weak,
        decoration: const InputDecoration(labelText: "Resultado Débil"),
        onSaved: (v) => weak = v!,
      ),

      // --- 5. Añadir widgets de chips ---
      const SizedBox(height: 16),
      FirestoreMultiSelector(
        label: "Qué Mide (Objetivos)",
        collectionRef: FirebaseFirestore.instance.collection('tags'),
        filterCategory: "Rendimiento Físico", // <-- FILTRO
        selectedIds: measuresObjectiveIds,
        onUpdate: (newList) => setState(() => measuresObjectiveIds = newList),
      ),

      FirestoreMultiSelector(
        label: "Qué Mejorar (Objetivos)",
        collectionRef: FirebaseFirestore.instance.collection('tags'),
        filterCategory: "Rendimiento Físico", // <-- FILTRO
        selectedIds: improvementObjectiveIds,
        onUpdate: (newList) => setState(() => improvementObjectiveIds = newList),
      ),
    ];
  }
}