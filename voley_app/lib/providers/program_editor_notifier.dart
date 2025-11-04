import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/mesocycles.dart';
import 'package:voley_app/providers/providers.dart'; // Para explorerProgramsProvider y firestoreProvider

/// Manages the state of a single Program being edited.
/// This centralizes the logic for updating, adding/removing blocks,
/// and saving to Firestore.
class ProgramEditorNotifier extends StateNotifier<Program?> {
  final Ref _ref;
  String? _profileId;
  bool _isSaving = false; // Prevents concurrent saves

  ProgramEditorNotifier(this._ref) : super(null);

  /// Loads a program into the editor and stores the profile ID for saving.
  void init(Program program, String profileId) {
    state = program;
    _profileId = profileId;
  }

  /// Saves the current state to Firestore.
  Future<void> _saveState() async {
    if (state == null || _profileId == null || _isSaving) return;

    _isSaving = true;
    try {
      // Recalculate end date before saving
      final totalWeeks = state!.mesocycles.fold<int>(0, (sum, meso) => sum + meso.weeks);
      final programToSave = state!.copyWith(
        endDate: state!.startDate.add(Duration(days: totalWeeks * 7)),
      );

      final firestore = _ref.read(firestoreProvider);
      await firestore.saveProgram(_profileId!, programToSave);
      
      // Update state with the final calculated dates
      // (Comprobamos si el widget sigue montado por si acaso)
      if (mounted) {
        state = programToSave;
      }
      
      // Invalidate the main list provider so the explorer screen is fresh
      _ref.invalidate(explorerProgramsProvider);
    } catch (e) {
      // Handle error (e.g., show a toast)
      print("Error saving program: $e");
      // Optionally re-throw or notify UI
    } finally {
      _isSaving = false;
    }
  }

  /// Updates the title of the program.
  void updateTitle(String newTitle) {
    if (state == null) return;
    final title = newTitle.isEmpty ? 'Programa sin título' : newTitle;
    state = state!.copyWith(title: title);
    _saveState(); // Asynchronously save
  }

  /// Adds a new Mesocycle (Bloque) to the program.
  void addBlock(Mesocycle newBlock) {
    if (state == null) return;
    final newBlocks = List<Mesocycle>.from(state!.mesocycles)..insert(0, newBlock);
    state = state!.copyWith(mesocycles: newBlocks);
    _saveState();
  }

  /// Updates an existing Mesocycle in the program.
  void updateBlock(Mesocycle updatedBlock) {
    if (state == null) return;
    final newBlocks = state!.mesocycles.map((b) {
      return (b.id == updatedBlock.id) ? updatedBlock : b;
    }).toList();
    state = state!.copyWith(mesocycles: newBlocks);
    _saveState();
  }

  /// Deletes a Mesocycle from the program.
  void deleteBlock(Mesocycle blockToDelete) {
    if (state == null) return;
    final newBlocks = state!.mesocycles.where((b) => b.id != blockToDelete.id).toList();
    state = state!.copyWith(mesocycles: newBlocks);
    _saveState();
  }
}


