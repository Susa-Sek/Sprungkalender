import 'package:flutter_test/flutter_test.dart';

import 'package:sprungkalender/data/spruenge.dart';
import 'package:sprungkalender/state/sprung_rechner.dart';

void main() {
  final DateTime termin = DateTime(2026, 1, 1);

  SprungStand amTag(int tage) =>
      berechne(termin: termin, heute: termin.add(Duration(days: tage)));

  group('Gerechnet wird ab dem errechneten Termin', () {
    test('aus Geburtsdatum und Abweichung wird der Termin', () {
      // Sechs Wochen zu früh geboren: Der Termin liegt sechs Wochen nach
      // der Geburt.
      expect(
        terminAusGeburt(DateTime(2026, 1, 1), wochenZuFrueh: 6),
        DateTime(2026, 2, 12),
      );
      // Zwei Wochen zu spät: Der Termin lag zwei Wochen vor der Geburt.
      expect(
        terminAusGeburt(DateTime(2026, 1, 15), wochenZuFrueh: -2),
        DateTime(2026, 1, 1),
      );
      // Pünktlich: Geburt ist der Termin.
      expect(
        terminAusGeburt(DateTime(2026, 1, 1), wochenZuFrueh: 0),
        DateTime(2026, 1, 1),
      );
    });

    test('ein Frühchen landet sechs Wochen anders als bei naiver Rechnung',
        () {
      // Der Fehler, den jeder Nachbau zuerst macht: ab Geburt rechnen.
      final DateTime geburt = DateTime(2026, 1, 1);
      final DateTime echterTermin =
          terminAusGeburt(geburt, wochenZuFrueh: 6);
      final DateTime heute = geburt.add(const Duration(days: 5 * 7));

      // Naiv ab Geburt wäre das Woche 5 — der erste Sprung.
      expect(berechne(termin: geburt, heute: heute).laufend?.nummer, 1);
      // Richtig ab Termin ist das Kind noch gar nicht geboren gewesen.
      final SprungStand richtig =
          berechne(termin: echterTermin, heute: heute);
      expect(richtig.vorDemTermin, isTrue);
      expect(richtig.laufend, isNull);
      expect(richtig.tageSeitTermin, -7);
    });

    test('vor dem Termin gibt es keinen laufenden Sprung', () {
      final SprungStand s = amTag(-20);
      expect(s.vorDemTermin, isTrue);
      expect(s.laufend, isNull);
      expect(s.naechster?.nummer, 1);
      expect(s.tageBisNaechster, 35 + 20);
      expect(s.durch, isFalse);
    });

    test('negative Wochen werden nach unten gezählt', () {
      expect(amTag(-1).wochen, 0);
      expect(amTag(-7).wochen, -1);
      expect(amTag(-13).wochen, -1);
      expect(amTag(-14).wochen, -2);
    });
  });

  group('Die Grenzen eines Fensters', () {
    test('der erste Tag gehört dazu', () {
      final SprungStand s = amTag(5 * 7);
      expect(s.laufend?.nummer, 1);
      expect(s.tageNochImFenster, 7);
      expect(fensterFortschritt(s), 0);
    });

    test('der letzte Tag gehört dazu', () {
      final SprungStand s = amTag(5 * 7 + 6);
      expect(s.laufend?.nummer, 1);
      expect(s.tageNochImFenster, 1, reason: 'heute noch, morgen nicht mehr');
    });

    test('der Tag danach nicht mehr', () {
      final SprungStand s = amTag(5 * 7 + 7);
      expect(s.laufend, isNull);
      expect(s.naechster?.nummer, 2);
    });

    test('der Tag davor nicht', () {
      final SprungStand s = amTag(5 * 7 - 1);
      expect(s.laufend, isNull);
      expect(s.naechster?.nummer, 1);
      expect(s.tageBisNaechster, 1);
    });
  });

  group('Zwischen zwei Sprüngen', () {
    test('kein laufender, aber der nächste steht fest', () {
      final SprungStand s = amTag(10 * 7);
      expect(s.laufend, isNull);
      expect(s.naechster?.nummer, 3, reason: 'Sprung 3 beginnt in Woche 12');
      expect(s.tageBisNaechster, 14);
      expect(s.durch, isFalse);
    });
  });

  group('Nach dem zehnten Sprung', () {
    test('ist nichts mehr offen', () {
      final SprungStand s = amTag(80 * 7);
      expect(s.laufend, isNull);
      expect(s.naechster, isNull);
      expect(s.durch, isTrue);
      expect(s.wochen, 80);
    });
  });

  group('Jeder Sprung ist genau einmal erreichbar', () {
    test('über zwei Jahre hinweg gehört kein Tag zu zwei Sprüngen', () {
      final Set<int> gesehen = <int>{};
      for (int tag = 0; tag < 800; tag++) {
        final SprungStand s = amTag(tag);
        if (s.laufend != null) gesehen.add(s.laufend!.nummer);
      }
      expect(gesehen, <int>{1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
          reason: 'alle zehn kommen vor');
    });

    test('die Summe der Fenstertage stimmt mit der Dauer überein', () {
      for (final Sprung sprung in kSpruenge) {
        int tageInDiesemFenster = 0;
        for (int tag = 0; tag < 800; tag++) {
          if (amTag(tag).laufend?.nummer == sprung.nummer) {
            tageInDiesemFenster++;
          }
        }
        expect(tageInDiesemFenster, sprung.dauerTage,
            reason: 'Sprung ${sprung.nummer}');
      }
    });
  });

  group('Kalender-Fallen', () {
    test('ein Schaltjahr verschiebt nichts', () {
      // 2028 ist ein Schaltjahr. Gerechnet wird in Tagen, nicht in Monaten.
      final DateTime t = DateTime(2028, 1, 1);
      expect(
        berechne(termin: t, heute: DateTime(2028, 2, 5)).laufend?.nummer,
        1,
        reason: '5. Februar ist Tag 35, also Woche 5',
      );
    });

    test('eine Uhrzeit im Termin ändert nichts', () {
      final SprungStand mit = berechne(
        termin: DateTime(2026, 1, 1, 23, 50),
        heute: DateTime(2026, 2, 5, 0, 10),
      );
      final SprungStand ohne = berechne(
        termin: DateTime(2026, 1, 1),
        heute: DateTime(2026, 2, 5),
      );
      expect(mit.tageSeitTermin, ohne.tageSeitTermin);
      expect(mit.laufend?.nummer, ohne.laufend?.nummer);
    });

    test('die Sommerzeit verschiebt keinen Tag', () {
      // Ende März springt die Uhr. In Tagen gerechnet darf das nichts tun.
      final DateTime t = DateTime(2026, 3, 1);
      expect(
        berechne(termin: t, heute: DateTime(2026, 4, 5)).tageSeitTermin,
        35,
      );
    });
  });

  group('Der Fortschritt im Fenster', () {
    test('läuft von 0 bis knapp unter 1', () {
      final Sprung vier = kSpruenge[3];
      expect(fensterFortschritt(amTag(vier.startTag)), 0);
      final double mitte = fensterFortschritt(
          amTag(vier.startTag + vier.dauerTage ~/ 2));
      expect(mitte, greaterThan(0.4));
      expect(mitte, lessThan(0.6));
      expect(fensterFortschritt(amTag(vier.endTag - 1)), lessThan(1));
    });

    test('ohne laufenden Sprung ist er null', () {
      expect(fensterFortschritt(amTag(10 * 7)), 0);
    });
  });

  group('Ein Tag im Tagebuch', () {
    test('sagt, ob er in einem Fenster lag', () {
      expect(
        sprungAmTag(termin: termin, tag: termin.add(const Duration(days: 36)))
            ?.nummer,
        1,
      );
      expect(
        sprungAmTag(termin: termin, tag: termin.add(const Duration(days: 70))),
        isNull,
      );
    });
  });

  group('Tagesschlüssel', () {
    test('ist sortierbar und zweistellig', () {
      expect(tagSchluessel(DateTime(2026, 1, 5)), '2026-01-05');
      expect(tagSchluessel(DateTime(2026, 11, 18)), '2026-11-18');
    });
  });
}
