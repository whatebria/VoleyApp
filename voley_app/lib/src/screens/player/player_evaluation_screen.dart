// lib/src/screens/player_evaluation_screen.dart (CORREGIDO)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
import 'package:voley_app/src/models/player_profile/player_event.dart';
import 'package:voley_app/src/models/player_profile/form_peak.dart';
import 'package:voley_app/src/services/firestore_service.dart';
import 'package:intl/intl.dart';

class PlayerEvaluationScreen extends ConsumerStatefulWidget {
  const PlayerEvaluationScreen({super.key});

  @override
  ConsumerState<PlayerEvaluationScreen> createState() =>
      _PlayerEvaluationScreenState();
}

class _PlayerEvaluationScreenState
    extends ConsumerState<PlayerEvaluationScreen> {
  // --- Estado del Formulario y Controladores ---
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final wingspanCtrl = TextEditingController();
  String selectedPosition = 'Central';
  String selectedLevel = 'Competitivo';
  List<Tournament> _selectedTournaments = [];
  List<String> selectedInjuries = [];
  Map<String, double> _testScores = {};
  List<String> selectedDays = [];
  List<String> _goals = [];
  List<PlayerEvent> _keyEvents = [];
  List<FormPeak> _formPeaks = [];
  final List<String> _allDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  final Map<String, int> _durationOptions = {
    '30-45 minutos': 45,
    '45-60 minutos': 60,
    '60-75 minutos': 75,
    '75-90 minutos': 90,
    '90+ minutos': 120,
  };
  int _selectedDurationMinutes = 60;

  String _eventTypeLabel(String type) {
    switch (type) {
      case 'cup':
        return 'Copa';
      case 'playoff':
        return 'Play-offs';
      case 'national_team':
        return 'Selección';
      case 'travel':
        return 'Viaje';
      case 'league':
      default:
        return 'Liga';
    }
  }

  // --- Estado de la Pantalla ---
  late final FirestoreService _firestoreService;
  PlayerProfile? _loadedProfile; // Usado para saber si es CREAR o EDITAR
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _firestoreService = ref.read(firestoreProvider);
    // [CORRECCIÓN] Eliminamos toda la lógica de carga de initState
  }

  // Lógica de llenado de formulario
  void _populateForm(PlayerProfile? p) {
    // Si p es null, se usa para inicializar un formulario nuevo
    if (p == null) {
      final userName =
          ref.read(currentUserAppUserProvider).value?.name ?? 'Jugador';
      setState(() {
        _loadedProfile = null;
        nameCtrl.text = userName;
        ageCtrl.clear();
        heightCtrl.clear();
        weightCtrl.clear();
        wingspanCtrl.clear();
        selectedPosition = 'Central';
        selectedLevel = 'Competitivo';
        selectedDays = [];
        _selectedDurationMinutes = 60;
        selectedInjuries = ['Ninguna'];
        _selectedTournaments = [];
        _testScores = {};
        _goals = [];
        _keyEvents = [];
        _formPeaks = [];
      });
      return;
    }

    // Si p tiene datos, cargamos el formulario para editar
    setState(() {
      _loadedProfile = p;
      nameCtrl.text = p.name;
      ageCtrl.text = p.age?.toString() ?? '';
      heightCtrl.text = p.heightCm?.toString() ?? '';
      weightCtrl.text = p.weightKg?.toString() ?? '';
      wingspanCtrl.text = p.wingspanCm?.toString() ?? '';
      selectedPosition = p.position;
      selectedLevel = p.level.isNotEmpty
          ? p.level[0].toUpperCase() + p.level.substring(1)
          : 'Competitivo';
      selectedDays = p.availability.trainingDays;
      _selectedDurationMinutes = p.availability.sessionMinutes;
      selectedInjuries = p.injuries.isEmpty ? ['Ninguna'] : p.injuries;
      _selectedTournaments = p.tournaments;
      _testScores = Map.from(p.evaluation.testScores); // Copia defensiva
      _goals = List.from(p.goals);
      _keyEvents = List.from(p.keyEvents);
      _formPeaks = List.from(p.formPeaks);
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    ageCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    wingspanCtrl.dispose();
    super.dispose();
  }

  // --- Diálogos ---
  Future<void> _showAddTournamentDialog() async {
    final nameCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Tournament>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Añadir Torneo'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Torneo *',
                        prefixIcon: Icon(Icons.emoji_events),
                        helperText: 'Ej: Copa Nacional 2024',
                      ),
                      validator: (v) => (v?.isEmpty ?? true)
                          ? 'El nombre es requerido'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Fecha del Torneo'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).maybePop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final tournament = Tournament(
                        name: nameCtrl.text.trim(),
                        date: selectedDate,
                      );
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pop(tournament);
                    }
                  },
                  child: const Text('Añadir'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _selectedTournaments.add(result));
    }
    nameCtrl.dispose();
  }

  Future<void> _showAddTestDialog() async {
    final scoreCtrl = TextEditingController();
    String? selectedTestId;
    String selectedTestName = '';
    String selectedTestMeasure = '';
    final formKey = GlobalKey<FormState>();

    // Fetch available tests from Firestore
    final testsSnapshot = await ref
        .read(firestoreProvider)
        .firestore
        .collection('tests')
        .get();

    final availableTests = testsSnapshot.docs
        .map(
          (doc) => {
            'id': doc.id,
            'name': doc.data()['name'] as String? ?? 'Sin nombre',
            'measure': doc.data()['measure'] as String? ?? '',
          },
        )
        .toList();

    if (availableTests.isEmpty) {
      _showError('No hay tests disponibles en la base de datos.');
      return;
    }

    final result = await showDialog<MapEntry<String, double>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Añadir Test Físico'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedTestId,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar Test *',
                        prefixIcon: Icon(Icons.assessment),
                      ),
                      items: availableTests.map((test) {
                        return DropdownMenuItem<String>(
                          value: test['id'] as String,
                          child: Text(test['name'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedTestId = value;
                          final test = availableTests.firstWhere(
                            (t) => t['id'] == value,
                          );
                          selectedTestName = test['name'] as String;
                          selectedTestMeasure = test['measure'] as String;
                        });
                      },
                      validator: (v) => v == null ? 'Selecciona un test' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: scoreCtrl,
                      decoration: InputDecoration(
                        labelText: 'Puntuación *',
                        prefixIcon: const Icon(Icons.score),
                        suffixText: selectedTestMeasure.isNotEmpty
                            ? selectedTestMeasure
                            : '',
                        helperText: 'Ingresa el resultado del test',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true)
                          return 'La puntuación es requerida';
                        if (double.tryParse(v!) == null)
                          return 'Ingresa un número válido';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).maybePop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final score = double.parse(scoreCtrl.text.trim());
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pop(MapEntry(selectedTestName, score));
                    }
                  },
                  child: const Text('Añadir'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _testScores[result.key] = result.value);
    }
    scoreCtrl.dispose();
  }

  Future<void> _showAddGoalDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Objetivo'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Objetivo',
              helperText: 'Ej: Aumentar fuerza de saque',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).maybePop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pop(controller.text.trim());
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => _goals.add(result));
    }
    controller.dispose();
  }

  Future<void> _showAddEventDialog() async {
    const eventOptions = {
      'league': 'Liga',
      'cup': 'Copa',
      'playoff': 'Play-offs',
      'national_team': 'Selección',
      'travel': 'Viaje',
    };

    String selectedType = 'league';
    DateTime selectedDate = DateTime.now();
    final descriptionCtrl = TextEditingController();

    final result = await showDialog<PlayerEvent>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Agregar Fecha Clave'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de evento',
                    ),
                    items: eventOptions.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Fecha'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  TextField(
                    controller: descriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      helperText: 'Ej: Liga Nacional',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).maybePop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop(
                      PlayerEvent(
                        type: selectedType,
                        date: selectedDate,
                        description: descriptionCtrl.text.trim().isEmpty
                            ? null
                            : descriptionCtrl.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _keyEvents.add(result));
    }
    descriptionCtrl.dispose();
  }

  Future<void> _showAddFormPeakDialog() async {
    DateTime selectedDate = DateTime.now();
    final noteCtrl = TextEditingController();

    final result = await showDialog<FormPeak>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar Pico de Forma'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Fecha estimada'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                      helperText: 'Ej: Preparar pico para finales',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).maybePop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop(
                      FormPeak(
                        date: selectedDate,
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _formPeaks.add(result));
    }
    noteCtrl.dispose();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() == false) {
      _showError('Por favor revisa los campos con errores.');
      return;
    }

    final appUserAsync = ref.read(currentUserAppUserProvider);
    final appUser = appUserAsync.value;

    if (appUser == null) {
      _showError(
        'Error: No se pudo identificar al jugador. Intenta cerrar y abrir sesión.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      PlayerProfile profileToSave;
      final availability = Availability(
        trainingDays: selectedDays,
        sessionMinutes: _selectedDurationMinutes,
      );
      final evaluation = EvaluationResult(
        testScores: _testScores,
        // Conservamos fortalezas/debilidades si existen
        strengths: _loadedProfile?.evaluation.strengths ?? [],
        weaknesses: _loadedProfile?.evaluation.weaknesses ?? [],
      );

      int? parseAge(String value) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return null;
        return int.tryParse(trimmed);
      }

      double? parseDouble(String value) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return null;
        return double.tryParse(trimmed.replaceAll(',', '.'));
      }

      if (_loadedProfile != null) {
        // --- ACTUALIZAR Perfil Existente ---
        profileToSave = _loadedProfile!.copyWith(
          position: selectedPosition,
          level: selectedLevel.toLowerCase(),
          injuries: selectedInjuries.contains('Ninguna')
              ? []
              : selectedInjuries,
          availability: availability,
          evaluation: evaluation,
          tournaments: _selectedTournaments,
          goals: _goals,
          age: parseAge(ageCtrl.text),
          heightCm: parseDouble(heightCtrl.text),
          weightKg: parseDouble(weightCtrl.text),
          wingspanCm: parseDouble(wingspanCtrl.text),
          keyEvents: _keyEvents,
          formPeaks: _formPeaks,
        );
      } else {
        // --- CREAR Perfil Nuevo ---
        profileToSave = PlayerProfile(
          id: const Uuid().v4(),
          userId: appUser.id,
          assignedCoachId: appUser.coachId ?? "",
          name: nameCtrl.text.trim(),
          position: selectedPosition,
          level: selectedLevel.toLowerCase(),
          goals: _goals,
          injuries: selectedInjuries.contains('Ninguna')
              ? []
              : selectedInjuries,
          availability: availability,
          evaluation: evaluation,
          tournaments: _selectedTournaments,
          age: parseAge(ageCtrl.text),
          heightCm: parseDouble(heightCtrl.text),
          weightKg: parseDouble(weightCtrl.text),
          wingspanCm: parseDouble(wingspanCtrl.text),
          keyEvents: _keyEvents,
          formPeaks: _formPeaks,
        );
      }

      await _firestoreService.savePlayerProfile(profileToSave);

      // --- [CORRECCIÓN CRÍTICA] INVALIDACIÓN DE PROVIDERS ---
      // Invalidamos el FutureProvider original (que carga el perfil)
      ref.invalidate(playerProfileProvider);
      // El generatedProgramProvider depende de playerProfileProvider, se actualizará solo.
      // ----------------------------------------------------

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('Error al guardar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // [CORRECCIÓN] Observamos el FutureProvider completo
    final profileAsync = ref.watch(playerProfileProvider);

    // [CORRECCIÓN] Escuchamos los cambios para llenar el formulario una vez
    ref.listen<AsyncValue<PlayerProfile?>>(playerProfileProvider, (_, next) {
      // El 'listen' solo se activa cuando el provider resuelve o cambia.
      next.whenOrNull(
        data: (profile) {
          // Comprobamos si es la carga inicial o si el perfil ha cambiado
          // forzamos el llenado solo si _loadedProfile es null (primera carga)
          // o si el profile es diferente.
          if (_loadedProfile == null || profile?.id != _loadedProfile?.id) {
            _populateForm(profile);
          }
        },
        // Si hay un error al cargar, también inicializamos el formulario vacío
        error: (_, __) => _populateForm(null),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_loadedProfile == null ? 'Crear Perfil' : 'Editar Perfil'),
      ),
      // [CORRECCIÓN] Usamos profileAsync.when para el estado principal de la pantalla
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Error al cargar datos: $e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (profile) {
          // El resto del formulario se mantiene igual, ya que usa los estados locales
          return Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
                  children: [
                    _buildSectionHeader(theme, Icons.person, "Perfil Básico"),
                    _buildPerfilSection(theme),
                    const SizedBox(height: 24),

                    _buildSectionHeader(
                      theme,
                      Icons.calendar_today,
                      "Disponibilidad",
                    ),
                    _buildDisponibilidadSection(theme),
                    const SizedBox(height: 24),

                    _buildSectionHeader(theme, Icons.healing, "Estado Físico"),
                    _buildEstadoFisicoSection(theme),
                    const SizedBox(height: 24),

                    _buildSectionHeader(theme, Icons.bar_chart, "Rendimiento"),
                    _buildRendimientoSection(theme),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildStickySaveButton(theme, _isSubmitting),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.secondary), // Azul Pro
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// --- Sección 1: Widget de Perfil ---
  Widget _buildPerfilSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: nameCtrl,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Nombre',
                filled: true,
                fillColor: theme.colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedPosition,
              decoration: const InputDecoration(
                labelText: 'Posición Principal',
              ),
              items: ['Central', 'Libero', 'Punta', 'Opuesto', 'Armadora']
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (newValue) =>
                  setState(() => selectedPosition = newValue!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedLevel,
              decoration: const InputDecoration(labelText: 'Nivel de Juego'),
              items: ['Competitivo', 'Recreativo']
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (newValue) =>
                  setState(() => selectedLevel = newValue!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: ageCtrl,
              decoration: const InputDecoration(
                labelText: 'Edad',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final parsed = int.tryParse(value.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Ingresa una edad válida';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: heightCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Altura (cm)',
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      return double.tryParse(value.replaceAll(',', '.')) == null
                          ? 'Número inválido'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: weightCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Peso (kg)',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      return double.tryParse(value.replaceAll(',', '.')) == null
                          ? 'Número inválido'
                          : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: wingspanCtrl,
              decoration: const InputDecoration(
                labelText: 'Envergadura (cm)',
                prefixIcon: Icon(Icons.swap_horiz_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return double.tryParse(value.replaceAll(',', '.')) == null
                    ? 'Número inválido'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Objetivos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  tooltip: 'Agregar objetivo',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _showAddGoalDialog,
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _goals.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Define objetivos específicos que guíen tu progreso.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _goals
                          .map(
                            (goal) => Chip(
                              label: Text(goal),
                              deleteIcon: const Icon(Icons.cancel, size: 18),
                              onDeleted: () =>
                                  setState(() => _goals.remove(goal)),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// --- Sección 2: Widget de Disponibilidad ---
  Widget _buildDisponibilidadSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- MEJORA DE UI: Checkboxes en 2 columnas ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: _allDays
                        .sublist(0, 4)
                        .map(
                          (day) => CheckboxListTile(
                            title: Text(day),
                            value: selectedDays.contains(day),
                            onChanged: (v) => setState(
                              () => v!
                                  ? selectedDays.add(day)
                                  : selectedDays.remove(day),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: _allDays
                        .sublist(4)
                        .map(
                          (day) => CheckboxListTile(
                            title: Text(day),
                            value: selectedDays.contains(day),
                            onChanged: (v) => setState(
                              () => v!
                                  ? selectedDays.add(day)
                                  : selectedDays.remove(day),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedDurationMinutes,
              decoration: const InputDecoration(
                labelText: 'Duración por Sesión',
              ),
              items: _durationOptions.entries
                  .map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry.value,
                      child: Text(entry.key),
                    ),
                  )
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null)
                  setState(() => _selectedDurationMinutes = newValue);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// --- Sección 3: Widget de Estado Físico ---
  Widget _buildEstadoFisicoSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children:
              [
                'Rodilla',
                'Tobillo',
                'Hombro',
                'Espalda',
                'Muñeca',
                'Dedo',
                'Ninguna',
              ].map((injury) {
                final isSelected = selectedInjuries.contains(injury);
                return FilterChip(
                  label: Text(injury),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary, // Volt
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      if (injury == 'Ninguna') {
                        selectedInjuries.clear();
                        if (selected) selectedInjuries.add('Ninguna');
                      } else {
                        selectedInjuries.remove('Ninguna');
                        if (selected)
                          selectedInjuries.add(injury);
                        else
                          selectedInjuries.remove(injury);
                      }
                    });
                  },
                );
              }).toList(),
        ),
      ),
    );
  }

  /// --- Sección 4: Widget de Rendimiento ---
  Widget _buildRendimientoSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Tests Físicos ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tests Físicos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showAddTestDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir'),
                  // --- MEJORA DE DISEÑO: Botón "Volt Pro" ---
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
            if (_testScores.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Añade tus puntuaciones (ej: Salto Vertical)...',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._testScores.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  trailing: Text(
                    entry.value.toString(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 16),
                  onTap: () => setState(() => _testScores.remove(entry.key)),
                  leading: Icon(
                    Icons.remove_circle_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                );
              }).toList(),

            const Divider(height: 24),

            // --- Torneos ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Torneos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showAddTournamentDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir'),
                  // --- MEJORA DE DISEÑO: Botón "Azul Pro" ---
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.secondary,
                    side: BorderSide(color: theme.colorScheme.secondary),
                  ),
                ),
              ],
            ),
            if (_selectedTournaments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Añade torneos (opcional)...',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _selectedTournaments.map((tournament) {
                    return Chip(
                      label: Text(
                        '${tournament.name} (${DateFormat('dd/MM/yy').format(tournament.date)})',
                      ),
                      deleteIcon: const Icon(Icons.cancel, size: 18),
                      onDeleted: () => setState(
                        () => _selectedTournaments.remove(tournament),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fechas Clave',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showAddEventDialog,
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: const Text('Añadir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
            if (_keyEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Registra ligas, copas, selecciones o viajes próximos.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._keyEvents.map(
                (event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.flag_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                  title: Text(
                    '${_eventTypeLabel(event.type)} - ${DateFormat('dd/MM/yy').format(event.date)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: event.description != null
                      ? Text(event.description!)
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _keyEvents.remove(event)),
                  ),
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Picos de Forma',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showAddFormPeakDialog,
                  icon: const Icon(Icons.trending_up, size: 18),
                  label: const Text('Añadir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
            if (_formPeaks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Planifica cuándo quieres alcanzar tu máximo rendimiento.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _formPeaks
                    .map(
                      (peak) => Chip(
                        label: Text(
                          '${DateFormat('dd/MM/yy').format(peak.date)}${peak.note != null ? ' • ${peak.note}' : ''}',
                        ),
                        deleteIcon: const Icon(Icons.cancel, size: 18),
                        onDeleted: () =>
                            setState(() => _formPeaks.remove(peak)),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  /// --- MEJORA DE UI: Botón de Guardar Pegajoso ---
  Widget _buildStickySaveButton(ThemeData theme, bool isSubmitting) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, // Color de fondo del scaffold
        // --- MEJORA DE DISEÑO: Sombra para separar ---
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: isSubmitting
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : Text(
                  _loadedProfile == null ? 'Crear Perfil' : 'Actualizar Perfil',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
