import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'screens/heute_screen.dart';
import 'screens/tagebuch_screen.dart';
import 'state/kind_store.dart';
import 'state/meldungen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const SprungkalenderApp());

/// Sprungkalender — die Entwicklungssprünge des ersten Lebensjahres.
///
/// Die Wochenzahlen stammen aus dem Modell von van de Rijt und Plooij und
/// sind Sachangaben; Texte, Gestaltung und Name dieser App sind eigen. Siehe
/// `lib/data/spruenge.dart` und das README.
class SprungkalenderApp extends StatefulWidget {
  const SprungkalenderApp({super.key});

  @override
  State<SprungkalenderApp> createState() => _SprungkalenderAppState();
}

class _SprungkalenderAppState extends State<SprungkalenderApp>
    with WidgetsBindingObserver {
  final KindStore _store = KindStore();
  final MeldungsDienst _meldungen = MeldungsDienst();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Der Plan wird beim Start und beim Zuklappen neu geschrieben: Ändert
    // sich der Termin, muss alles neu gelegt werden.
    _store.addListener(_planeNeu);
    _store.load().then((_) => _planeNeu());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.removeListener(_planeNeu);
    _store.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _planeNeu();
  }

  void _planeNeu() => unawaited(_meldungen.neuPlanen(
        termin: _store.termin,
        jetzt: DateTime.now(),
        erinnerungen: _store.erinnerungen,
        abendfrage: _store.abendfrage,
        abendStunde: _store.abendStunde,
        name: _store.name,
      ));

  @override
  Widget build(BuildContext context) {
    return KindScope(
      store: _store,
      child: MaterialApp(
        title: 'Sprungkalender',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        home: const AppShell(),
      ),
    );
  }
}

/// Zwei Bereiche: Heute und Tagebuch. Mehr braucht es nicht.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack statt Neuaufbau: Wer im Tagebuch gescrollt hat, findet
      // die Stelle beim Zurückwechseln wieder.
      body: IndexedStack(
        index: _index,
        children: const <Widget>[HeuteScreen(), TagebuchScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Heute',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Tagebuch',
          ),
        ],
      ),
    );
  }
}
