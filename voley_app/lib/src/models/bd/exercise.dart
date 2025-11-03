class Exercise {
  final String id;
  final String name;
  final List<String> tags;
  final String level; // "principiante","intermedio","avanzado"
  final String category;
  final String videoUrl;
  final List<String> equipment;
  final List<String> contraindicatedFor;
  final String description;

  Exercise({
    required this.id,
    required this.name,
    required this.tags,
    required this.level,
    required this.category,
    required this.videoUrl,
    required this.equipment,
    required this.contraindicatedFor,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tags': tags,
        'level': level,
        'category': category,
        'videoUrl': videoUrl,
        'equipment': equipment,
        'contraindicatedFor': contraindicatedFor,
        'description': description,
      };

  static Exercise fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Ejercicio',
        tags: List<String>.from(json['tags'] ?? []),
        level: json['level'] as String? ?? 'principiante',
        category: json['category'] as String? ?? 'general',
        videoUrl: json['videoUrl'] as String? ?? '',
        equipment: List<String>.from(json['equipment'] ?? []),
        contraindicatedFor: List<String>.from(json['contraindicatedFor'] ?? []),
        description: json['description'] as String? ?? '',
      );
}
