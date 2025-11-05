// lib/screens/add_key_event_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/src/models/player_profile/player_event.dart'; // Tu modelo

class AddKeyEventScreen  extends ConsumerStatefulWidget {
  // Aceptamos un evento opcional para modo "Editar"
  final PlayerEvent? event;
  const AddKeyEventScreen ({super.key, this.event});

  @override
  ConsumerState<AddKeyEventScreen > createState() => _AddKeyEventScreen();
}

class _AddKeyEventScreen  extends ConsumerState<AddKeyEventScreen > {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  DateTime _selectedDate = DateTime.now();
  String? _selectedType;

  // Mapa para los tipos de evento. Mucho mejor UX que un campo de texto.
  final Map<String, String> _eventTypes = {
    'league': 'Liga',
    'cup': 'Copa',
    'playoff': 'Play-offs',
    'national_team': 'Selección',
    'travel': 'Viaje',
  };

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.event?.description ?? '');
    _selectedDate = widget.event?.date ?? DateTime.now();
    _selectedType = widget.event?.type ?? 'league'; // 'league' por defecto
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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
      if (_selectedType == null) {
        // Asegurarse de que se haya seleccionado un tipo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor, selecciona un tipo de evento')),
        );
        return;
      }

      final newEvent = PlayerEvent(
        type: _selectedType!,
        date: _selectedDate,
        description: _descriptionController.text,
        // id: widget.event?.id ?? Uuid().v4(), // Si usas IDs
      );

      // TODO: Llamar al Notifier para añadir o actualizar
      // if (widget.event != null) {
      //   ref.read(playerProfileProvider.notifier).updateKeyEvent(newEvent);
      // } else {
      //   ref.read(playerProfileProvider.notifier).addKeyEvent(newEvent);
      // }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fecha clave guardada (simulado)')),
      );
      Navigator.pop(context); // Volver a la lista
      // Si la lista está en otra pantalla, puede que necesites 2 pops
      // Navigator.pop(context); // Volver al hub de settings
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.event != null ? 'Editar Fecha Clave' : 'Añadir Fecha Clave'),
        actions: [
          IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveForm,
              tooltip: 'Guardar'),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Dropdown para el TIPO de evento
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Tipo de Evento'),
              items: _eventTypes.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
              validator: (value) =>
                  (value == null) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 24),

            // Selector de FECHA
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
            const SizedBox(height: 24),

            // Campo de DESCRIPCIÓN
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (Opcional)',
                hintText: 'Ej. "Cuartos de final vs..."',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Botón de GUARDAR
            ElevatedButton(
              onPressed: _saveForm,
              child: const Text('Guardar Fecha Clave'),
            ),
          ],
        ),
      ),
    );
  }
}