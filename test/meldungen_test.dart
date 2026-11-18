import 'package:flutter_test/flutter_test.dart';

import 'package:sprungkalender/data/spruenge.dart';
import 'package:sprungkalender/state/meldungen.dart';

/// Ein Benachrichtigungssystem ohne Gerät: merkt sich, was geplant wurde.
class FakeMeldungsBackend implements MeldungsBackend {
  FakeMeldungsBackend({this.erlaubt = true});

  final bool erlaubt;
  final List<GeplanteMeldung> geplant = <GeplanteMeldung>[];
  int abbrueche = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => erlaubt;

  @override
  Future<void> schedule(GeplanteMeldung meldung) async =>
      geplant.add(meldung);

  @override
  Future<void> cancelAll() async {
    abbrueche++;
    geplant.clear();
  }
}

void main() {
  final DateTime termin = DateTime(2026, 1, 1);
  final DateTime jetzt = DateTime(2026, 1, 1, 8);

  List<GeplanteMeldung> plan({
    DateTime? t,
    DateTime? n,
    bool erinnerungen = true,
    bool abendfrage = false,
    int abendStunde = 20,
    String name = '',
    int horizonTage = 180,
  }) =>
      planeMeldungen(
        termin: t ?? termin,
        jetzt: n ?? jetzt,
        erinnerungen: erinnerungen,
        abendfrage: abendfrage,
        abendStunde: abendStunde,
        name: name,
        horizonTage: horizonTage,
      );

  group('Ohne Termin gibt es nichts', () {
    test('keine Meldung, statt einer zur falschen Zeit', () {
      // Das Modell rechnet ab dem errechneten Termin. Ohne ihn wäre jede
      // Meldung geraten. Direkt gerufen, nicht über den Helfer: Dort würde
      // `t ?? termin` das null wieder wegnehmen.
      expect(planeMeldungen(termin: null, jetzt: jetzt), isEmpty);
    });

    test('abgeschaltet auch nicht', () {
      expect(plan(erinnerungen: false), isEmpty);
    });
  });

  group('Je Sprung zwei Meldungen', () {
    test('eine vorher und eine am Ende', () {
      // Über zwei Jahre, damit alle zehn Sprünge hineinfallen.
      final List<GeplanteMeldung> alle = plan(horizonTage: 800);
      expect(alle, hasLength(kSpruenge.length * 2));
    });

    test('die Vorwarnung kommt drei Tage vor dem Fenster', () {
      final GeplanteMeldung erste = plan().first;
      expect(erste.wann, DateTime(2026, 1, 1).add(
          Duration(days: 5 * 7 - kVorlaufTage, hours: 9)));
      expect(erste.titel, contains('Sprung 1'));
      expect(erste.text, contains('3 Tagen'));
    });

    test('die zweite kommt, wenn das Fenster vorbei ist', () {
      final GeplanteMeldung zweite = plan()[1];
      expect(zweite.wann,
          DateTime(2026, 1, 1).add(const Duration(days: 5 * 7 + 7, hours: 9)));
      expect(zweite.titel, contains('durch'));
      expect(zweite.text, contains(kSpruenge.first.titel));
    });

    test('sie kommen morgens, nicht nachts', () {
      for (final GeplanteMeldung m in plan(horizonTage: 800)) {
        expect(m.wann.hour, 9, reason: m.toString());
      }
    });

    test('die Kennungen sind eindeutig', () {
      final List<GeplanteMeldung> alle =
          plan(horizonTage: 800, abendfrage: true);
      expect(alle.map((GeplanteMeldung m) => m.id).toSet().length,
          alle.length);
    });

    test('sie stehen in zeitlicher Reihenfolge', () {
      final List<GeplanteMeldung> alle = plan(horizonTage: 800);
      for (int i = 1; i < alle.length; i++) {
        expect(alle[i].wann.isBefore(alle[i - 1].wann), isFalse);
      }
    });
  });

  group('Vergangenes wird übersprungen', () {
    test('ein Sprung von vor vier Monaten meldet sich nicht mehr', () {
      // Android stellt eine Meldung mit Zeitpunkt in der Vergangenheit
      // sofort zu — das wäre hier Unsinn.
      final List<GeplanteMeldung> alle =
          plan(n: DateTime(2026, 6, 1), horizonTage: 800);
      for (final GeplanteMeldung m in alle) {
        expect(m.wann.isAfter(DateTime(2026, 6, 1)), isTrue,
            reason: m.toString());
      }
      // „Sprung 1 " mit Leerzeichen: „Sprung 10" enthält sonst „Sprung 1".
      expect(alle.any((GeplanteMeldung m) => m.titel.startsWith('Sprung 1 ')),
          isFalse, reason: 'Sprung 1 war im Februar');
    });

    test('nach dem zehnten Sprung ist nichts mehr zu planen', () {
      expect(plan(n: DateTime(2028, 1, 1), horizonTage: 800), isEmpty);
    });

    test('der Horizont begrenzt die Sprünge nicht', () {
      // Der gefundene Fehler: Mit einem Horizont über allem bekäme ein Kind,
      // das erst in fünf Monaten errechnet ist, überhaupt keine Meldung —
      // der erste Sprung läge jenseits von 180 Tagen.
      final List<GeplanteMeldung> spaeterTermin = planeMeldungen(
        termin: DateTime(2026, 6, 1),
        jetzt: DateTime(2026, 1, 1, 8),
      );
      expect(spaeterTermin, hasLength(kSpruenge.length * 2));
      expect(spaeterTermin.first.wann.isAfter(DateTime(2026, 7, 1)), isTrue);
    });
  });

  group('Der Name des Kindes', () {
    test('steht im Text, wenn einer da ist', () {
      expect(plan(name: 'Amina').first.text, contains('Amina'));
    });

    test('sonst steht dort „dein Kind"', () {
      expect(plan().first.text, contains('dein Kind'));
      expect(plan(name: '   ').first.text, contains('dein Kind'));
    });
  });

  group('Die Abendfrage', () {
    test('ist standardmäßig aus', () {
      expect(plan().any((GeplanteMeldung m) => m.titel.contains('Wie war')),
          isFalse);
    });

    test('angeschaltet kommt sie täglich zur gewählten Stunde', () {
      final List<GeplanteMeldung> abends = plan(
        abendfrage: true,
        abendStunde: 21,
        horizonTage: 10,
      ).where((GeplanteMeldung m) => m.titel.contains('Wie war')).toList();

      expect(abends.length, greaterThanOrEqualTo(9));
      for (final GeplanteMeldung m in abends) {
        expect(m.wann.hour, 21);
      }
    });

    test('heute Abend nur, wenn die Stunde noch kommt', () {
      final List<GeplanteMeldung> spaet = plan(
        n: DateTime(2026, 1, 1, 22),
        abendfrage: true,
        abendStunde: 20,
        horizonTage: 3,
      ).where((GeplanteMeldung m) => m.titel.contains('Wie war')).toList();
      expect(spaet.first.wann.day, 2, reason: '20 Uhr ist heute vorbei');
    });
  });

  group('Der Dienst', () {
    test('verwirft den alten Plan und schreibt ihn neu', () async {
      // Ändert sich der Termin, muss alles neu geplant werden — eine halb
      // alte Reihe wäre schlimmer als keine.
      final FakeMeldungsBackend backend = FakeMeldungsBackend();
      final MeldungsDienst dienst = MeldungsDienst(backend: backend);

      await dienst.neuPlanen(termin: termin, jetzt: jetzt);
      expect(backend.abbrueche, 1);
      expect(backend.geplant, hasLength(kSpruenge.length * 2));

      await dienst.neuPlanen(
          termin: DateTime(2026, 6, 1), jetzt: jetzt);
      expect(backend.abbrueche, 2);
      expect(backend.geplant.first.wann.isAfter(DateTime(2026, 6, 1)), isTrue);
    });

    test('ohne Termin wird nur abgeräumt', () async {
      final FakeMeldungsBackend backend = FakeMeldungsBackend();
      await MeldungsDienst(backend: backend)
          .neuPlanen(termin: null, jetzt: jetzt);
      expect(backend.abbrueche, 1);
      expect(backend.geplant, isEmpty);
    });

    test('eine abgelehnte Erlaubnis meldet sich zurück', () async {
      final MeldungsDienst dienst =
          MeldungsDienst(backend: FakeMeldungsBackend(erlaubt: false));
      expect(await dienst.erlaubnis(), isFalse);
    });
  });
}
