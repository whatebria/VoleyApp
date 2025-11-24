import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/permission_provider.dart';
import 'package:voley_app/src/models/coach_player_permission.dart';

// --- CAMBIO: Convertido a ConsumerWidget ---
class PermissionManagementScreen extends ConsumerWidget {
  const PermissionManagementScreen({Key? key}) : super(key: key);

  // --- CAMBIO: Toda la lógica y estado se movieron al Notifier ---

  // --- CAMBIO: Helper de SnackBar ---
  void _showFeedback(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // --- CAMBIO: _linkWithCode ahora es un wrapper ---
  Future<void> _linkWithCode(
    WidgetRef ref,
    TextEditingController controller,
    BuildContext context,
  ) async {
    final code = controller.text;

    // Llama al notifier para que haga la lógica
    final result = await ref
        .read(permissionControllerProvider.notifier)
        .linkWithCode(code);

    // Muestra el resultado (éxito o error)
    _showFeedback(context, result, isError: !result.contains('correctamente'));

    if (result.contains('correctamente')) {
      controller.clear();
    }
  }

  // --- CAMBIO: _handlePermissionAction ahora es un wrapper ---
  Future<void> _handlePermissionAction(
    BuildContext context,
    WidgetRef ref,
    CoachPlayerPermission permission,
    PermissionStatus newStatus,
  ) async {
    final result = await ref
        .read(permissionControllerProvider.notifier)
        .handlePermissionAction(permission, newStatus);
    _showFeedback(context, result, isError: result.startsWith('Error'));
  }

  // --- CAMBIO: _handleDeletePermission movido y simplificado ---
  Future<void> _handleDeletePermission(
    BuildContext context,
    WidgetRef ref,
    String permissionId,
  ) async {
    final confirm = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _PermissionConfirmationScreen(),

      ),
    );

    if (confirm != true) return;

    final result = await ref
        .read(permissionControllerProvider.notifier)
        .deletePermission(permissionId);
    _showFeedback(context, result, isError: result.startsWith('Error'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- CAMBIO: El build ahora observa el nuevo provider ---
    final stateAsync = ref.watch(permissionControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Invitar Atletas')),
      // --- CAMBIO: Usamos .when() para manejar estados ---
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error al cargar datos: $e'),
          ),
        ),
        data: (state) {
          // --- CAMBIO: Pantalla de "Acceso Denegado" para jugadores ---
          if (!state.currentUser.isCoach) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Esta pantalla solo está disponible para entrenadores.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // --- CAMBIO: La UI principal usa los datos del 'state' ---
          return RefreshIndicator(
            onRefresh: () async {
              // Invalida el provider para forzar un 're-build'
              ref.invalidate(permissionControllerProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHowItWorksCard(theme),
                const SizedBox(height: 24),
                _buildMyCodeCard(context, theme, state.linkCode),
                const SizedBox(height: 24),
                _buildLinkWithCodeCard(context, theme, ref),
                const SizedBox(height: 24),
                _buildPendingPermissionsSection(
                  context,
                  theme,
                  ref,
                  state.pendingRequests,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- CAMBIO: Widgets ahora son stateless y reciben datos ---

  Widget _buildHowItWorksCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface, // grisPro
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.surfaceVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Cómo invitar atletas?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStepRow(
              theme,
              '1',
              'Comparte tu código de entrenador (abajo) con tus atletas.',
            ),
            const SizedBox(height: 12),
            _buildStepRow(
              theme,
              '2',
              'El atleta debe ingresar tu código en su propia app.',
            ),
            const SizedBox(height: 12),
            _buildStepRow(
              theme,
              '3',
              'La solicitud aparecerá en "Invitaciones Pendientes" en esta pantalla para que la apruebes.',
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Opción Alternativa:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStepRow(
              theme,
              '?',
              'Pídele al atleta su código de 6 dígitos y escríbelo en la tarjeta "Vincular con Código".',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(ThemeData theme, String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: theme.colorScheme.secondary, // azulPro
          child: Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }

  Widget _buildMyCodeCard(
    BuildContext context,
    ThemeData theme,
    String linkCode,
  ) {
    final headline = 'Mi Código de Entrenador';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headline,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        linkCode.isEmpty ? '------' : linkCode,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: linkCode.isEmpty
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: linkCode));
                          _showFeedback(
                            context,
                            'Código copiado al portapapeles',
                          );
                        },
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copiar código',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- CAMBIO: _buildLinkWithCodeCard ahora es un Consumer ---
  // Necesita su propio Consumer/StatefulBuilder para manejar el TextField
  Widget _buildLinkWithCodeCard(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
  ) {
    // Usamos un 'Hook' o un 'StatefulBuilder' para el controller localmente
    // Aquí usaremos un StatefulBuilder por simplicidad
    final codeController = TextEditingController();
    final isLinking = ref.watch(isLinkingProvider);

    return Card(
      elevation: 0,
      color: theme.colorScheme.background, // Sutil
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.surfaceVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vincular con Código',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ingresa el código de un jugador para agregarlo de inmediato.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              onChanged: (value) {
                final upper = value.toUpperCase();
                if (value != upper) {
                  codeController.value = TextEditingValue(
                    text: upper,
                    selection: TextSelection.collapsed(offset: upper.length),
                  );
                }
              },
              decoration: InputDecoration(
                labelText: 'Código del jugador',
                prefixIcon: const Icon(Icons.key_outlined),
                counterText: '',
                // --- CORRECCIÓN: StatefulBuilder para el suffixIcon ---
                suffixIcon: Consumer(
                  builder: (context, ref, child) {
                    // Reconstruye solo el icono cuando el texto cambia
                    return codeController.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            onPressed: () => codeController.clear(),
                            icon: const Icon(Icons.clear),
                          );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLinking
                    ? null
                    : () => _linkWithCode(ref, codeController, context),
                icon: isLinking
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.link),
                label: Text(isLinking ? 'Vinculando...' : 'Vincular'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPermissionsSection(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    List<PendingPermissionView> permissions,
  ) {
    if (permissions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            'No hay invitaciones pendientes.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invitaciones Pendientes (${permissions.length})',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // --- CAMBIO: Ya no usa FutureBuilder ---
        ...permissions.map((request) {
          final user = request.user;
          final permission = request.permission;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text(user.name[0].toUpperCase()),
              ),
              title: Text(user.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email),
                  const SizedBox(height: 4),
                  Text(
                    'Estado: ${_getStatusText(permission.status)}',
                    style: TextStyle(
                      color: _getStatusColor(permission.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _handlePermissionAction(
                      context,
                      ref,
                      permission,
                      PermissionStatus.accepted,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _handlePermissionAction(
                      context,
                      ref,
                      permission,
                      PermissionStatus.rejected,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- CAMBIO: _findPermission eliminado ---
  // (Esta lógica ya no es necesaria en la vista)

  String _getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.pending:
        return 'Pendiente';
      case PermissionStatus.accepted:
        return 'Aceptado';
      case PermissionStatus.rejected:
        return 'Rechazado';
    }
  }

  Color _getStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.pending:
        return Colors.orange;
      case PermissionStatus.accepted:
        return Colors.green;
      case PermissionStatus.rejected:
        return Colors.red;
    }
  }
}
class _PermissionConfirmationScreen extends StatelessWidget {
  const _PermissionConfirmationScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar acción')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de revocar este permiso?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Se quitará el acceso del atleta y deberá volver a ser invitado para recuperar los permisos.',
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Revocar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}