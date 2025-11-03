import 'package:cloud_firestore/cloud_firestore.dart';

class FormPeak {
  final DateTime date;
  final String? note;

  const FormPeak({
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'date': Timestamp.fromDate(date),
        'note': note,
      };

  static FormPeak fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    DateTime parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return FormPeak(
      date: parsedDate,
      note: json['note'] as String?,
    );
  }

  FormPeak copyWith({
    DateTime? date,
    String? note,
  }) {
    return FormPeak(
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
