import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// Providers y modelos reales de tu app
import 'package:voley_app/providers/providers.dart'; // currentUserAppUserProvider, playerProfileProvider, firestoreProvider
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/goal.dart';

/// Onboarding amigable y de baja carga cognitiva para completar el PlayerProfile
/// acorde a TUS MODELOS actuales.
///
/// Claves:
/// - 4 pasos cortos (bienvenida, básicos, disponibilidad, objetivo opcional)
/// - Omitir en cada paso y "Omitir todo" global (crea un perfil mínimo)
/// - Guarda con valores por defecto y vuelve (AuthWrapper redirige)
class PlayerOnboardingScreen extends ConsumerStatefulWidget {
  const PlayerOnboardingScreen({super.key});

  @override
  ConsumerState<PlayerOnboardingScreen> createState() => _PlayerOnboardingScreenState();
}

class _PlayerOnboardingScreenState extends ConsumerState<PlayerOnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;

  final _formKeyBasics = GlobalKey<FormState>();
  String _name = '';
  String _position = '';
  String _level = '';

  final List<String> _allDays = const ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];
  final Set<String> _trainingDays = {};

  // Rango de tiempo (minutos)
  static const List<_MinutesRange> _timeRanges = <_MinutesRange>[
    _MinutesRange(30, 45),
    _MinutesRange(45, 60),
    _MinutesRange(60, 75),
    _MinutesRange(75, 90),
    _MinutesRange(90, 120),
  ];
  int _selectedRangeIndex = 2; // por defecto 60–75
  double _sessionMinutes = _timeRanges[2].mid as double; // solo para vista previa

  final _goalController = TextEditingController();
  final List<String> _goals = [];

  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
      _pageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      // 1) Rescatamos usuario app para asignar userId y defaults
      final appUser = await ref.read(currentUserAppUserProvider.future);
      final uid = appUser?.id; // puede ser null si algo falla, manejamos abajo

      // 2) Construimos perfil MÍNIMO coherente con tu modelo
      final profile = PlayerProfile(
        id: const Uuid().v4(),
        userId: uid,
        name: _name.trim().isEmpty ? (appUser?.name ?? 'Jugador') : _name.trim(),
        position: _position.isEmpty ? 'Sin posición' : _position,
        level: _level.isEmpty ? 'recreativo' : _level, // "recreativo" | "competitivo" | "semiprofesional"
        goals: _goals
            .map((g) => Goal(id: const Uuid().v4(), description: g, isCompleted: false))
            .toList(),
        injuries: const [],
        availability: Availability(
          trainingDays: _trainingDays.toList(),
          sessionMinutes: _timeRanges[_selectedRangeIndex].mid, // guardamos el promedio del rango
        ),
        evaluationHistory: const [],
        tournaments: const [],
        assignedCoachId: null,
        equipmentIds: const [],
        age: null,
        heightCm: null,
        weightKg: null,
        wingspanCm: null,
        keyEvents: const [],
        formPeaks: const [],
      );

      // 3) Guardamos (usa el método agregado en FirestoreService)
      final firestore = ref.read(firestoreProvider);
      await firestore.upsertPlayerProfile(profile);

      // 4) Invalidamos provider para que AuthWrapper/Perfil re-lean
      ref.invalidate(playerProfileProvider);

      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No pudimos guardar tu perfil: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configura tu perfil'),
        leading: _step == 0
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).maybePop())
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
        actions: [
          TextButton(onPressed: _saving ? null : _finish, child: const Text('Omitir todo')),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_step + 1) / 4),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StepWelcome(onNext: _next),
          _StepBasics(
            formKey: _formKeyBasics,
            onSaved: (n, p, l) { _name = n; _position = p; _level = l; },
            onNext: () { _formKeyBasics.currentState?.save(); _next(); },
            onSkip: _next,
          ),
          _StepAvailability(
            allDays: _allDays,
            selectedDays: _trainingDays,
            timeRanges: _timeRanges,
            selectedRangeIndex: _selectedRangeIndex,
            onToggleDay: (day, enabled) {
              setState(() {
                final copy = {..._trainingDays};
                if (enabled) { copy.add(day); } else { copy.remove(day); }
                _trainingDays
                  ..clear()
                  ..addAll(copy);
              });
            },
            onSelectRange: (index) {
              setState(() {
                _selectedRangeIndex = index;
                _sessionMinutes = _timeRanges[index].mid as double; // solo para preview
              });
            },
            previewMinutes: _sessionMinutes,
            onNext: _next,
            onSkip: _next,
          ),
          _StepGoals(
            controller: _goalController,
            goals: _goals,
            onAddGoal: () {
              final text = _goalController.text.trim();
              if (text.isNotEmpty) { setState(() { _goals.add(text); }); _goalController.clear(); }
            },
            onRemoveGoal: (g) => setState(() { _goals.remove(g); }),
            onFinish: _finish,
            onSkip: _finish,
            saving: _saving,
          ),
        ],
      ),
    );
  }
}

// --- Paso 1: Bienvenida ---
class _StepWelcome extends StatelessWidget {
  const _StepWelcome({required this.onNext});
  final VoidCallback onNext;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_volleyball_outlined, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('¡Bienvenido/a!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Tomará menos de 1 minuto. Puedes omitir cualquier paso.', style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: onNext, icon: const Icon(Icons.arrow_forward), label: const Text('Empezar')),
        ],
      ),
    );
  }
}

// --- Paso 2: Básicos ---
class _StepBasics extends StatelessWidget {
  const _StepBasics({
    required this.formKey,
    required this.onSaved,
    required this.onNext,
    required this.onSkip,
  });
  final GlobalKey<FormState> formKey;
  final void Function(String name, String position, String level) onSaved;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String name = '';
    String position = '';
    String level = '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: ListView(
          children: [
            Text('Cuéntanos de ti', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Puedes editar esto más tarde en tu perfil.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nombre para mostrar (opcional)'),
              onSaved: (v) => name = (v ?? '').trim(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Posición (opcional)'),
              items: const [
                DropdownMenuItem(value: 'Opuesto', child: Text('Opuesto')),
                DropdownMenuItem(value: 'Punta', child: Text('Punta')),
                DropdownMenuItem(value: 'Central', child: Text('Central')),
                DropdownMenuItem(value: 'Armador', child: Text('Armador')),
                DropdownMenuItem(value: 'Líbero', child: Text('Líbero')),
              ],
              onChanged: (v) => position = v ?? '',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Nivel (opcional)'),
              items: const [
                DropdownMenuItem(value: 'recreativo', child: Text('Recreativo')),
                DropdownMenuItem(value: 'competitivo', child: Text('Competitivo')),
                DropdownMenuItem(value: 'semiprofesional', child: Text('Semiprofesional')),
              ],
              onChanged: (v) => level = v ?? '',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(onPressed: onSkip, child: const Text('Omitir')),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () { formKey.currentState?.save(); onSaved(name, position, level); onNext(); },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continuar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Paso 3: Disponibilidad (con switches por día + rangos de tiempo) ---
class _StepAvailability extends StatelessWidget {
  const _StepAvailability({
    required this.allDays,
    required this.selectedDays,
    required this.timeRanges,
    required this.selectedRangeIndex,
    required this.onToggleDay,
    required this.onSelectRange,
    required this.previewMinutes,
    required this.onNext,
    required this.onSkip,
  });

  final List<String> allDays;
  final Set<String> selectedDays;
  final List<_MinutesRange> timeRanges;
  final int selectedRangeIndex;

  final void Function(String day, bool enabled) onToggleDay;
  final void Function(int index) onSelectRange;

  final double previewMinutes;

  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text('Tu disponibilidad', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Activa los días en que sueles entrenar y elige un rango de tiempo.',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),

          // DÍAS: switches deslizables (no se reinician al cambiar el tiempo)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: allDays.map((day) {
                final enabled = selectedDays.contains(day);
                return SwitchListTile.adaptive(
                  title: Text(day),
                  value: enabled,
                  onChanged: (v) => onToggleDay(day, v),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // RANGOS DE TIEMPO
          Text('Duración por sesión', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(timeRanges.length, (i) {
              final r = timeRanges[i];
              final selected = i == selectedRangeIndex;
              return ChoiceChip(
                label: Text(r.label),
                selected: selected,
                onSelected: (_) => onSelectRange(i),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text('Promedio estimado: ${previewMinutes.round()} min', style: theme.textTheme.bodySmall),

          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(onPressed: onSkip, child: const Text('Omitir')),
              const Spacer(),
              FilledButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Paso 4: Objetivo opcional + Finalizar ---
class _StepGoals extends StatelessWidget {
  const _StepGoals({
    required this.controller,
    required this.goals,
    required this.onAddGoal,
    required this.onRemoveGoal,
    required this.onFinish,
    required this.onSkip,
    required this.saving,
  });
  final TextEditingController controller;
  final List<String> goals;
  final VoidCallback onAddGoal;
  final void Function(String) onRemoveGoal;
  final VoidCallback onFinish;
  final VoidCallback onSkip;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text('¿Algún objetivo ahora?', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Opcional. Ej: "Mejorar salto vertical 5 cm"', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Escribe un objetivo corto'),
                  onSubmitted: (_) => onAddGoal(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: onAddGoal, icon: const Icon(Icons.add), label: const Text('Añadir')),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: goals.map((g) => Chip(label: Text(g), onDeleted: () => onRemoveGoal(g))).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(onPressed: onSkip, child: const Text('Omitir')),
              const Spacer(),
              FilledButton.icon(
                onPressed: saving ? null : onFinish,
                icon: const Icon(Icons.check),
                label: saving ? const Text('Guardando...') : const Text('Finalizar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Helper para rangos de minutos ---
class _MinutesRange {
  final int min;
  final int max;
  const _MinutesRange(this.min, this.max);

  int get mid => ((min + max) / 2).round();
  String get label => '$min–$max min';
}
