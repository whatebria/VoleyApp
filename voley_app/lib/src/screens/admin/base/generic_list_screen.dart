// lib/screens/admin/base/generic_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/services/firestore_service.dart';

// --- Definiciones de Builders (para el Dashboard) ---

/// Firma para el builder del formulario.
/// Recibe el DocumentSnapshot completo para editar.
typedef FormWidgetBuilder = Widget Function({DocumentSnapshot? doc});

/// Firma para el builder del contenido del ListTile.
typedef TileContentBuilder = Widget Function(Map<String, dynamic> data);

/// Firma para la acción de tap en un item.
typedef ItemTapCallback = void Function(DocumentSnapshot doc);

class GenericListScreen extends StatelessWidget {
  /// La referencia directa a la colección (o sub-colección).
  final CollectionReference collectionRef;
  final String title;
  
  /// (Opcional) Título para el FloatingActionButton.
  final String? fabLabel;

  /// Construye la pantalla de formulario para crear/editar.
  final FormWidgetBuilder formBuilder;

  /// Construye el widget [title] del ListTile.
  final TileContentBuilder tileTitleBuilder;

  /// Construye el widget [subtitle] del ListTile.
  final TileContentBuilder tileSubtitleBuilder;
  
  /// (Opcional) Acción personalizada al tocar un item.
  /// Si es nulo, la acción por defecto es editar.
  final ItemTapCallback? onItemTap;

  const GenericListScreen({
    super.key,
    required this.collectionRef,
    required this.title,
    required this.formBuilder,
    required this.tileTitleBuilder,
    required this.tileSubtitleBuilder,
    this.onItemTap,
    this.fabLabel,
  });

  @override
  Widget build(BuildContext context) {
    // El servicio ahora se inicializa con la referencia
    final FirestoreService service = FirestoreService(collectionRef);

    // Función para abrir el formulario
    void _openForm(BuildContext context, {DocumentSnapshot? doc}) {
      Navigator.push(
        context,
        MaterialPageRoute(
          // Pasa el snapshot completo al builder
          builder: (_) => formBuilder(doc: doc),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        label: Text(fabLabel ?? 'Nuevo'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getItems(), // .getItems() funciona igual
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay datos para mostrar."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: tileTitleBuilder(data),
                subtitle: tileSubtitleBuilder(data),
                
                // Acción al tocar el item
                onTap: onItemTap != null
                    ? () => onItemTap!(doc) // Acción personalizada (ej. ir a detalle)
                    : () => _openForm(context, doc: doc), // Acción por defecto (editar)

                // Botones de acción a la derecha
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón de Editar (si no hay onItemTap)
                    if (onItemTap == null)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        onPressed: () => _openForm(context, doc: doc),
                      ),
                    // Botón de Borrar
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => service.deleteItem(doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}