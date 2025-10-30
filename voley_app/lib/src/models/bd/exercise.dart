class Exercise {
  final String name;
  final List<String> tags;
  final String level; // beginner, intermediate, advanced
  final String positionFocus; // all, setter, middle, opposite, libero, outside
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

  /// Método para convertir un objeto Exercise a un Map<String, dynamic>
  /// Esto es necesario para subir los datos a Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tags': tags,
      'level': level,
      'positionFocus': positionFocus,
      'videoUrl': videoUrl,
      'equipment': equipment,
      'contraindicatedFor': contraindicatedFor,
    };
  }
}
