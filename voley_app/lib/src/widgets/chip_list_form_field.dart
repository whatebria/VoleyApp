// lib/widgets/chip_list_form_field.dart
import 'package:flutter/material.dart';

/// Un campo de formulario reutilizable para gestionar una lista de 'chips'.
class ChipListFormField extends StatefulWidget {
  final String label;
  final List<String> items;
  // Callback para notificar al formulario padre que la lista ha cambiado
  final ValueChanged<List<String>> onUpdate; 

  const ChipListFormField({
    super.key,
    required this.label,
    required this.items,
    required this.onUpdate,
  });

  @override
  State<ChipListFormField> createState() => _ChipListFormFieldState();
}

class _ChipListFormFieldState extends State<ChipListFormField> {
  final TextEditingController _controller = TextEditingController();

  void _addItem() {
    if (_controller.text.isNotEmpty) {
      // 1. Crea una nueva lista (inmutabilidad)
      final newList = List<String>.from(widget.items)..add(_controller.text);
      // 2. Notifica al formulario padre del cambio
      widget.onUpdate(newList); 
      _controller.clear();
    }
  }

  void _removeItem(String item) {
    // 1. Crea una nueva lista
    final newList = List<String>.from(widget.items)..remove(item);
    // 2. Notifica al formulario padre
    widget.onUpdate(newList);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: widget.items
              .map((t) => Chip(
                    label: Text(t),
                    onDeleted: () => _removeItem(t),
                  ))
              .toList(),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: "Añadir nuevo"),
                onSubmitted: (_) => _addItem(), // Permite añadir con "Enter"
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addItem,
            )
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}