import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sprungkalender/data/spruenge.dart';
import 'package:sprungkalender/main.dart';
import 'package:sprungkalender/screens/einstellungen_screen.dart';
import 'package:sprungkalender/screens/heute_screen.dart';
import 'package:sprungkalender/screens/termin_blatt.dart';
import 'package:sprungkalender/screens/tagebuch_screen.dart';
import 'package:sprungkalender/state/kind_store.dart';
import 'package:sprungkalender/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<KindStore> store({
    DateTime? termin,
    DateTime? jetzt,
    String name = '',
  }) async {
    final KindStore s =
        KindStore(clock: () => jetzt ?? DateTime(2026, 2, 5));
    await s.load();
    if (termin != null) await s.setTermin(termin);
    if (name.isNotEmpty) await s.setName(name);
    return s;
  }

  Widget rahmen(KindStore s, Widget kind, {double scale = 1}) => KindScope(
        store: s,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: kind,
          ),
        ),
      );

  Future<void> oeffne(
    WidgetTester tester,
    KindStore s,
    Widget kind, {
    Size groesse = const Size(420, 2400),
    double scale = 1,
  }) async {
    tester.view.physicalSize = groesse;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(rahmen(s, kind, scale: scale));
    await tester.pumpAndSettle();
  }

  group('Ohne Termin', () {
    testWidgets('sagt der Bildschirm, was fehlt — und warum',
        (WidgetTester tester) async {
      await oeffne(tester, await store(), const HeuteScreen());
      expect(find.text('Noch kein Termin eingetragen'), findsOneWidget);
      expect(find.textContaining('errechneten Geburtstermin'), findsOneWidget);
      expect(find.text('Termin eintragen'), findsOneWidget);
    });

    testWidgets('kein Sternchen-Rest im Text', (WidgetTester tester) async {
      // Ein Markdown-Sternchen in einem Text-Widget wird als Sternchen
      // angezeigt. Genau das stand hier einmal drin.
      await oeffne(tester, await store(), const HeuteScreen());
      expect(find.textContaining('**'), findsNothing);
    });
  });

  group('Mit Termin', () {
    testWidgets('zeigt das korrigierte Alter', (WidgetTester tester) async {
      await oeffne(
        tester,
        await store(termin: DateTime(2026, 1, 1)),
        const HeuteScreen(),
      );
      expect(find.text('Woche 5'), findsOneWidget);
      expect(find.textContaining('korrigiertes Alter'), findsOneWidget);
    });

    testWidgets('nennt den laufenden Sprung', (WidgetTester tester) async {
      await oeffne(
        tester,
        await store(termin: DateTime(2026, 1, 1)),
        const HeuteScreen(),
      );
      expect(find.text('Sprung 1 läuft'), findsOneWidget);
      expect(find.text(kSpruenge.first.titel), findsWidgets);
    });

    testWidgets('nennt sonst den nächsten mit Abstand',
        (WidgetTester tester) async {
      // Tag 70 ist Woche 10 — zwischen Sprung 2 und 3.
      await oeffne(
        tester,
        await store(
            termin: DateTime(2026, 1, 1), jetzt: DateTime(2026, 3, 12)),
        const HeuteScreen(),
      );
      expect(find.textContaining('Nächster Sprung in'), findsOneWidget);
    });

    testWidgets('vor dem Termin zählt es herunter',
        (WidgetTester tester) async {
      await oeffne(
        tester,
        await store(
            termin: DateTime(2026, 3, 1), jetzt: DateTime(2026, 2, 5)),
        const HeuteScreen(),
      );
      expect(find.textContaining('bis zum Termin'), findsOneWidget);
      expect(find.text('Woche 5'), findsNothing);
    });

    testWidgets('alle zehn Sprünge stehen in der Liste',
        (WidgetTester tester) async {
      await oeffne(
        tester,
        await store(termin: DateTime(2026, 1, 1)),
        const HeuteScreen(),
      );
      for (final Sprung s in kSpruenge) {
        expect(find.text('ab Woche ${s.startWoche}'), findsWidgets,
            reason: 'Sprung ${s.nummer}');
      }
    });

    testWidgets('der Name steht in der Kopfzeile',
        (WidgetTester tester) async {
      await oeffne(
        tester,
        await store(termin: DateTime(2026, 1, 1), name: 'Amina'),
        const HeuteScreen(),
      );
      expect(find.text('Amina'), findsOneWidget);
    });
  });

  group('Der Hinweis zum Modell', () {
    testWidgets('steht auf der Startseite', (WidgetTester tester) async {
      // Er darf nicht wegfallen: Die Sprungwochen sind ein Modell, keine
      // Tatsache, und wer die App benutzt, soll das lesen.
      await oeffne(
        tester,
        await store(termin: DateTime(2026, 1, 1)),
        const HeuteScreen(),
      );
      expect(find.textContaining('de Weerth'), findsOneWidget);
    });
  });

  group('Das Tagebuch', () {
    testWidgets('nimmt Stimmung und Schlaf auf', (WidgetTester tester) async {
      final KindStore s = await store(termin: DateTime(2026, 1, 1));
      await oeffne(tester, s, const TagebuchScreen());

      await tester.tap(find.text('Quengelig'));
      await tester.pumpAndSettle();
      expect(s.eintragFuer(DateTime(2026, 2, 5)).stimmung,
          Stimmung.quengelig);

      await tester.tap(find.text('Unruhig'));
      await tester.pumpAndSettle();
      expect(s.eintragFuer(DateTime(2026, 2, 5)).schlaf, Schlaf.unruhig);
    });

    testWidgets('ein zweiter Tipp nimmt die Wahl zurück',
        (WidgetTester tester) async {
      final KindStore s = await store();
      await oeffne(tester, s, const TagebuchScreen());

      await tester.tap(find.text('Zufrieden'));
      await tester.pumpAndSettle();
      expect(s.eintragFuer(DateTime(2026, 2, 5)).stimmung, Stimmung.gut);

      await tester.tap(find.text('Zufrieden'));
      await tester.pumpAndSettle();
      expect(s.eintragFuer(DateTime(2026, 2, 5)).stimmung, isNull);
    });

    testWidgets('zeigt an, dass heute in einem Fenster liegt',
        (WidgetTester tester) async {
      await oeffne(
        tester,
        await store(termin: DateTime(2026, 1, 1)),
        const TagebuchScreen(),
      );
      expect(find.text('Sprung 1'), findsOneWidget);
    });

    testWidgets('leer sagt es das, mit Hinweis auf den Termin',
        (WidgetTester tester) async {
      await oeffne(tester, await store(), const TagebuchScreen());
      expect(find.textContaining('Noch keine Einträge'), findsOneWidget);
      expect(find.textContaining('Trag den Termin ein'), findsOneWidget);
    });

    testWidgets('vergangene Tage stehen darunter',
        (WidgetTester tester) async {
      final KindStore s = await store(termin: DateTime(2026, 1, 1));
      await s.setzeEintrag(const TagebuchEintrag(
          tag: '2026-02-01', stimmung: Stimmung.gut, notiz: 'Viel gelacht.'));
      await oeffne(tester, s, const TagebuchScreen());

      expect(find.text('Sonntag, 1. Februar'), findsOneWidget);
      expect(find.text('Viel gelacht.'), findsOneWidget);
    });
  });

  group('Die ganze App', () {
    testWidgets('startet und zeigt zwei Bereiche',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const SprungkalenderApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationDestination), findsNWidgets(2));
      expect(find.text('Heute'), findsWidgets);
      expect(find.text('Tagebuch'), findsWidgets);
    });

    testWidgets('der Wechsel ins Tagebuch funktioniert',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const SprungkalenderApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_note_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Stimmung'), findsOneWidget);
    });
  });

  group('Layout', () {
    testWidgets('320 px und 150 % Schrift laufen nicht über',
        (WidgetTester tester) async {
      await oeffne(
        tester,
        await store(termin: DateTime(2026, 1, 1)),
        const HeuteScreen(),
        groesse: const Size(320, 6000),
        scale: 1.5,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('das Tagebuch auch', (WidgetTester tester) async {
      await oeffne(
        tester,
        await store(termin: DateTime(2026, 1, 1)),
        const TagebuchScreen(),
        groesse: const Size(320, 6000),
        scale: 1.5,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Das Theme', () {
    testWidgets('Knöpfe lassen sich nebeneinander in eine Row setzen',
        (WidgetTester tester) async {
      // Size.fromHeight(48) als Mindestgröße heißt „unendlich breit" — so
      // ein Knopf verschwindet in jeder Row. Das darf nicht wiederkommen.
      await oeffne(
        tester,
        await store(),
        Scaffold(
          body: Row(
            children: <Widget>[
              TextButton(onPressed: () {}, child: const Text('A')),
              const Spacer(),
              OutlinedButton(onPressed: () {}, child: const Text('B')),
              FilledButton(onPressed: () {}, child: const Text('C')),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('C'), findsOneWidget);
    });
  });

  group('Das Termin-Blatt', () {
    // Hier war der „Übernehmen"-Knopf verschwunden: Das Theme gab allen
    // FilledButtons eine unendliche Mindestbreite, und in einer Row lässt
    // sich das nicht anordnen. Man konnte ein Datum wählen, aber nicht
    // bestätigen.
    testWidgets('öffnet ohne Layoutfehler und zeigt „Übernehmen"',
        (WidgetTester tester) async {
      await oeffne(
        tester,
        await store(termin: DateTime(2026, 1, 1)),
        const EinstellungenScreen(),
      );
      await tester.tap(find.text('Errechneter Termin'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Übernehmen'), findsOneWidget);
      expect(find.text('Termin löschen'), findsOneWidget);
    });

    testWidgets('über das Geburtsdatum: wählen, verschieben, übernehmen',
        (WidgetTester tester) async {
      final KindStore s = await store();
      await oeffne(
        tester,
        s,
        Scaffold(
          body: TerminBlatt(store: s, heute: DateTime(2026, 2, 5)),
        ),
      );

      await tester.tap(find.text('Geburtsdatum'));
      await tester.pumpAndSettle();
      expect(find.text('Datum wählen'), findsOneWidget);

      // Ohne Datum lässt sich nichts übernehmen.
      final Finder knopf = find.widgetWithText(FilledButton, 'Übernehmen');
      expect(tester.widget<FilledButton>(knopf).onPressed, isNull);

      // Datumswähler: der 1. Februar, dann „Auswählen".
      await tester.tap(find.text('Datum wählen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1'));
      await tester.tap(find.text('Auswählen'));
      await tester.pumpAndSettle();
      expect(find.text('1. Februar 2026'), findsWidgets);

      // Drei Wochen zu früh.
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
      }
      expect(find.text('3 Wochen zu früh'), findsOneWidget);
      expect(find.text('22. Februar 2026'), findsOneWidget);

      expect(tester.widget<FilledButton>(knopf).onPressed, isNotNull);
      await tester.tap(knopf);
      await tester.pumpAndSettle();
      expect(s.termin, DateTime(2026, 2, 22));
    });

    testWidgets('320 px und 150 % Schrift laufen nicht über',
        (WidgetTester tester) async {
      final KindStore s = await store(termin: DateTime(2026, 1, 1));
      await oeffne(
        tester,
        s,
        Scaffold(
          body: TerminBlatt(store: s, heute: DateTime(2026, 2, 5)),
        ),
        groesse: const Size(320, 2400),
        scale: 1.5,
      );
      await tester.tap(find.text('Geburtsdatum'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Ohne Termin führt der Knopf', () {
    testWidgets('direkt zum Termin-Blatt', (WidgetTester tester) async {
      await oeffne(tester, await store(), const HeuteScreen());
      await tester.tap(find.text('Termin eintragen'));
      await tester.pumpAndSettle();
      expect(find.text('Ab wann wird gezählt?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
