import 'package:flutter/foundation.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';

@immutable
class EvaluationWithProfile {
  const EvaluationWithProfile({
    required this.profile,
    required this.evaluation,
  });

  final PlayerProfile profile;
  final EvaluationResult evaluation;
}