// lib/src/models/shared/day_of_week.dart
enum DayOfWeek { mon, tue, wed, thu, fri, sat, sun }

extension DayOfWeekLabel on DayOfWeek {
  String get shortEs => const {
    DayOfWeek.mon: 'Lun',
    DayOfWeek.tue: 'Mar',
    DayOfWeek.wed: 'Mié',
    DayOfWeek.thu: 'Jue',
    DayOfWeek.fri: 'Vie',
    DayOfWeek.sat: 'Sáb',
    DayOfWeek.sun: 'Dom',
  }[this]!;

  String get longEs => const {
    DayOfWeek.mon: 'Lunes',
    DayOfWeek.tue: 'Martes',
    DayOfWeek.wed: 'Miércoles',
    DayOfWeek.thu: 'Jueves',
    DayOfWeek.fri: 'Viernes',
    DayOfWeek.sat: 'Sábado',
    DayOfWeek.sun: 'Domingo',
  }[this]!;
}
