class Availability {
  final List<String> trainingDays;
  final int sessionMinutes;

  Availability({required this.trainingDays, required this.sessionMinutes});

  Map<String, dynamic> toJson() => {
        'trainingDays': trainingDays,
        'sessionMinutes': sessionMinutes,
      };

  static Availability fromJson(Map<String, dynamic> json) => Availability(
        trainingDays: List<String>.from(json['trainingDays'] ?? []),
        sessionMinutes: json['sessionMinutes'] ?? 60,
      );
}