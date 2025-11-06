import 'package:flutter/material.dart';
import 'package:voley_app/src/models/player_profile/player_event.dart';

class AddKeyEventScreen extends StatefulWidget {
  const AddKeyEventScreen({super.key});

  @override
  State<AddKeyEventScreen> createState() => _AddKeyEventScreenState();
}

class _AddKeyEventScreenState extends State<AddKeyEventScreen> {
  final _formKey = GlobalKey<FormState>();
  PlayerEventType _type = PlayerEventType.league;
  DateTime _date = DateTime.now();
  final _descCtrl = TextEditingController();

  String _typeLabel(PlayerEventType t) {
    switch (t) {
      case PlayerEventType.league: return 'Liga';
      case PlayerEventType.cup: return 'Copa';
      case PlayerEventType.playoff: return 'Play-offs';
      case PlayerEventType.nationalTeam: return 'Selección';
      case PlayerEventType.travel: return 'Viaje';
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = PlayerEventType.values
        .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t))))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Añadir fecha clave')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<PlayerEventType>(
              value: _type,
              items: items,
              decoration: const InputDecoration(labelText: 'Tipo'),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha'),
              subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: _date,
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              onPressed: () {
                final ev = PlayerEvent(type: _type, date: _date, description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim());
                Navigator.pop(context, ev);
              },
            ),
          ],
        ),
      ),
    );
  }
}
