import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/src/models/player_profile/form_peak.dart';
import 'package:voley_app/src/models/player_profile/goal.dart';
import 'package:voley_app/src/models/player_profile/injury.dart';
import 'package:voley_app/src/models/player_profile/player_event.dart';
import 'package:voley_app/src/models/player_profile/test_score.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';

class TournamentFormScreen extends StatefulWidget {
  const TournamentFormScreen({super.key});

  @override
  State<TournamentFormScreen> createState() => _TournamentFormScreenState();
}

class _TournamentFormScreenState extends State<TournamentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(
        context,
        Tournament(name: _nameCtrl.text.trim(), date: _selectedDate),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir Torneo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Torneo *',
                  prefixIcon: Icon(Icons.emoji_events),
                  helperText: 'Ej: Copa Nacional 2024',
                ),
                validator: (v) => (v?.isEmpty ?? true)
                    ? 'El nombre es requerido'
                    : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fecha del Torneo'),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.edit),
                onTap: _pickDate,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Añadir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoalFormScreen extends StatefulWidget {
  final String Function() idBuilder;
  const GoalFormScreen({super.key, required this.idBuilder});

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _goalCtrl = TextEditingController();

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_goalCtrl.text.trim().isNotEmpty) {
      Navigator.pop(
        context,
        Goal(
          id: widget.idBuilder(),
          description: _goalCtrl.text.trim(),
          isCompleted: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Objetivo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _goalCtrl,
              decoration: const InputDecoration(
                labelText: 'Objetivo',
                helperText: 'Ej: Mejorar salto vertical',
              ),
              autofocus: true,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class TestScoreFormScreen extends StatefulWidget {
  const TestScoreFormScreen({super.key});

  @override
  State<TestScoreFormScreen> createState() => _TestScoreFormScreenState();
}

class _TestScoreFormScreenState extends State<TestScoreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final value = double.parse(_valueCtrl.text.replaceAll(',', '.'));
      Navigator.pop(
        context,
        TestScore(
          testId: _nameCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
          value: value,
          unit: _unitCtrl.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Test Inicial')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Test *',
                  helperText: 'Ej: Salto vertical',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresa un nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueCtrl,
                decoration: const InputDecoration(
                  labelText: 'Resultado *',
                  helperText: 'Ej: 45.5',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un resultado';
                  }
                  return double.tryParse(value.replaceAll(',', '.')) == null
                      ? 'Ingresa un número válido'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitCtrl,
                decoration: const InputDecoration(
                  labelText: 'Unidad *',
                  helperText: 'Ej: cm, seg, kg',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresa una unidad'
                    : null,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Añadir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InjuryFormScreen extends StatefulWidget {
  final String Function() idBuilder;
  const InjuryFormScreen({super.key, required this.idBuilder});

  @override
  State<InjuryFormScreen> createState() => _InjuryFormScreenState();
}

class _InjuryFormScreenState extends State<InjuryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  InjuryStatus _status = InjuryStatus.active;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(
        context,
        Injury(
          id: widget.idBuilder(),
          description: _descriptionCtrl.text.trim(),
          status: _status,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Lesión')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción de la Lesión *',
                  helperText: 'Ej: Esguince de tobillo',
                ),
                autofocus: true,
                validator: (v) => (v?.isEmpty ?? true)
                    ? 'La descripción es requerida'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<InjuryStatus>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: InjuryStatus.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s.toString()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _status = val);
                  }
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayerEventFormScreen extends StatefulWidget {
  const PlayerEventFormScreen({super.key});

  @override
  State<PlayerEventFormScreen> createState() => _PlayerEventFormScreenState();
}

class _PlayerEventFormScreenState extends State<PlayerEventFormScreen> {
  PlayerEventType _selectedType = PlayerEventType.league;
  DateTime _selectedDate = DateTime.now();
  final _descriptionCtrl = TextEditingController();

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  String _eventTypeLabel(PlayerEventType t) {
    switch (t) {
      case PlayerEventType.cup:
        return 'Copa';
      case PlayerEventType.playoff:
        return 'Play-offs';
      case PlayerEventType.nationalTeam:
        return 'Selección';
      case PlayerEventType.travel:
        return 'Viaje';
      case PlayerEventType.league:
        return 'Liga';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    Navigator.pop(
      context,
      PlayerEvent(
        type: _selectedType,
        date: _selectedDate,
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Fecha Clave')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<PlayerEventType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Tipo de evento'),
              items: PlayerEventType.values
                  .map(
                    (t) => DropdownMenuItem<PlayerEventType>(
                      value: t,
                      child: Text(_eventTypeLabel(t)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha'),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(_selectedDate),
              ),
              onTap: _pickDate,
            ),
            TextField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                helperText: 'Ej: Liga Metropolitana',
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}

class FormPeakFormScreen extends StatefulWidget {
  const FormPeakFormScreen({super.key});

  @override
  State<FormPeakFormScreen> createState() => _FormPeakFormScreenState();
}

class _FormPeakFormScreenState extends State<FormPeakFormScreen> {
  DateTime _selectedDate = DateTime.now();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    Navigator.pop(
      context,
      FormPeak(
        date: _selectedDate,
        note:
            _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Pico de Forma')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha estimada'),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(_selectedDate),
              ),
              onTap: _pickDate,
            ),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                helperText: 'Ej: Preparar pico para play-offs',
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class NumberPadScreen extends StatefulWidget {
  final double initialValue;
  const NumberPadScreen({super.key, required this.initialValue});

  @override
  State<NumberPadScreen> createState() => _NumberPadScreenState();
}

class _NumberPadScreenState extends State<NumberPadScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, double.tryParse(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Valor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}