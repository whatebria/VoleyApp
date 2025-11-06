import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/providers/providers.dart';

class EditBasicInfoScreen extends ConsumerStatefulWidget {
  const EditBasicInfoScreen({super.key});
  @override
  ConsumerState<EditBasicInfoScreen> createState() =>
      _EditBasicInfoScreenState();
}

class _EditBasicInfoScreenState extends ConsumerState<EditBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  PlayerPosition _position = PlayerPosition.oh;
  PlayerLevel _level = PlayerLevel.competitivo;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(playerProfileProvider).valueOrNull; // <- ref.read
    _nameCtrl = TextEditingController(text: profile?.name ?? '');
    _position = profile?.position ?? PlayerPosition.oh;
    _level = profile?.level ?? PlayerLevel.competitivo;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _enumLabel(Enum e) => e.name[0].toUpperCase() + e.name.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Información Básica')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PlayerPosition>(
              value: _position,
              decoration: const InputDecoration(labelText: 'Posición'),
              items: PlayerPosition.values
                  .map(
                    (p) =>
                        DropdownMenuItem(value: p, child: Text(_enumLabel(p))),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _position = v ?? _position),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PlayerLevel>(
              value: _level,
              decoration: const InputDecoration(labelText: 'Nivel'),
              items: PlayerLevel.values
                  .map(
                    (l) =>
                        DropdownMenuItem(value: l, child: Text(_enumLabel(l))),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _level = v ?? _level),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final profile = ref
                    .read(playerProfileProvider)
                    .valueOrNull; // <- ref.read
                if (profile == null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No hay perfil cargado')),
                  );
                  return;
                }
                final updated = profile.copyWith(
                  name: _nameCtrl.text.trim(),
                  position: _position,
                  level: _level,
                );
                // TODO: guarda en Firestore/servicio
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
