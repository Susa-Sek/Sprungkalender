import 'package:material_ui/material_ui.dart';

import '../data/spruenge.dart';
import '../state/kind_store.dart';
import '../state/sprung_rechner.dart';
import '../theme/app_theme.dart';
import 'einstellungen_screen.dart';
import 'sprung_screen.dart';

/// Was heute ansteht.
class HeuteScreen extends StatelessWidget {
  const HeuteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final KindStore store = KindScope.of(context);
    final SprungStand? stand = store.stand;

    return Scaffold(
      appBar: AppBar(
        title: Text(store.name.isEmpty ? 'Heute' : store.name),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            tooltip: 'Einstellungen',
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const EinstellungenScreen(),
              ),
            ),
          ),
        ],
      ),
      body: stand == null
          ? const _KeinTermin()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: <Widget>[
                _AlterKarte(stand: stand),
                const SizedBox(height: Insets.md),
                _JetztKarte(stand: stand),
                const SizedBox(height: Insets.xl),
                Text('Alle zehn Sprünge',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: Insets.sm),
                _Zeitleiste(stand: stand),
                const SizedBox(height: Insets.xl),
                Text(
                  kModellHinweis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).hintColor),
                ),
              ],
            ),
    );
  }
}

/// Ohne Termin rechnet die App nichts — und sagt das.
class _KeinTermin extends StatelessWidget {
  const _KeinTermin();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.event_outlined,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: Insets.lg),
            Text('Noch kein Termin eingetragen',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: Insets.sm),
            Text(
              'Die Sprünge werden ab dem errechneten Geburtstermin gezählt, '
              'nicht ab der Geburt. Bei einem Kind, das sechs Wochen zu früh '
              'kam, liegen dazwischen sechs Wochen.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Insets.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const EinstellungenScreen(),
                ),
              ),
              child: const Text('Termin eintragen'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Das korrigierte Alter.
class _AlterKarte extends StatelessWidget {
  const _AlterKarte({required this.stand});

  final SprungStand stand;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: Insets.card,
        child: Row(
          children: <Widget>[
            Icon(Icons.child_care_outlined,
                color: theme.colorScheme.primary),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    stand.vorDemTermin
                        ? 'Noch ${-stand.tageSeitTermin} Tage bis zum Termin'
                        : 'Woche ${stand.wochen}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    stand.vorDemTermin
                        ? 'Gezählt wird ab dem errechneten Termin.'
                        : 'korrigiertes Alter, ab dem errechneten Termin',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Der laufende oder der nächste Sprung.
class _JetztKarte extends StatelessWidget {
  const _JetztKarte({required this.stand});

  final SprungStand stand;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (stand.durch) {
      return Card(
        child: Padding(
          padding: Insets.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Alle zehn Sprünge liegen hinter dir',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: Insets.xs),
              Text(
                'Das Modell endet hier. Das Tagebuch bleibt — und es zeigt, '
                'wie die zwei Jahre wirklich gelaufen sind.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final Sprung? laufend = stand.laufend;
    final Sprung? naechster = stand.naechster;
    final Sprung gezeigt = laufend ?? naechster!;

    return Card(
      color: laufend != null ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        borderRadius: Radii.cardShape,
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => SprungScreen(sprung: gezeigt),
          ),
        ),
        child: Padding(
          padding: Insets.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                laufend != null
                    ? 'Sprung ${laufend.nummer} läuft'
                    : 'Nächster Sprung in ${stand.tageBisNaechster} '
                        '${stand.tageBisNaechster == 1 ? "Tag" : "Tagen"}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: laufend != null
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.hintColor,
                ),
              ),
              const SizedBox(height: Insets.xs),
              Text(
                gezeigt.titel,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: laufend != null
                      ? theme.colorScheme.onPrimaryContainer
                      : null,
                ),
              ),
              const SizedBox(height: Insets.sm),
              if (laufend != null) ...<Widget>[
                LinearProgressIndicator(value: fensterFortschritt(stand)),
                const SizedBox(height: Insets.sm),
                Text(
                  'Noch etwa ${stand.tageNochImFenster} '
                  '${stand.tageNochImFenster == 1 ? "Tag" : "Tage"} — '
                  'das Fenster ist eine Schätzung, kein Termin.',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer),
                ),
              ] else
                Text(
                  'Ab Woche ${gezeigt.startWoche}, etwa '
                  '${gezeigt.dauerTage ~/ 7} '
                  '${gezeigt.dauerTage ~/ 7 == 1 ? "Woche" : "Wochen"} lang.',
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: Insets.sm),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Antippen für Einzelheiten',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.hintColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alle zehn Sprünge als Liste — abgehakt, laufend, kommend.
///
/// Bewusst eine Liste und kein waagerechter Balken: Zehn Fenster über zwei
/// Jahre auf 320 Pixel Breite ergeben Striche, die niemand auseinanderhält.
class _Zeitleiste extends StatelessWidget {
  const _Zeitleiste({required this.stand});

  final SprungStand stand;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Column(
        children: <Widget>[
          for (final Sprung s in kSpruenge)
            ListTile(
              dense: true,
              leading: _Punkt(
                nummer: s.nummer,
                zustand: _zustandVon(s),
              ),
              title: Text(s.titel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: _zustandVon(s) == _Zustand.laufend
                        ? FontWeight.w600
                        : null,
                  )),
              subtitle: Text('ab Woche ${s.startWoche}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.hintColor)),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => SprungScreen(sprung: s),
                ),
              ),
            ),
        ],
      ),
    );
  }

  _Zustand _zustandVon(Sprung s) {
    if (stand.laufend?.nummer == s.nummer) return _Zustand.laufend;
    if (stand.tageSeitTermin >= s.endTag) return _Zustand.vorbei;
    return _Zustand.kommt;
  }
}

enum _Zustand { vorbei, laufend, kommt }

class _Punkt extends StatelessWidget {
  const _Punkt({required this.nummer, required this.zustand});

  final int nummer;
  final _Zustand zustand;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (Color flaeche, Color schrift) = switch (zustand) {
      _Zustand.laufend => (
          theme.colorScheme.primary,
          theme.colorScheme.onPrimary
        ),
      _Zustand.vorbei => (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer
        ),
      _Zustand.kommt => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant
        ),
    };

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: flaeche, shape: BoxShape.circle),
      child: zustand == _Zustand.vorbei
          ? Icon(Icons.check, size: 16, color: schrift)
          : Text('$nummer',
              style: theme.textTheme.labelMedium?.copyWith(color: schrift)),
    );
  }
}
