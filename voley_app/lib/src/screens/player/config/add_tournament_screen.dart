// lib/screens/add_tournament_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart'; // Modelo

class AddTournamentScreen extends ConsumerStatefulWidget {
  // Opcional: podemos pasar un torneo para editarlo
  final Tournament? tournament;
  const AddTournamentScreen({super.key, this.tournament});

  @override
  ConsumerState<AddTournamentScreen> createState() => _AddTournamentScreenState();
}

class _AddTournamentScreenState extends ConsumerState<AddTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tournament?.name ?? '');
    _selectedDate = widget.tournament?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final newTournament = Tournament(
        name: _nameController.text,
        date: _selectedDate,
        // id: widget.tournament?.id ?? Uuid().v4(), // Si usas IDs
      );

      // TODO: Llamar al Notifier para añadir o actualizar
      // if (widget.tournament != null) {
      //   ref.read(playerProfileProvider.notifier).updateTournament(newTournament);
      // } else {
      //   ref.read(playerProfileProvider.notifier).addTournament(newTournament);
      // }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Torneo guardado (simulado)')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournament != null ? 'Editar Torneo' : 'Añadir Torneo'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveForm),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del Torneo'),
                validator: (value) => (value?.isEmpty ?? true) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _pickDate(context),
                    child: const Text('Seleccionar Fecha'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveForm,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}