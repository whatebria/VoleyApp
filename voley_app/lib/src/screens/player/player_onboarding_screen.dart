import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart';

// Providers y modelos reales de tu app
import 'package:voley_app/providers/providers.dart'; // currentUserAppUserProvider, playerProfileProvider, firestoreProvider
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/goal.dart';

/// Onboarding amigable y de baja carga cognitiva para completar el PlayerProfile.
/// - 4 pasos: bienvenida, básicos, disponibilidad, objetivo opcional.
/// - Omitir en cada paso y "Omitir todo" global (crea perfil mínimo).
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
  PlayerPosition _selectedPosition = PlayerPosition.oh;     // enums
  PlayerLevel _selectedLevel = PlayerLevel.competitivo;

  final Set<DayOfWeek> _trainingDays = {};                  // enums

  static const List<_MinutesRange> _timeRanges = <_MinutesRange>[
    _MinutesRange(30, 45),
    _MinutesRange(45, 60),
    _MinutesRange(60, 75),
    _MinutesRange(75, 90),
    _MinutesRange(90, 120),
  ];
  int _selectedRangeIndex = 2;
  double _sessionMinutes = 0; // vista previa

  final _goalController = TextEditingController();
  final List<String> _goals = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sessionMinutes = _timeRanges[_selectedRangeIndex].mid.toDouble();
  }

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
      // 1) Rescatamos usuario app para asignar userId
      final appUser = await ref.read(currentUserAppUserProvider.future);
      final uid = appUser?.id;

      // 2) Construimos perfil mínimo coherente con tu modelo
      final profile = PlayerProfile(
        id: const Uuid().v4(),
        userId: uid,
        name: _name.trim().isEmpty ? (appUser?.name ?? 'Jugador') : _name.trim(),
        position: _selectedPosition,                           // enum
        level: _selectedLevel,                                 // enum
        goals: _goals.map((g) => Goal(id: const Uuid().v4(), description: g)).toList(),
        injuries: const [],
        availability: Availability(
          trainingDays: _trainingDays.toList(),               // List<DayOfWeek>
          sessionMinutes: _timeRanges[_selectedRangeIndex].mid, // int
        ),
        evaluationHistory: const [],
        tournaments: const [],
        assignedCoachId: null,
        equipmentIds: const [],
        keyEvents: const [],
        formPeaks: const [],
      );

      // 3) Guardamos
      final firestore = ref.read(firestoreProvider);
      await firestore.upsertPlayerProfile(profile);

      // 4) Refrescamos perfil
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
            initialPosition: _selectedPosition,
            initialLevel: _selectedLevel,
            onSaved: (n, p, l) { _name = n; _selectedPosition = p; _selectedLevel = l; },
            onNext: () { _formKeyBasics.currentState?.save(); _next(); },
            onSkip: _next,
          ),
          _StepAvailability(
            allDaysEnum: DayOfWeek.values,
            trainingDays: _trainingDays,
            timeRanges: _timeRanges,
            selectedRangeIndex: _selectedRangeIndex,
            onToggleDay: (day, enabled) {
              setState(() {
                if (enabled) {
                  _trainingDays.add(day);
                } else {
                  _trainingDays.remove(day);
                }
              });
            },
            onSelectRange: (index) {
              setState(() {
                _selectedRangeIndex = index;
                _sessionMinutes = _timeRanges[index].mid.toDouble(); // preview
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

// --- Paso 2: Básicos (usa enums) ---
class _StepBasics extends StatefulWidget {
  const _StepBasics({
    required this.formKey,
    required this.onSaved,
    required this.onNext,
    required this.onSkip,
    required this.initialPosition,
    required this.initialLevel,
  });
  final GlobalKey<FormState> formKey;
  final void Function(String name, PlayerPosition pos, PlayerLevel lvl) onSaved;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final PlayerPosition initialPosition;
  final PlayerLevel initialLevel;

  @override
  State<_StepBasics> createState() => _StepBasicsState();
}

class _StepBasicsState extends State<_StepBasics> {
  String name = '';
  late PlayerPosition position;
  late PlayerLevel level;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
    level = widget.initialLevel;
  }

  String _label(Enum e) => e.name[0].toUpperCase() + e.name.substring(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: widget.formKey,
        child: ListView(
          children: [
            Text('Cuéntanos de ti', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nombre (opcional)'),
              onSaved: (v) => name = (v ?? '').trim(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PlayerPosition>(
              value: position,
              decoration: const InputDecoration(labelText: 'Posición'),
              items: PlayerPosition.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(_label(p))))
                  .toList(),
              onChanged: (v) => setState(() => position = v ?? position),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PlayerLevel>(
              value: level,
              decoration: const InputDecoration(labelText: 'Nivel'),
              items: PlayerLevel.values
                  .map((l) => DropdownMenuItem(value: l, child: Text(_label(l))))
                  .toList(),
              onChanged: (v) => setState(() => level = v ?? level),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(onPressed: widget.onSkip, child: const Text('Omitir')),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () {
                    widget.formKey.currentState?.save();
                    widget.onSaved(name, position, level);
                    widget.onNext();
                  },
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

// --- Paso 3: Disponibilidad (DayOfWeek + rango de minutos) ---
class _StepAvailability extends StatelessWidget {
  const _StepAvailability({
    required this.allDaysEnum,
    required this.trainingDays,
    required this.timeRanges,
    required this.selectedRangeIndex,
    required this.onToggleDay,
    required this.onSelectRange,
    required this.previewMinutes,
    required this.onNext,
    required this.onSkip,
  });

  final List<DayOfWeek> allDaysEnum;
  final Set<DayOfWeek> trainingDays;
  final List<_MinutesRange> timeRanges;
  final int selectedRangeIndex;

  final void Function(DayOfWeek day, bool enabled) onToggleDay;  // ✅
  final void Function(int index) onSelectRange;
  final double previewMinutes;

  final VoidCallback onNext;
  final VoidCallback onSkip;

  String _dayShort(DayOfWeek d) => {
    DayOfWeek.mon:'Lun', DayOfWeek.tue:'Mar', DayOfWeek.wed:'Mié',
    DayOfWeek.thu:'Jue', DayOfWeek.fri:'Vie', DayOfWeek.sat:'Sáb',
    DayOfWeek.sun:'Dom',
  }[d]!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: allDaysEnum.map((day) {
                final enabled = trainingDays.contains(day);
                return SwitchListTile.adaptive(
                  title: Text(_dayShort(day)),
                  value: enabled,
                  onChanged: (v) => onToggleDay(day, v),        // ✅
                );
              }).toList(),
            ),
          ),
          // ... resto igual
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

  int get mid => ((min + max) / 2).round(); // int para tu modelo
  String get label => '$min–$max min';
}
