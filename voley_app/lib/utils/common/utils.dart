import 'package:flutter/foundation.dart';

@immutable
class ModelUtils {
  const ModelUtils._();

  /// Convierte enum por nombre con fallback seguro.
  static T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null) return fallback;
    try { return values.byName(name); } catch (_) { return fallback; }
  }

  /// Intenta parsear DateTime desde String/DateTime/Timestamp.
  static DateTime? parseDateFlex(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    // Firestore Timestamp: tiene toDate()
    final hasToDate = (v is dynamic) && (v as dynamic).toString().contains('Timestamp');
    try {
      if (hasToDate && v.toDate is Function) return (v as dynamic).toDate();
    } catch (_) {}
    if (v is String) {
      try { return DateTime.parse(v); } catch (_) {}
    }
    return null;
  }

  static String? isoOrNull(DateTime? dt) => dt?.toIso8601String();
}
