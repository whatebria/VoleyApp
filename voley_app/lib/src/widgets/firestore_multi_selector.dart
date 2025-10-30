// lib/widgets/firestore_multi_selector.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Un widget de formulario que permite seleccionar múltiples IDs de una colección
/// y los muestra como Chips, con filtrado opcional por categoría.
class FirestoreMultiSelector extends StatelessWidget {
  final String label;
  final CollectionReference collectionRef;
  final String nameField; // El campo del documento a mostrar (ej. "name")
  
  // --- NUEVO PARÁMETRO ---
  /// (Opcional) Filtra la lista por el campo 'category' en Firestore.
  final String? filterCategory; 
  // -----------------------

  final List<String> selectedIds;
  final ValueChanged<List<String>> onUpdate;

  const FirestoreMultiSelector({
    super.key,
    required this.label,
    required this.collectionRef,
    this.nameField = 'name',
    this.filterCategory, // <-- Añadido al constructor
    required this.selectedIds,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildSelectedChips(),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_task),
          label: Text("Seleccionar... (${selectedIds.length})"),
          onPressed: () => _showSelectionDialog(context),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Muestra los nombres de los items seleccionados
  Widget _buildSelectedChips() {
    if (selectedIds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Ninguno seleccionado.", style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: selectedIds.map((id) {
        return FutureBuilder<DocumentSnapshot>(
          future: collectionRef.doc(id).get(),
          builder: (context, snapshot) {
            // ... (Esta lógica de FutureBuilder no cambia)
            if (!snapshot.hasData) {
              return const Chip(label: Text("..."));
            }
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final name = data?[nameField] ?? 'ID: $id';
            return Chip(
              label: Text(name),
              onDeleted: () {
                final newList = List<String>.from(selectedIds)..remove(id);
                onUpdate(newList);
              },
            );
          },
        );
      }).toList(),
    );
  }

  /// Muestra un diálogo para seleccionar items del catálogo
  void _showSelectionDialog(BuildContext context) async {
    // --- LÓGICA DE QUERY ACTUALIZADA ---
    // 1. Empezamos con la referencia base
    Query query = collectionRef;

    // 2. Si se proveyó un filtro, lo aplicamos
    if (filterCategory != null && filterCategory!.isNotEmpty) {
      query = query.where('category', isEqualTo: filterCategory);
    }
    
    // 3. (Opcional pero recomendado) Ordenamos alfabéticamente
    query = query.orderBy('name');

    // 4. Ejecutamos la query (filtrada o no)
    final itemsSnapshot = await query.get();
    // ------------------------------------

    final allItems = itemsSnapshot.docs;
    List<String> tempSelectedIds = List.from(selectedIds);

    final List<String>? result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Seleccionar $label"),
              content: SizedBox(
                width: double.maxFinite,
                // Si la lista está vacía DESPUÉS de filtrar
                child: allItems.isEmpty 
                  ? Center(child: Text("No hay objetivos en la categoría '$filterCategory'."))
                  : ListView.builder(
                      itemCount: allItems.length,
                      itemBuilder: (context, index) {
                        // ... (El resto del diálogo no cambia)
                        final doc = allItems[index];
                        final docId = doc.id;
                        final docName = (doc.data() as Map<String,dynamic>)[nameField] ?? '...';
                        final isChecked = tempSelectedIds.contains(docId);

                        return CheckboxListTile(
                          title: Text(docName),
                          value: isChecked,
                          onChanged: (bool? checked) {
                            setDialogState(() {
                              if (checked == true) {
                                tempSelectedIds.add(docId);
                              } else {
                                tempSelectedIds.remove(docId);
                              }
                            });
                          },
                        );
                      },
                    ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, tempSelectedIds),
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      onUpdate(result); // Notifica al formulario
    }
  }
}