// lib/screens/edit_basic_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart'; // Para leer los datos

class EditBasicInfoScreen extends ConsumerStatefulWidget {
  const EditBasicInfoScreen({super.key});

  @override
  ConsumerState<EditBasicInfoScreen> createState() =>
      _EditBasicInfoScreenState();
}

class _EditBasicInfoScreenState extends ConsumerState<EditBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los campos
  late final TextEditingController _nameController;
  late final TextEditingController _positionController;
  late final TextEditingController _levelController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _wingspanController;

  @override
  void initState() {
    super.initState();
    // Leemos el estado actual del provider (¡no escuchar!)
    final profile = ref.read(playerProfileProvider).asData?.value;

    // Inicializamos los controladores con los datos del perfil
    _nameController = TextEditingController(text: profile?.name ?? '');
    _positionController = TextEditingController(text: profile?.position ?? '');
    _levelController = TextEditingController(text: profile?.level ?? '');
    _ageController = TextEditingController(text: profile?.age?.toString() ?? '');
    _heightController = TextEditingController(text: profile?.heightCm?.toString() ?? '');
    _weightController = TextEditingController(text: profile?.weightKg?.toString() ?? '');
    _wingspanController = TextEditingController(text: profile?.wingspanCm?.toString() ?? '');
  }

  @override
  void dispose() {
    // Limpiamos los controladores
    _nameController.dispose();
    _positionController.dispose();
    _levelController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _wingspanController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      // TODO: Aquí es donde llamarías al Notifier para guardar los datos
      // ej: ref.read(playerProfileProvider.notifier).updateBasicInfo(
      //   name: _nameController.text,
      //   position: _positionController.text,
      //   level: _levelController.text,
      //   age: int.tryParse(_ageController.text),
      //   // etc.
      // );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado (simulado)')),
      );
      Navigator.pop(context); // Volver a la pantalla anterior
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Información Básica'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre Completo'),
              validator: (value) => (value?.isEmpty ?? true) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _positionController,
              decoration: const InputDecoration(labelText: 'Posición'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _levelController,
              decoration: const InputDecoration(labelText: 'Nivel (ej. Profesional, Amateur)'),
            ),
            const Divider(height: 32),
            Text('Métricas Físicas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Edad', suffixText: 'años'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(labelText: 'Altura', suffixText: 'cm'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: 'Peso', suffixText: 'kg'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _wingspanController,
              decoration: const InputDecoration(labelText: 'Envergadura', suffixText: 'cm'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveForm,
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }
}