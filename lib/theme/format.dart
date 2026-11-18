/// Datumsangaben auf Deutsch — ohne `intl`, weil es nur diese zwei Formen
/// braucht und sie an drei Stellen gleich aussehen sollen.
library;

const List<String> _monate = <String>[
  'Januar',
  'Februar',
  'März',
  'April',
  'Mai',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'Dezember',
];

const List<String> _wochentage = <String>[
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];

/// „12. März 2026"
String datumLang(DateTime d) => '${d.day}. ${_monate[d.month - 1]} ${d.year}';

/// „Donnerstag, 5. Februar" — mit Jahr, wenn es nicht [bezugsJahr] ist.
String datumMitWochentag(DateTime d, {int? bezugsJahr}) {
  final String ohneJahr =
      '${_wochentage[d.weekday - 1]}, ${d.day}. ${_monate[d.month - 1]}';
  return d.year == bezugsJahr ? ohneJahr : '$ohneJahr ${d.year}';
}
