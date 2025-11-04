import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/auth_provider.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/services/firestore_service.dart';
class PlayerLinkCodeScreen extends ConsumerStatefulWidget {
  const PlayerLinkCodeScreen({super.key});
  @override
  ConsumerState<PlayerLinkCodeScreen> createState() =>
      _PlayerLinkCodeScreenState();
}
class _PlayerLinkCodeScreenState
    extends ConsumerState<PlayerLinkCodeScreen> {
  final _firestoreService = FirestoreService();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = true;
  bool _isLinking = false;
  app_user.User? _currentUser;
  app_user.User? _linkedCoach;
  String? _linkCode;
  @override
  void initState() {
    super.initState();
    _loadUser();
  }
  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final authUser = ref.read(currentUserProvider);
      if (authUser == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      final firestoreUser = await _firestoreService.getUser(authUser.uid);
      if (!mounted) return;
      if (firestoreUser == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cargar tu información.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!firestoreUser.isPlayer) {
        setState(() {
          _currentUser = firestoreUser;
          _isLoading = false;
        });
        return;
      }
      final ensuredCode =
          await _firestoreService.ensureUserLinkCode(firestoreUser.id);
      app_user.User? linkedCoach;
      if ((firestoreUser.coachId ?? '').isNotEmpty) {
        linkedCoach = await _firestoreService.getUser(firestoreUser.coachId!);
      }
      if (!mounted) return;
      setState(() {
        _currentUser = firestoreUser.copyWith(linkCode: ensuredCode);
        _linkedCoach = linkedCoach;
        _linkCode = ensuredCode;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void> _linkWithCode() async {
    if (_currentUser == null || !_currentUser!.isPlayer) return;
    final input = _codeController.text.trim().toUpperCase();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el código de tu entrenador.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_linkCode != null && input == _linkCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes usar tu propio código.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isLinking = true);
    try {
      final targetUser = await _firestoreService.getUserByLinkCode(input);
      if (targetUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código no encontrado. Verifica e inténtalo de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!targetUser.isCoach) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este código no pertenece a un entrenador.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (_currentUser!.coachId == targetUser.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya estás vinculado con este entrenador.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      await _firestoreService.linkCoachAndPlayer(
        coachId: targetUser.id,
        playerId: _currentUser!.id,
      );
      if (!mounted) return;
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡${targetUser.name} ahora es tu entrenador!'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al vincular: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLinking = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular con mi entrenador'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(theme),
    );
  }
  Widget _buildContent(ThemeData theme) {
    if (_currentUser == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No se encontró información del jugador.'),
        ),
      );
    }
    if (!_currentUser!.isPlayer) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Esta pantalla está disponible solo para jugadores.'),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCodeCard(theme),
          const SizedBox(height: 24),
          if (_linkedCoach != null) _buildCoachCard(theme),
          if (_linkedCoach != null) const SizedBox(height: 24),
          _buildInputCard(theme),
        ],
      ),
    );
  }
  Widget _buildCodeCard(ThemeData theme) {
     final linkCode = _linkCode;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparte tu código',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Envía este código a tu entrenador para que pueda encontrarte.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
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
                        linkCode ?? '------',
                        style: theme.textTheme.headlineMedium?.copyWith(
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
                  onPressed: linkCode == null
                      ? null
                      : () {
                          Clipboard.setData(
                            ClipboardData(text: linkCode),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código copiado al portapapeles'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copiar código',
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildCoachCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu entrenador actual',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondary,
                child: Text(
                  _linkedCoach!.name.isNotEmpty
                      ? _linkedCoach!.name.substring(0, 2).toUpperCase()
                      : '??',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                _linkedCoach!.name,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(_linkedCoach!.email),
            ),
            const SizedBox(height: 4),
            Text(
              'Si necesitas cambiar de entrenador, ingresa un nuevo código abajo.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildInputCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa el código de tu entrenador',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código de entrenador',
                hintText: 'Ej. ABC123',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLinking,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLinking ? null : _linkWithCode,
                icon: _isLinking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: Text(_isLinking ? 'Vinculando...' : 'Vincular entrenador'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}