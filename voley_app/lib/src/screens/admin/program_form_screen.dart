// lib/src/screens/admin/program_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProgramFormScreen extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? existing;

  const ProgramFormScreen({super.key, this.id, this.existing});

  @override
  State<ProgramFormScreen> createState() => _ProgramFormScreenState();
}

class _ProgramFormScreenState extends State<ProgramFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _focus = '';
  String _phase = '';
  List<String> _selectedTags = [];
  List<String> _selectedExercises = [];
  List<String> _selectedTests = [];
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final data = widget.existing!;
      _nameController.text = data['name'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _focus = data['focus'] ?? '';
      _phase = data['phase'] ?? '';
      _selectedTags = List<String>.from(data['recommendedTags'] ?? []);
      _selectedExercises = List<String>.from(data['exerciseIds'] ?? []);
      _selectedTests = List<String>.from(data['testIds'] ?? []);
      _startDate = (data['startDate'] as Timestamp?)?.toDate();
      _endDate = (data['endDate'] as Timestamp?)?.toDate();
    }
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate()) return;

    final programData = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'focus': _focus,
      'phase': _phase,
      'recommendedTags': _selectedTags,
      'exerciseIds': _selectedExercises,
      'testIds': _selectedTests,
      'startDate': _startDate,
      'endDate': _endDate,
    };

    final collection = FirebaseFirestore.instance.collection('programs');

    if (widget.id != null) {
      await collection.doc(widget.id).update(programData);
    } else {
      await collection.add(programData);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  Widget _buildFirestoreMultiSelect({
    required String label,
    required String collection,
    required List<String> selectedIds,
    required Function(List<String>) onChanged,
  }) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection(collection).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!.docs;
        return ExpansionTile(
          title: Text(label),
          children: docs.map((doc) {
            final id = doc.id;
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Sin nombre';
            final selected = selectedIds.contains(id);
            return CheckboxListTile(
              title: Text(name),
              value: selected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    selectedIds.add(id);
                  } else {
                    selectedIds.remove(id);
                  }
                  onChanged(List.from(selectedIds));
                });
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.id != null ? 'Editar Programa' : 'Nuevo Programa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre')),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descripción')),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Foco (e.g. fuerza, técnica)'),
                initialValue: _focus,
                onChanged: (val) => _focus = val,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Fase (e.g. pretemporada, temporada)'),
                initialValue: _phase,
                onChanged: (val) => _phase = val,
              ),
              _buildFirestoreMultiSelect(
                label: 'Etiquetas recomendadas',
                collection: 'tags',
                selectedIds: _selectedTags,
                onChanged: (v) => _selectedTags = v,
              ),
              _buildFirestoreMultiSelect(
                label: 'Ejercicios',
                collection: 'exercises',
                selectedIds: _selectedExercises,
                onChanged: (v) => _selectedExercises = v,
              ),
              _buildFirestoreMultiSelect(
                label: 'Tests',
                collection: 'tests',
                selectedIds: _selectedTests,
                onChanged: (v) => _selectedTests = v,
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _selectDate(context, true),
                    child: Text('Inicio: ${_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'No seleccionado'}'),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => _selectDate(context, false),
                    child: Text('Fin: ${_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'No seleccionado'}'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _saveProgram, child: const Text('Guardar Programa')),
            ],
          ),
        ),
      ),
    );
  }
}
