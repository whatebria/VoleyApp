// exercise.dart
class Exercise {
  final String name;
  final List<String> tags;
  final String level;
  final String positionFocus;
  final String videoUrl;
  final String equipment;
  final List<String> contraindicatedFor;

  Exercise({
    required this.name,
    required this.tags,
    required this.level,
    required this.positionFocus,
    required this.videoUrl,
    required this.equipment,
    required this.contraindicatedFor,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'tags': tags,
        'level': level,
        'positionFocus': positionFocus,
        'videoUrl': videoUrl,
        'equipment': equipment,
        'contraindicatedFor': contraindicatedFor,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        name: map['name'],
        tags: List<String>.from(map['tags']),
        level: map['level'],
        positionFocus: map['positionFocus'],
        videoUrl: map['videoUrl'],
        equipment: map['equipment'],
        contraindicatedFor: List<String>.from(map['contraindicatedFor']),
      );
}
