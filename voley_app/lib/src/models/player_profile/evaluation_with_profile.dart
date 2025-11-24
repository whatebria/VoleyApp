import 'package:flutter/foundation.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/program.dart';

@immutable
class ProgramWithOwner {
  const ProgramWithOwner({
    required this.program,
    required this.owner,
  });

  final Program program;
  final PlayerProfile owner;
}