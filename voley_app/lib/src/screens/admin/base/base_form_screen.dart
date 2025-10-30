// lib/screens/forms/base_form_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voley_app/src/services/firestore_service.dart';

/// Widget base abstracto para un formulario de "Crear/Editar".
/// No se puede usar directamente, debe ser extendido.
abstract class BaseFormScreen extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? existing;
  final CollectionReference collectionRef;

  const BaseFormScreen({
    super.key,
    required this.collectionRef,
    this.id,
    this.existing,
  });
}

/// Estado base abstracto. Maneja toda la lógica común de guardado y validación.
abstract class BaseFormScreenState<T extends BaseFormScreen> extends State<T> {
  final formKey = GlobalKey<FormState>();
  late final FirestoreService service;

  @override
  void initState() {
    super.initState();
    service = FirestoreService(widget.collectionRef);
    // Llama al método de la subclase para inicializar sus variables locales
    initializeData(widget.existing);
  }

  // ---
  // --- MÉTODOS ABSTRACTOS (deben ser implementados por las subclases)
  // ---

  /// Devuelve el título para la AppBar.
  String getScreenTitle();

  /// Construye la lista de widgets (campos) para el formulario.
  List<Widget> buildFormFields(BuildContext context);

  /// Inicializa las variables de estado locales (ej. 'name', 'level')
  /// a partir del mapa 'existing' cuando se está editando.
  void initializeData(Map<String, dynamic>? existing);

  /// Crea el mapa de datos final que se guardará en Firestore.
  Map<String, dynamic> buildDataMap();

  // ---
  // --- LÓGICA COMÚN (ya implementada)
  // ---

  /// Valida y guarda el formulario.
  void save() async {
    if (!formKey.currentState!.validate()) return;
    
    // Llama a 'onSaved' en todos los TextFormField
    formKey.currentState!.save(); 

    // Llama al método de la subclase para obtener el mapa de datos
    final data = buildDataMap();

    // Lógica de guardado
    if (widget.id == null) {
      await service.addItem(data);
    } else {
      await service.updateItem(widget.id!, data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getScreenTitle())), // Título de la subclase
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey, // Usa la key del estado base
          child: ListView(
            children: [
              // Construye los campos del formulario desde la subclase
              ...buildFormFields(context),

              // Botón de guardar común
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: save, // Llama a la función de guardado base
                icon: const Icon(Icons.save),
                label: const Text("Guardar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}