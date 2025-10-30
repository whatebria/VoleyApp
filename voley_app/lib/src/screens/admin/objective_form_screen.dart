// lib/screens/admin/forms/objective_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/screens/admin/base/base_form_screen.dart';

class ObjectiveFormScreen extends BaseFormScreen {
  ObjectiveFormScreen({super.key, String? id, Map<String, dynamic>? existing})
      : super(
          collectionRef: FirebaseFirestore.instance.collection('tags'),
          id: id,
          existing: existing,
        );

  @override
  State<ObjectiveFormScreen> createState() => _ObjectiveFormScreenState();
}

class _ObjectiveFormScreenState extends BaseFormScreenState<ObjectiveFormScreen> {
  String name = '';
  String description = '';
  String category = 'General'; // Valor por defecto

  @override
  String getScreenTitle() => "Objetivo";

  @override
  void initializeData(Map<String, dynamic>? data) {
    if (data != null) {
      name = data['name'] ?? '';
      description = data['description'] ?? '';
      category = data['category'] ?? 'General';
    }
  }

  @override
  Map<String, dynamic> buildDataMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
    };
  }

  @override
  List<Widget> buildFormFields(BuildContext context) {
    return [
      TextFormField(
        initialValue: name,
        decoration: const InputDecoration(labelText: "Nombre del Objetivo"),
        validator: (v) => v!.isEmpty ? "Campo requerido" : null,
        onSaved: (v) => name = v!,
      ),
      TextFormField(
        initialValue: category,
        decoration: const InputDecoration(labelText: "Categoría (ej. Físico, Técnico)"),
        onSaved: (v) => category = v!,
      ),
      TextFormField(
        initialValue: description,
        decoration: const InputDecoration(labelText: "Descripción"),
        maxLines: 3,
        onSaved: (v) => description = v!,
      ),
    ];
  }
}