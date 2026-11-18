import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sprungkalender/state/kind_store.dart';
import 'package:sprungkalender/state/sprung_rechner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<KindStore> frisch({DateTime? jetzt}) async {
    final KindStore store = KindStore(
        clock: () => jetzt ?? DateTime(2026, 11, 18));
    await store.load();
    return store;
  }

  group('Frisch installiert', () {
    test('kein Termin, kein Stand, keine Rechnung', () async {
      final KindStore store = await frisch();
      expect(store.eingerichtet, isFalse);
      expect(store.termin, isNull);
      expect(store.stand, isNull, reason: 'ohne Termin wird nichts gerechnet');
      expect(store.tagebuch, isEmpty);
      expect(store.erinnerungen, isTrue);
      expect(store.abendfrage, isFalse);
    });
  });

  group('Der Termin', () {
    test('wird auf Mitternacht gelegt und überlebt den Neustart', () async {
      final KindStore erst = await frisch();
      await erst.setTermin(DateTime(2026, 1, 1, 17, 42));
      await erst.setName('Amina');

      final KindStore wieder = await frisch();
      expect(wieder.termin, DateTime(2026, 1, 1));
      expect(wieder.name, 'Amina');
      expect(wieder.eingerichtet, isTrue);
    });

    test('mit Termin rechnet der Stand', () async {
      final KindStore store = await frisch(jetzt: DateTime(2026, 2, 5));
      await store.setTermin(DateTime(2026, 1, 1));
      expect(store.stand?.laufend?.nummer, 1, reason: 'Tag 35 ist Woche 5');
    });

    test('löschen macht die App wieder leer', () async {
      final KindStore store = await frisch();
      await store.setTermin(DateTime(2026, 1, 1));
      await store.setTermin(null);
      expect(store.eingerichtet, isFalse);
      expect(store.stand, isNull);
    });
  });

  group('Das Tagebuch', () {
    test('ein Eintrag je Tag, und er hält', () async {
      final KindStore erst = await frisch();
      final DateTime heute = DateTime(2026, 11, 18);
      await erst.setzeEintrag(TagebuchEintrag(
        tag: tagSchluessel(heute),
        stimmung: Stimmung.quengelig,
        schlaf: Schlaf.unruhig,
        notiz: 'Dreimal wach.',
      ));

      final KindStore wieder = await frisch();
      final TagebuchEintrag e = wieder.eintragFuer(heute);
      expect(e.stimmung, Stimmung.quengelig);
      expect(e.schlaf, Schlaf.unruhig);
      expect(e.notiz, 'Dreimal wach.');
      expect(wieder.tagebuch, hasLength(1));
    });

    test('ein zweiter Eintrag am selben Tag ersetzt den ersten', () async {
      final KindStore store = await frisch();
      final String tag = tagSchluessel(DateTime(2026, 11, 18));
      await store.setzeEintrag(
          TagebuchEintrag(tag: tag, stimmung: Stimmung.gut));
      await store.setzeEintrag(
          TagebuchEintrag(tag: tag, stimmung: Stimmung.mittel));
      expect(store.tagebuch, hasLength(1));
      expect(store.tagebuch.single.stimmung, Stimmung.mittel);
    });

    test('ein leerer Eintrag wird nicht gespeichert', () async {
      // Sonst wüchse der Speicher mit Leerzeilen, sobald man einen Tag
      // antippt und doch nichts einträgt.
      final KindStore store = await frisch();
      final String tag = tagSchluessel(DateTime(2026, 11, 18));
      await store.setzeEintrag(
          TagebuchEintrag(tag: tag, stimmung: Stimmung.gut));
      expect(store.tagebuch, hasLength(1));

      await store.setzeEintrag(TagebuchEintrag(tag: tag));
      expect(store.tagebuch, isEmpty);
    });

    test('nur Leerzeichen in der Notiz zählt als leer', () async {
      final KindStore store = await frisch();
      await store.setzeEintrag(TagebuchEintrag(
          tag: tagSchluessel(DateTime(2026, 11, 18)), notiz: '   '));
      expect(store.tagebuch, isEmpty);
    });

    test('„mit" ändert nur, was angegeben ist', () {
      const TagebuchEintrag e = TagebuchEintrag(
        tag: '2026-11-18',
        stimmung: Stimmung.gut,
        schlaf: Schlaf.mittel,
        notiz: 'alt',
      );
      final TagebuchEintrag neu = e.mit(notiz: 'neu');
      expect(neu.stimmung, Stimmung.gut);
      expect(neu.schlaf, Schlaf.mittel);
      expect(neu.notiz, 'neu');

      expect(e.mit(stimmungLoeschen: true).stimmung, isNull);
      expect(e.mit(stimmungLoeschen: true).schlaf, Schlaf.mittel);
    });

    test('die Liste beginnt mit dem neuesten Tag', () async {
      final KindStore store = await frisch();
      for (final String tag in <String>[
        '2026-11-16',
        '2026-11-18',
        '2026-11-17'
      ]) {
        await store.setzeEintrag(
            TagebuchEintrag(tag: tag, stimmung: Stimmung.gut));
      }
      expect(store.tagebuch.map((TagebuchEintrag e) => e.tag).toList(),
          <String>['2026-11-18', '2026-11-17', '2026-11-16']);
    });
  });

  group('Sichern und einspielen', () {
    test('was herauskommt, kommt auch wieder hinein', () async {
      final KindStore erst = await frisch();
      await erst.setTermin(DateTime(2026, 1, 1));
      await erst.setName('Amina');
      await erst.setAbendfrage(true);
      await erst.setAbendStunde(21);
      await erst.setzeEintrag(const TagebuchEintrag(
        tag: '2026-11-18',
        stimmung: Stimmung.quengelig,
        notiz: 'Zahn?',
      ));
      final String sicherung = erst.ausgeben();

      final KindStore leer = await frisch();
      await leer.einspielen(sicherung);

      expect(leer.termin, DateTime(2026, 1, 1));
      expect(leer.name, 'Amina');
      expect(leer.abendfrage, isTrue);
      expect(leer.abendStunde, 21);
      expect(leer.eintragFuer(DateTime(2026, 11, 18)).notiz, 'Zahn?');
    });

    test('eine Sicherung aus einer älteren Version liest sich', () async {
      // Nur die Felder von damals — alles Neue nimmt seine Vorgabe.
      final KindStore store = await frisch();
      await store.einspielen('{"termin":"2026-01-01T00:00:00.000"}');
      expect(store.termin, DateTime(2026, 1, 1));
      expect(store.name, '');
      expect(store.erinnerungen, isTrue);
      expect(store.abendStunde, 20);
    });

    test('kaputtes JSON lässt den Stand in Ruhe', () async {
      final KindStore store = await frisch();
      await store.setTermin(DateTime(2026, 1, 1));
      store.uebernehmen('[]');
      expect(store.termin, DateTime(2026, 1, 1),
          reason: 'etwas, das keine Karte ist, ändert nichts');
    });

    test('leere Tagebuchtage landen nicht in der Sicherung', () async {
      final KindStore store = await frisch();
      await store.setzeEintrag(
          const TagebuchEintrag(tag: '2026-11-18', stimmung: Stimmung.gut));
      expect(store.ausgeben(), contains('2026-11-18'));
      expect(store.ausgeben(), isNot(contains('2026-11-19')));
    });
  });

  group('Zurücksetzen', () {
    test('räumt alles ab', () async {
      final KindStore store = await frisch();
      await store.setTermin(DateTime(2026, 1, 1));
      await store.setName('Amina');
      await store.setzeEintrag(
          const TagebuchEintrag(tag: '2026-11-18', stimmung: Stimmung.gut));

      await store.zuruecksetzen();
      expect(store.eingerichtet, isFalse);
      expect(store.name, '');
      expect(store.tagebuch, isEmpty);
    });
  });
}
