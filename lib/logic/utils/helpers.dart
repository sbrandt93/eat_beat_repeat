// lib/utils/date_utils.dart

/// Formatiert ein [DateTime]-Objekt in das Format 'dd.MM.yyyy'.
///
/// Beispiel: formatDateTime(DateTime(2025, 1, 9)) gibt "09.01.2025" zurück.
String formatDateTime(DateTime date) {
  // Fügt eine führende Null hinzu, wenn der Wert einstellig ist (z.B. 01 statt 1).
  String twoDigits(int n) => n.toString().padLeft(2, '0');

  final day = twoDigits(date.day);
  final month = twoDigits(date.month);
  final year = date.year.toString();

  return '$day.$month.$year'; // Ergebnis: dd.MM.yyyy
}

// Optional: Wenn Sie auch die Uhrzeit formatieren möchten:
// String formatDateTimeWithTime(DateTime date) {
//   // ... zusätzliche Logik für Stunden und Minuten ...
// }

/// Berechnet die Differenz zwischen zwei [DateTime]-Objekten und gibt die zeit in tagen, stunden, minuten oder sekunden zurück.

String timeDifference(DateTime from, DateTime to) {
  final difference = to.difference(from);

  if (difference.inDays > 0) {
    return '${difference.inDays} Tage';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} Stunden';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} Minuten';
  } else {
    return '${difference.inSeconds} Sekunden';
  }
}

const autoDeleteDuration = Duration(days: 30);
