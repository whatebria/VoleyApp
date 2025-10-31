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

/// Firma para el builder del 'leading' (widget inicial) del ListTile.
typedef TileLeadingBuilder = Widget Function(Map<String, dynamic> data);

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

  /// (NUEVO - Opcional) Construye el widget [leading] del ListTile.
  final TileLeadingBuilder? tileLeadingBuilder;

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
    this.tileLeadingBuilder, // <-- Añadido al constructor
    this.onItemTap,
    this.fabLabel,
  });

  // --- Funciones Helper ---

  /// Muestra un diálogo de confirmación antes de eliminar.
  void _showDeleteDialog(
      BuildContext context, FirestoreService service, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text("Confirmar eliminación"),
        content:
            const Text("¿Estás seguro de que deseas eliminar este elemento?"),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text(
              "Eliminar",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onPressed: () {
              service.deleteItem(docId);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  /// Construye un widget visual para cuando la lista está vacía.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No hay datos",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Aún no se ha agregado nada aquí. ¡Usa el botón '+' para comenzar!",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Función para abrir el formulario
  void _openForm(BuildContext context, {DocumentSnapshot? doc}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pasa el snapshot completo al builder
        builder: (_) => formBuilder(doc: doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // El servicio ahora se inicializa con la referencia
    final FirestoreService service = FirestoreService(collectionRef);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        // --- MEJORA VISUAL ---
        elevation: 0,
        centerTitle: true,
      ),
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
            // --- MEJORA VISUAL ---
            return _buildEmptyState(context);
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            // --- MEJORA VISUAL ---
            padding: const EdgeInsets.all(10), // Padding alrededor de la lista
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              // --- MEJORA VISUAL: ListTile envuelto en Card ---
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                clipBehavior: Clip.antiAlias, // Recorta el splash de InkWell
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  // --- (NUEVO) Widget opcional al inicio ---
                  leading: tileLeadingBuilder?.call(data),
                  
                  title: tileTitleBuilder(data),
                  subtitle: tileSubtitleBuilder(data),

                  // Acción al tocar el item
                  onTap: onItemTap != null
                      ? () => onItemTap!(doc) // Acción personalizada
                      : () => _openForm(context,
                          doc: doc), // Acción por defecto (editar)

                  // Botones de acción a la derecha
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón de Editar (si no hay onItemTap)
                      if (onItemTap == null)
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            // --- MEJORA VISUAL: Color del tema ---
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          onPressed: () => _openForm(context, doc: doc),
                        ),
                      // Botón de Borrar
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          // --- MEJORA VISUAL: Color del tema ---
                          color: Theme.of(context).colorScheme.error,
                        ),
                        // --- MEJORA UX: Confirmación ---
                        onPressed: () => _showDeleteDialog(context, service, doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}