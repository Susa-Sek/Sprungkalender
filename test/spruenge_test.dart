import 'package:flutter_test/flutter_test.dart';

import 'package:sprungkalender/data/spruenge.dart';

void main() {
  group('Die zehn Sprünge', () {
    test('es sind zehn, von 1 bis 10 durchnummeriert', () {
      expect(kSpruenge, hasLength(10));
      for (int i = 0; i < kSpruenge.length; i++) {
        expect(kSpruenge[i].nummer, i + 1);
      }
    });

    test('die Startwochen stehen fest', () {
      // Die dokumentierten Wochen des Modells, gezählt ab dem errechneten
      // Termin. Ändert sie jemand aus Versehen, fällt es hier auf.
      expect(
        kSpruenge.map((Sprung s) => s.startWoche).toList(),
        <int>[5, 8, 12, 17, 26, 36, 44, 53, 61, 72],
      );
    });

    test('sie liegen aufsteigend und überschneiden sich nicht', () {
      // Ohne das könnte ein Tag zu zwei Sprüngen gehören, und „welcher
      // Sprung läuft gerade" hätte zwei Antworten.
      for (int i = 1; i < kSpruenge.length; i++) {
        expect(kSpruenge[i].startTag,
            greaterThanOrEqualTo(kSpruenge[i - 1].endTag),
            reason: "Sprung ${i + 1} beginnt, bevor $i vorbei ist");
      }
    });

    test('jeder hat Titel, Anzeichen und Folge', () {
      for (final Sprung s in kSpruenge) {
        expect(s.titel.trim(), isNotEmpty, reason: 'Sprung ${s.nummer}');
        expect(s.anzeichen.trim(), isNotEmpty, reason: 'Sprung ${s.nummer}');
        expect(s.danach.trim(), isNotEmpty, reason: 'Sprung ${s.nummer}');
        expect(s.anzeichen.length, greaterThan(30), reason: 'Sprung ${s.nummer}');
        expect(s.danach.length, greaterThan(60), reason: 'Sprung ${s.nummer}');
      }
    });

    test('die Dauer ist plausibel und wächst mit dem Alter', () {
      // Eine Schätzung, aber keine wilde: mindestens eine Woche, höchstens
      // sechs, und ein späteres Fenster ist nie kürzer als ein viel früheres.
      for (final Sprung s in kSpruenge) {
        expect(s.dauerTage, greaterThanOrEqualTo(7), reason: 'Sprung ${s.nummer}');
        expect(s.dauerTage, lessThanOrEqualTo(42), reason: 'Sprung ${s.nummer}');
      }
      expect(kSpruenge.last.dauerTage,
          greaterThan(kSpruenge.first.dauerTage));
    });

    test('endTag folgt aus startWoche und dauerTage', () {
      for (final Sprung s in kSpruenge) {
        expect(s.startTag, s.startWoche * 7);
        expect(s.endTag, s.startTag + s.dauerTage);
      }
    });
  });

  group('Die beiden Hinweise', () {
    test('der Hinweis zum Modell benennt die Nachuntersuchung', () {
      // Er darf nicht zu einer Floskel verwässern: Wer das Modell benutzt,
      // soll wissen, dass es bestritten ist.
      expect(kModellHinweis, contains('de Weerth'));
      expect(kModellHinweis, contains('1998'));
      expect(kModellHinweis, contains('keine gesicherte Tatsache'));
    });

    test('der Hinweis zur Entwicklung schickt zur Kinderärztin', () {
      expect(kEntwicklungHinweis, contains('Kinderärztin'));
      expect(kEntwicklungHinweis, contains('keine Prüfliste'));
    });
  });
}
