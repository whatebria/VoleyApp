// lib/screens/admin/forms/progression_type_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/screens/admin/base/base_form_screen.dart';

class ProgressionTypeFormScreen extends BaseFormScreen {
  ProgressionTypeFormScreen({super.key, String? id, Map<String, dynamic>? existing})
      : super(
          collectionRef: FirebaseFirestore.instance.collection('progression_types'),
          id: id,
          existing: existing,
        );

  @override
  State<ProgressionTypeFormScreen> createState() => _ProgressionTypeFormScreenState();
}

class _ProgressionTypeFormScreenState extends BaseFormScreenState<ProgressionTypeFormScreen> {
  String name = '';
  String description = '';

  @override
  String getScreenTitle() => "Tipo de Progresión";

  @override
  void initializeData(Map<String, dynamic>? data) {
    if (data != null) {
      name = data['name'] ?? '';
      description = data['description'] ?? '';
    }
  }

  @override
  Map<String, dynamic> buildDataMap() {
    return {
      'name': name,
      'description': description,
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
    ];
  }
}