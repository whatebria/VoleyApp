// lib/src/screens/player_evaluation_screen.dart (CORREGIDO)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
import 'package:voley_app/src/services/firestore_service.dart';
import 'package:intl/intl.dart';

class PlayerEvaluationScreen extends ConsumerStatefulWidget {
  const PlayerEvaluationScreen({super.key});

  @override
  ConsumerState<PlayerEvaluationScreen> createState() =>
      _PlayerEvaluationScreenState();
}

class _PlayerEvaluationScreenState extends ConsumerState<PlayerEvaluationScreen> {
  // --- Estado del Formulario y Controladores ---
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  String selectedPosition = 'Central';
  String selectedLevel = 'Competitivo';
  List<Tournament> _selectedTournaments = [];
  List<String> selectedInjuries = [];
  Map<String, double> _testScores = {};
  List<String> selectedDays = [];
  final List<String> _allDays = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];
  final Map<String, int> _durationOptions = {
    '30-45 minutos': 45, '45-60 minutos': 60, '60-75 minutos': 75,
    '75-90 minutos': 90, '90+ minutos': 120,
  };
  int _selectedDurationMinutes = 60;

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
      final userName = ref.read(currentUserAppUserProvider).value?.name ?? 'Jugador';
      setState(() {
        _loadedProfile = null;
        nameCtrl.text = userName;
        selectedPosition = 'Central';
        selectedLevel = 'Competitivo';
        selectedDays = [];
        _selectedDurationMinutes = 60;
        selectedInjuries = ['Ninguna'];
        _selectedTournaments = [];
        _testScores = {};
      });
      return;
    }

    // Si p tiene datos, cargamos el formulario para editar
    setState(() {
      _loadedProfile = p;
      nameCtrl.text = p.name;
      selectedPosition = p.position;
      selectedLevel = p.level.isNotEmpty ? p.level[0].toUpperCase() + p.level.substring(1) : 'Competitivo';
      selectedDays = p.availability.trainingDays;
      _selectedDurationMinutes = p.availability.sessionMinutes;
      selectedInjuries = p.injuries.isEmpty ? ['Ninguna'] : p.injuries;
      _selectedTournaments = p.tournaments;
      _testScores = Map.from(p.evaluation.testScores); // Copia defensiva
    });
  }


  @override
  void dispose() {
    nameCtrl.dispose();
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
                      validator: (v) =>
                          (v?.isEmpty ?? true) ? 'El nombre es requerido' : null,
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
                          lastDate: DateTime.now().add(const Duration(days: 365)),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final tournament = Tournament(
                        name: nameCtrl.text.trim(),
                        date: selectedDate,
                      );
                      Navigator.pop(context, tournament);
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
    final testsSnapshot = await ref.read(firestoreProvider).firestore
        .collection('tests')
        .get();
    
    final availableTests = testsSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc.data()['name'] as String? ?? 'Sin nombre',
              'measure': doc.data()['measure'] as String? ?? '',
            })
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'La puntuación es requerida';
                        if (double.tryParse(v!) == null) return 'Ingresa un número válido';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final score = double.parse(scoreCtrl.text.trim());
                      Navigator.pop(
                        context,
                        MapEntry(selectedTestName, score),
                      );
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
      _showError('Error: No se pudo identificar al jugador. Intenta cerrar y abrir sesión.');
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

      if (_loadedProfile != null) {
        // --- ACTUALIZAR Perfil Existente ---
        profileToSave = _loadedProfile!.copyWith(
          position: selectedPosition,
          level: selectedLevel.toLowerCase(),
          injuries: selectedInjuries.contains('Ninguna') ? [] : selectedInjuries,
          availability: availability,
          evaluation: evaluation,
          tournaments: _selectedTournaments,
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
          goals: [], 
          injuries: selectedInjuries.contains('Ninguna') ? [] : selectedInjuries,
          availability: availability,
          evaluation: evaluation,
          tournaments: _selectedTournaments,
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
        Navigator.pop(context); 
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
                  child: Text('Error al cargar datos: $e', textAlign: TextAlign.center),
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

                      _buildSectionHeader(theme, Icons.calendar_today, "Disponibilidad"),
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
                )
              ],
            );
          }),
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
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
              decoration: const InputDecoration(labelText: 'Posición Principal'),
              items: ['Central', 'Libero', 'Punta', 'Opuesto', 'Armadora']
                  .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                  .toList(),
              onChanged: (newValue) => setState(() => selectedPosition = newValue!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedLevel,
              decoration: const InputDecoration(labelText: 'Nivel de Juego'),
              items: ['Competitivo', 'Recreativo']
                  .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                  .toList(),
              onChanged: (newValue) => setState(() => selectedLevel = newValue!),
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
                    children: _allDays.sublist(0, 4).map((day) => CheckboxListTile(
                          title: Text(day),
                          value: selectedDays.contains(day),
                          onChanged: (v) => setState(() => v! ? selectedDays.add(day) : selectedDays.remove(day)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        )).toList(),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: _allDays.sublist(4).map((day) => CheckboxListTile(
                          title: Text(day),
                          value: selectedDays.contains(day),
                          onChanged: (v) => setState(() => v! ? selectedDays.add(day) : selectedDays.remove(day)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        )).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedDurationMinutes,
              decoration: const InputDecoration(labelText: 'Duración por Sesión'),
              items: _durationOptions.entries
                  .map((entry) => DropdownMenuItem<int>(value: entry.value, child: Text(entry.key)))
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) setState(() => _selectedDurationMinutes = newValue);
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
          children: [ 'Rodilla', 'Tobillo', 'Hombro', 'Espalda', 'Muñeca', 'Dedo', 'Ninguna']
              .map((injury) {
            final isSelected = selectedInjuries.contains(injury);
            return FilterChip(
              label: Text(injury),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary, // Volt
              labelStyle: TextStyle(
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              ),
              onSelected: (bool selected) {
                setState(() {
                  if (injury == 'Ninguna') {
                    selectedInjuries.clear();
                    if (selected) selectedInjuries.add('Ninguna');
                  } else {
                    selectedInjuries.remove('Ninguna');
                    if (selected) selectedInjuries.add(injury);
                    else selectedInjuries.remove(injury);
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
                Text('Tests Físicos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  onPressed: _showAddTestDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir'),
                  // --- MEJORA DE DISEÑO: Botón "Volt Pro" ---
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary, side: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
            if (_testScores.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('Añade tus puntuaciones (ej: Salto Vertical)...', style: TextStyle(color: Colors.grey)),
              )
            else
              ..._testScores.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  trailing: Text(entry.value.toString(), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 16),
                  onTap: () => setState(() => _testScores.remove(entry.key)),
                  leading: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error, size: 20),
                );
              }).toList(),
            
            const Divider(height: 24),

            // --- Torneos ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Torneos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  onPressed: _showAddTournamentDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir'),
                  // --- MEJORA DE DISEÑO: Botón "Azul Pro" ---
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.secondary, side: BorderSide(color: theme.colorScheme.secondary),
                  ),
                ),
              ],
            ),
            if (_selectedTournaments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('Añade torneos (opcional)...', style: TextStyle(color: Colors.grey)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _selectedTournaments.map((tournament) {
                    return Chip(
                      label: Text('${tournament.name} (${DateFormat('dd/MM/yy').format(tournament.date)})'),
                      deleteIcon: const Icon(Icons.cancel, size: 18),
                      onDeleted: () => setState(() => _selectedTournaments.remove(tournament)),
                    );
                  }).toList(),
                ),
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
          )
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}