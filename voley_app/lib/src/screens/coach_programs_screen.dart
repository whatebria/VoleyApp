import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/screens/program_view/program_explorer_screen.dart';

class CoachProgramsScreen extends ConsumerWidget {
  const CoachProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ProgramExplorerScreen(showAllPlayers: true);
  }
}