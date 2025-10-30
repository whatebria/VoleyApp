// lib/screens/admin/forms/injury_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:voley_app/src/screens/admin/base/base_form_screen.dart';
import 'package:voley_app/src/widgets/firestore_multi_selector.dart';

class InjuryFormScreen extends BaseFormScreen {
  InjuryFormScreen({super.key, String? id, Map<String, dynamic>? existing})
      : super(
          collectionRef: FirebaseFirestore.instance.collection('injuries'),
          id: id,
          existing: existing,
        );

  @override
  State<InjuryFormScreen> createState() => _InjuryFormScreenState();
}

class _InjuryFormScreenState extends BaseFormScreenState<InjuryFormScreen> {
  // --- Variables locales ---
  String name = '';
  String description = '';
  String precautions = '';
  String severity = 'leve'; // Valor por defecto
  
  // Lista de valores válidos para el dropdown
  final List<String> validSeverities = ["leve", "moderada", "grave"];
  
  // Controlador para el número
  final TextEditingController _recoveryTimeController = TextEditingController();

  // Listas de IDs
  List<String> excludeObjectiveIds = [];
  List<String> recommendObjectiveIds = [];
  List<String> zonaCuerpoIds = [];
  List<String> condicionesIds = [];

  @override
  void dispose() {
    _recoveryTimeController.dispose();
    super.dispose();
  }

  @override
  String getScreenTitle() => "Agregar/Editar Lesión";

  @override
  void initializeData(Map<String, dynamic>? data) {
    if (data != null) {
      name = data['name'] ?? '';
      description = data['description'] ?? '';
      precautions = data['precautions'] ?? '';
      _recoveryTimeController.text = data['recoveryTime']?.toString() ?? '0';

      // --- ¡AQUÍ SE EVITA EL ERROR DEL DROPDOWN! ---
      // 1. Carga el valor de Firebase
      String loadedSeverity = data['severity'] ?? 'leve';
      
      // 2. Comprueba si es un valor válido de la lista
      if (!validSeverities.contains(loadedSeverity)) {
        // 3. Si no lo es (ej. es "" o un valor antiguo), lo resetea
        loadedSeverity = 'leve';
      }
      severity = loadedSeverity;
      // --- FIN DE LA CORRECCIÓN ---

      // Carga las listas de IDs
      excludeObjectiveIds = List<String>.from(data['excludeObjectiveIds'] ?? []);
      recommendObjectiveIds = List<String>.from(data['recommendObjectiveIds'] ?? []);
      zonaCuerpoIds = List<String>.from(data['zonaCuerpoIds'] ?? []);
      condicionesIds = List<String>.from(data['condicionesIds'] ?? []);
    }
  }

  @override
  Map<String, dynamic> buildDataMap() {
    return {
      'name': name,
      'description': description,
      'precautions': precautions,
      'severity': severity,
      'recoveryTime': int.tryParse(_recoveryTimeController.text) ?? 0,
      'excludeObjectiveIds': excludeObjectiveIds,
      'recommendObjectiveIds': recommendObjectiveIds,
      'zonaCuerpoIds': zonaCuerpoIds,
      'condicionesIds': condicionesIds,
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
      TextFormField(
        initialValue: description,
        decoration: const InputDecoration(labelText: "Descripción / Síntomas"),
        maxLines: 2,
        onSaved: (v) => description = v!,
      ),
      
      // --- Campos nuevos ---
      DropdownButtonFormField(
        value: severity, // Garantizado que este valor está en la lista
        decoration: const InputDecoration(labelText: "Nivel de Severidad"),
        items: const [
          DropdownMenuItem(value: "leve", child: Text("Leve")),
          DropdownMenuItem(value: "moderada", child: Text("Moderada")),
          DropdownMenuItem(value: "grave", child: Text("Grave")),
        ],
        onChanged: (val) => setState(() => severity = val!),
      ),
      TextFormField(
        controller: _recoveryTimeController,
        decoration: const InputDecoration(labelText: "Tiempo de Recup. (semanas)"),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],),
      TextFormField(
        initialValue: precautions,
        decoration: const InputDecoration(labelText: "Precauciones"),
        maxLines: 2,
        onSaved: (v) => precautions = v!,
      ),
      
      const Divider(height: 30),

      
    ];
  }
}