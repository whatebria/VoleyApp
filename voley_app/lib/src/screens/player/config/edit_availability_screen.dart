import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart';

class EditAvailabilityScreen extends ConsumerStatefulWidget {
  const EditAvailabilityScreen({super.key});

  @override
  ConsumerState<EditAvailabilityScreen> createState() => _EditAvailabilityScreenState(); // <- CORRECTO
}

class _EditAvailabilityScreenState extends ConsumerState<EditAvailabilityScreen> {
  final _formKey = GlobalKey<FormState>();

  final _minutesCtrl = TextEditingController(text: '60');
  final Set<DayOfWeek> _selected = {};

  @override
  void initState() {
    super.initState();
final profile = ref.read(playerProfileProvider).valueOrNull;

    if (profile != null) {
      _selected.addAll(profile.availability.trainingDays);
      _minutesCtrl.text = profile.availability.sessionMinutes.toString();
    }
  }

  @override
  void dispose() {
    _minutesCtrl.dispose();
    super.dispose();
  }

  String _dayLabel(DayOfWeek d) {
    switch (d) {
      case DayOfWeek.mon: return 'Lun';
      case DayOfWeek.tue: return 'Mar';
      case DayOfWeek.wed: return 'Mié';
      case DayOfWeek.thu: return 'Jue';
      case DayOfWeek.fri: return 'Vie';
      case DayOfWeek.sat: return 'Sáb';
      case DayOfWeek.sun: return 'Dom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = DayOfWeek.values;
    return Scaffold(
      appBar: AppBar(title: const Text('Disponibilidad')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              children: days.map((d) {
                final selected = _selected.contains(d);
                return FilterChip(
                  label: Text(_dayLabel(d)),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    v ? _selected.add(d) : _selected.remove(d);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minutesCtrl,
              decoration: const InputDecoration(labelText: 'Minutos por sesión'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Ingresa minutos válidos';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final profile = ref.read(playerProfileProvider).valueOrNull;
                if (profile == null) return;
                final updated = profile.copyWith(
                  availability: Availability(
                    trainingDays: _selected.toList(),
                    sessionMinutes: int.parse(_minutesCtrl.text),
                  ),
                );
                // TODO: guardar
                // await ref.read(firestoreProvider).savePlayerProfile(updated);
                if (!mounted) return;
                Navigator.pop(context, updated);
              },
            ),
          ],
        ),
      ),
    );
  }
}
