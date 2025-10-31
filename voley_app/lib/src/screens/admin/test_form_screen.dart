// lib/screens/admin/forms/test_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/screens/admin/base/base_form_screen.dart';
import 'package:voley_app/src/widgets/firestore_multi_selector.dart';

class TestFormScreen extends BaseFormScreen {
  TestFormScreen({super.key, super.id, super.existing})
      : super(
          collectionRef: FirebaseFirestore.instance.collection('tests'),
        );

  @override
  State<TestFormScreen> createState() => _TestFormScreenState();
}

class _TestFormScreenState extends BaseFormScreenState<TestFormScreen> {
  // --- Variables locales (adaptadas al modelo) ---
  String name = '';
  String description = '';
  String measure = '';
  String objective = '';
  List<String> recommendedTags = []; // IDs de 'objectives'

  @override
  String getScreenTitle() => "Agregar/Editar Test";

  @override
  void initializeData(Map<String, dynamic>? data) {
    if (data != null) {
      name = data['name'] ?? '';
      description = data['description'] ?? '';
      measure = data['measure'] ?? '';
      objective = data['objective'] ?? '';
      recommendedTags = List<String>.from(data['recommendedTags'] ?? []);
    }
  }

  @override
  Map<String, dynamic> buildDataMap() {
    return {
      'name': name,
      'description': description,
      'measure': measure,
      'objective': objective,
      'recommendedTags': recommendedTags,
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
        initialValue: description,
        decoration: const InputDecoration(labelText: "Descripción"),
        maxLines: 3,
        onSaved: (v) => description = v!,
      ),
      TextFormField(
        initialValue: measure,
        decoration: const InputDecoration(labelText: "Medida (cm, s, kg)"),
        onSaved: (v) => measure = v!,
      ),
      TextFormField(
        initialValue: objective,
        decoration: const InputDecoration(labelText: "Objetivo del Test"),
        maxLines: 2,
        onSaved: (v) => objective = v!,
      ),

      const SizedBox(height: 16),

      // Selector para 'recommendedTags' (Qué mejorar)
      FirestoreMultiSelector(
        label: "Tags Recomendados (Qué mejorar)",
        // Apunta a la colección correcta de 'objectives'
        collectionRef: FirebaseFirestore.instance.collection('tags'),
        filterCategory: "Rendimiento Físico", // O la categoría que corresponda
        selectedIds: recommendedTags,
        onUpdate: (newList) => setState(() => recommendedTags = newList),
      ),
    ];
  }
}