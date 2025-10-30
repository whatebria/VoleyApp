// lib/screens/admin/forms/evaluation_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/models/evaluation.dart';
import 'package:voley_app/src/services/firestore_service.dart';

class EvaluationFormScreen extends StatefulWidget {
  // Recibe la referencia a 'athletes/{uid}/evaluations'
  final CollectionReference collectionRef;
  final Evaluation? evaluation;

  const EvaluationFormScreen({
    super.key,
    required this.collectionRef,
    this.evaluation,
  });

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final FirestoreService _service;

  // Controladores
  late TextEditingController _dateController;
  late TextEditingController _notesController;
  late TextEditingController _priorityController;

  // Map<TestID, TestResult>
  Map<String, TestResult> _tests = {};
  
  // NINGÚN CAMBIO AQUÍ. ELIMINAMOS 'MOBILITY'
  // List<String> de IDs de lesiones
  List<String> _injuriesDetected = []; 

  @override
  void initState() {
    super.initState();
    _service = FirestoreService(widget.collectionRef);
    final e = widget.evaluation;

    _dateController = TextEditingController(text: e?.date ?? DateTime.now().toIso8601String().substring(0, 10));
    _notesController = TextEditingController(text: e?.notes ?? '');
    _priorityController = TextEditingController(text: e?.generatedPriority ?? '');

    if (e != null) {
      _tests = e.tests;
      // 1. INICIALIZA LA LISTA DE IDs
      _injuriesDetected = e.injuriesDetected;
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final data = {
      'date': _dateController.text,
      'notes': _notesController.text,
      'generatedPriority': _priorityController.text,
      'tests': _tests.map((key, value) => MapEntry(key, value.toMap())),
      // 2. GUARDA LA LISTA DE IDs
      'injuriesDetected': _injuriesDetected,
      'recommendations': [], // Esto debería generarse por lógica, no en el form
    };

    if (widget.evaluation == null) {
      await _service.addItem(data);
    } else {
      await _service.updateItem(widget.evaluation!.evaluationId, data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.evaluation == null ? 'Nueva Evaluación' : 'Editar Evaluación')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: "Fecha (YYYY-MM-DD)"),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 16),
              Text("Tests de Rendimiento", style: Theme.of(context).textTheme.titleMedium),
              _buildTestsSection(),
              
              // 3. SECCIÓN PARA SELECCIONAR LESIONES
              const SizedBox(height: 24),
              Text("Lesiones Detectadas", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              // Muestra los nombres de las lesiones ya seleccionadas
              _buildSelectedInjuriesDisplay(),
              OutlinedButton.icon(
                icon: const Icon(Icons.healing),
                label: Text("Seleccionar Lesiones (${_injuriesDetected.length})"),
                onPressed: _showInjurySelectionDialog,
              ),
              // ------------------------------------

              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: "Notas Generales"),
                maxLines: 3,
              ),
              TextFormField(
                controller: _priorityController,
                decoration: const InputDecoration(labelText: "Prioridad Generada (ej. power)"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text("Guardar Evaluación")),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye los campos de tests dinámicamente desde la colección 'tests'
  Widget _buildTestsSection() {
    return StreamBuilder<QuerySnapshot>(
      // Apunta a la colección de "Recursos" de tests
      stream: FirebaseFirestore.instance.collection('tests').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Text("Error al cargar tests");

        final testDocs = snapshot.data!.docs;

        return Column(
          children: testDocs.map((testDoc) {
            final testId = testDoc.id;
            final testName = testDoc['name'] ?? 'Test sin nombre';
            final testUnit = testDoc['measure'] ?? ''; // ej. "cm", "s"

            // Busca el resultado existente si estamos editando
            final existingResult = _tests[testId];

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 1,
                  child: Text(testName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: existingResult?.result?.toString() ?? '',
                    decoration: InputDecoration(labelText: "Resultado. ($testUnit)"),
                    keyboardType: TextInputType.number,
                    onSaved: (v) {
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
  
  // --- 4. WIDGETS PARA SELECCIONAR LESIONES ---

  /// Muestra los nombres de las lesiones seleccionadas
  Widget _buildSelectedInjuriesDisplay() {
    if (_injuriesDetected.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Ninguna seleccionada.", style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }

    // Crea un Chip por cada ID de lesión
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: _injuriesDetected.map((injuryId) {
        // Busca el nombre de la lesión en la colección 'injuries'
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('injuries').doc(injuryId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Chip(label: Text("Cargando..."));
            }
            final injuryName = (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? 'ID: $injuryId';
            return Chip(label: Text(injuryName));
          },
        );
      }).toList(),
    );
  }

  /// Muestra un diálogo para seleccionar lesiones del catálogo
  void _showInjurySelectionDialog() async {
    // Carga todas las lesiones del catálogo
    final injuriesSnapshot = await FirebaseFirestore.instance.collection('injuries').get();
    final allInjuries = injuriesSnapshot.docs;

    // Lista temporal para manejar los cambios en el diálogo
    List<String> tempSelectedIds = List.from(_injuriesDetected);

    final List<String>? result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        // StatefulBuilder para que el contenido del diálogo se actualice
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Seleccionar Lesiones"),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: allInjuries.length,
                  itemBuilder: (context, index) {
                    final doc = allInjuries[index];
                    final docId = doc.id;
                    final docName = (doc.data())['name'] ?? 'Lesión sin nombre';
                    final isChecked = tempSelectedIds.contains(docId);

                    return CheckboxListTile(
                      title: Text(docName),
                      value: isChecked,
                      onChanged: (bool? checked) {
                        setDialogState(() {
                          if (checked == true) {
                            tempSelectedIds.add(docId);
                          } else {
                            tempSelectedIds.remove(docId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Devuelve la lista de IDs seleccionados
                    Navigator.pop(context, tempSelectedIds);
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );

    // Si el usuario guardó (no canceló), actualiza el estado del formulario
    if (result != null) {
      setState(() {
        _injuriesDetected = result;
      });
    }
  }
}