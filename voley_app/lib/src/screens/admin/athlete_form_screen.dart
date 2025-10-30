// lib/screens/admin/forms/athlete_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/models/athlete/athlete.dart';
import 'package:voley_app/src/services/firestore_service.dart';

class AthleteFormScreen extends StatefulWidget {
  final Athlete? athlete; // Pasa el atleta completo para editar

  const AthleteFormScreen({super.key, this.athlete});

  @override
  State<AthleteFormScreen> createState() => _AthleteFormScreenState();
}

class _AthleteFormScreenState extends State<AthleteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService(FirebaseFirestore.instance.collection('athletes'));

  // Controladores
  late TextEditingController _uidController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _birthDateController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _positionController;
  late TextEditingController _levelController;
  late TextEditingController _daysPerWeekController;
  late TextEditingController _goalsController;
  // ... y así sucesivamente para todos los campos

  @override
  void initState() {
    super.initState();
    final a = widget.athlete;
    _uidController = TextEditingController(text: a?.uid ?? '');
    _nameController = TextEditingController(text: a?.name ?? '');
    _emailController = TextEditingController(text: a?.email ?? '');
    _birthDateController = TextEditingController(text: a?.birthDate ?? '');
    _heightController = TextEditingController(text: a?.height.toString() ?? '0.0');
    _weightController = TextEditingController(text: a?.weight.toString() ?? '0.0');
    _positionController = TextEditingController(text: a?.position ?? '');
    _levelController = TextEditingController(text: a?.level ?? '');
    _daysPerWeekController = TextEditingController(text: a?.availability.daysPerWeek.toString() ?? '0');
    _goalsController = TextEditingController(text: a?.goals.join(', ') ?? '');
    // ...
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    // El ID del documento es el UID
    final uid = _uidController.text;
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El UID no puede estar vacío."))
      );
      return;
    }

    final data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'birthDate': _birthDateController.text,
      'height': double.tryParse(_heightController.text) ?? 0.0,
      'weight': double.tryParse(_weightController.text) ?? 0.0,
      'position': _positionController.text,
      'level': _levelController.text,
      'availability': {
        'daysPerWeek': int.tryParse(_daysPerWeekController.text) ?? 0,
        'preferredDays': [], // Simplificado, puedes usar un ChipListFormField aquí
      },
      'goals': _goalsController.text.split(',').map((e) => e.trim()).toList(),
      'injuries': [], // Simplificado, esto requeriría un sub-constructor complejo
      'hasTournamentSoon': false,
      'tournamentDate': '',
      'priority': '',
      'currentPhase': '',
      'currentProgramId': '',
      'lastEvaluationDate': '',
      'createdAt': widget.athlete?.createdAt ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    // Usamos setItem para forzar el ID a ser el UID
    await _service.setItem(uid, data); 

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.athlete == null ? 'Nuevo Atleta' : 'Editar Atleta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _uidController,
                decoration: const InputDecoration(labelText: "UID (Auth ID)"),
                enabled: widget.athlete == null, // Solo editable al crear
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _birthDateController,
                decoration: const InputDecoration(labelText: "Fecha Nacimiento (YYYY-MM-DD)"),
              ),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: "Altura (ej. 1.75)"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: "Peso (ej. 68.5)"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(labelText: "Posición"),
              ),
              TextFormField(
                controller: _levelController,
                decoration: const InputDecoration(labelText: "Nivel"),
              ),
              TextFormField(
                controller: _daysPerWeekController,
                decoration: const InputDecoration(labelText: "Días por Semana"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _goalsController,
                decoration: const InputDecoration(labelText: "Metas (separadas por coma)"),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text("Guardar Atleta"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}