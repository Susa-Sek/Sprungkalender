import 'package:flutter/foundation.dart';

import '../data/spruenge.dart';

/// Mitternacht des Tages — wie `dayOf` in Täglich Klüger.
///
/// Alles hier rechnet in ganzen Tagen. Eine Uhrzeit im Termin würde ein
/// Fenster um Stunden verschieben, und davon hat niemand etwas.
DateTime tagVon(DateTime moment) =>
    DateTime(moment.year, moment.month, moment.day);

/// Tagesschlüssel „2026-11-18" — für das Tagebuch und die Speicherung.
String tagSchluessel(DateTime moment) {
  final String m = moment.month.toString().padLeft(2, '0');
  final String d = moment.day.toString().padLeft(2, '0');
  return '${moment.year}-$m-$d';
}

/// Der errechnete Termin, aus Geburtsdatum und Abweichung.
///
/// **Warum das nötig ist.** Das Modell rechnet ab dem **errechneten Termin**,
/// nicht ab der Geburt. Bei einem Kind, das sechs Wochen zu früh kam, liegt
/// dazwischen ein Unterschied von sechs Wochen — jeder Sprung wäre um
/// anderthalb Monate verschoben. Das ist die Stelle, an der ein Nachbau als
/// Erstes falsch rechnet.
///
/// [wochenZuFrueh] ist positiv für „zu früh geboren", negativ für „zu spät".
DateTime terminAusGeburt(DateTime geburt, {required int wochenZuFrueh}) =>
    tagVon(geburt).add(Duration(days: wochenZuFrueh * 7));

/// Wo ein Kind heute steht.
@immutable
class SprungStand {
  const SprungStand({
    required this.tageSeitTermin,
    this.laufend,
    this.tageNochImFenster = 0,
    this.naechster,
    this.tageBisNaechster = 0,
  });

  /// Korrigiertes Alter in Tagen, gezählt ab dem errechneten Termin.
  /// Negativ, solange der Termin noch nicht erreicht ist.
  final int tageSeitTermin;

  /// Der Sprung, dessen Fenster gerade offen ist — oder `null`.
  final Sprung? laufend;

  /// Wie viele Tage das offene Fenster noch läuft (mindestens 1).
  final int tageNochImFenster;

  /// Der nächste Sprung, der noch kommt — oder `null` nach dem zehnten.
  final Sprung? naechster;

  /// In wie vielen Tagen er beginnt.
  final int tageBisNaechster;

  /// Korrigiertes Alter in ganzen Wochen. Negativ vor dem Termin.
  int get wochen => tageSeitTermin < 0
      ? -((-tageSeitTermin) ~/ 7)
      : tageSeitTermin ~/ 7;

  /// Vor dem errechneten Termin — ein Frühchen, das noch nicht „Woche 0" ist.
  bool get vorDemTermin => tageSeitTermin < 0;

  /// Alle zehn Fenster liegen hinter uns.
  bool get durch => laufend == null && naechster == null && !vorDemTermin;

  @override
  String toString() => laufend != null
      ? 'Sprung ${laufend!.nummer}, noch $tageNochImFenster Tage'
      : naechster != null
          ? 'Sprung ${naechster!.nummer} in $tageBisNaechster Tagen'
          : 'kein Sprung mehr';
}

/// Was heute ansteht — rein, damit die Randfälle nachrechenbar sind.
///
/// Die Fenster liegen nach [Sprung.startTag] und [Sprung.endTag] in Tagen
/// nach dem Termin. Das Fenster gilt von `startTag` **einschließlich** bis
/// `endTag` **ausschließlich**; so kann kein Tag zu zwei Sprüngen gehören,
/// solange die Fenster sich nicht überschneiden (ein Test hält das fest).
SprungStand berechne({required DateTime termin, required DateTime heute}) {
  final int tage = tagVon(heute).difference(tagVon(termin)).inDays;

  Sprung? laufend;
  Sprung? naechster;
  for (final Sprung s in kSpruenge) {
    if (tage >= s.startTag && tage < s.endTag) {
      laufend = s;
    } else if (tage < s.startTag) {
      naechster ??= s;
    }
  }

  return SprungStand(
    tageSeitTermin: tage,
    laufend: laufend,
    tageNochImFenster: laufend == null ? 0 : laufend.endTag - tage,
    naechster: naechster,
    tageBisNaechster: naechster == null ? 0 : naechster.startTag - tage,
  );
}

/// Wie weit ein Fenster durchlaufen ist, 0 bis 1 — für den Balken.
double fensterFortschritt(SprungStand stand) {
  final Sprung? s = stand.laufend;
  if (s == null) return 0;
  final int vergangen = stand.tageSeitTermin - s.startTag;
  return (vergangen / s.dauerTage).clamp(0, 1).toDouble();
}

/// Liegt dieser Tag in einem Sprungfenster? Für den Hintergrund im Tagebuch.
Sprung? sprungAmTag({required DateTime termin, required DateTime tag}) =>
    berechne(termin: termin, heute: tag).laufend;
