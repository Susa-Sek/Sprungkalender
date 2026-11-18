import 'package:material_ui/material_ui.dart';

import '../data/spruenge.dart';
import '../state/kind_store.dart';
import '../state/sprung_rechner.dart';
import '../theme/app_theme.dart';
import 'einstellungen_screen.dart';
import 'sprung_screen.dart';
import 'termin_blatt.dart';

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
                Padding(
                  padding: const EdgeInsets.only(left: Insets.xs),
                  child: Text(
                    'Alle zehn Sprünge',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: Insets.sm),
                _Zeitleiste(stand: stand),
                const SizedBox(height: Insets.xl),
                Text(
                  kModellHinweis,
                  style: Theme.of(context).textTheme.bodySmall
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
    final ColorScheme farben = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    farben.primaryContainer,
                    farben.tertiaryContainer,
                  ],
                ),
              ),
              child: Icon(
                Icons.child_friendly_outlined,
                size: 44,
                color: farben.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: Insets.xl),
            Text(
              'Noch kein Termin eingetragen',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: Insets.sm),
            Text(
              'Die Sprünge werden ab dem errechneten Geburtstermin gezählt, '
              'nicht ab der Geburt. Bei einem Kind, das sechs Wochen zu früh '
              'kam, liegen dazwischen sechs Wochen.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: farben.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Insets.xl),
            FilledButton.icon(
              icon: const Icon(Icons.event_outlined),
              onPressed: () => TerminBlatt.open(context, KindScope.of(context)),
              label: const Text('Termin eintragen'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Das korrigierte Alter — groß, als Kopf der Seite.
class _AlterKarte extends StatelessWidget {
  const _AlterKarte({required this.stand});

  final SprungStand stand;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme farben = theme.colorScheme;
    final Color schrift = farben.onPrimary;
    final int tag = stand.tageSeitTermin;

    return Container(
      padding: const EdgeInsets.all(Insets.xl - 4),
      decoration: BoxDecoration(
        borderRadius: Radii.cardShape,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[farben.primary, farben.tertiary],
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  stand.vorDemTermin
                      ? 'Noch ${-tag} ${tag == -1 ? "Tag" : "Tage"} bis zum Termin'
                      : 'Woche ${stand.wochen}',
                  style:
                      (stand.vorDemTermin
                              ? theme.textTheme.titleLarge
                              : theme.textTheme.headlineMedium)
                          ?.copyWith(
                            color: schrift,
                            fontWeight: FontWeight.w700,
                          ),
                ),
                const SizedBox(height: Insets.xs),
                Text(
                  stand.vorDemTermin
                      ? 'Gezählt wird ab dem errechneten Termin.'
                      : 'korrigiertes Alter, ab dem errechneten Termin',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: schrift.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          if (!stand.vorDemTermin) ...<Widget>[
            const SizedBox(width: Insets.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.md,
                vertical: Insets.sm,
              ),
              decoration: BoxDecoration(
                color: schrift.withValues(alpha: 0.16),
                borderRadius: Radii.chipShape,
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    'Tag',
                    style: theme.textTheme.labelSmall?.copyWith(color: schrift),
                  ),
                  Text(
                    '$tag',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: schrift,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
              Text(
                'Alle zehn Sprünge liegen hinter dir',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                LinearProgressIndicator(
                  value: fensterFortschritt(stand),
                  backgroundColor: theme.colorScheme.onPrimaryContainer
                      .withValues(alpha: 0.12),
                ),
                const SizedBox(height: Insets.sm),
                Text(
                  'Noch etwa ${stand.tageNochImFenster} '
                  '${stand.tageNochImFenster == 1 ? "Tag" : "Tage"} — '
                  'das Fenster ist eine Schätzung, kein Termin.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Mehr dazu',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: laufend != null
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: laufend != null
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.primary,
                    ),
                  ],
                ),
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
          for (final Sprung s in kSpruenge) ...<Widget>[
            if (s.nummer != kSpruenge.first.nummer) const Divider(indent: 64),
            ListTile(
              dense: true,
              leading: _Punkt(nummer: s.nummer, zustand: _zustandVon(s)),
              title: Text(
                s.titel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: _zustandVon(s) == _Zustand.laufend
                      ? FontWeight.w600
                      : null,
                ),
              ),
              subtitle: Text(
                'ab Woche ${s.startWoche}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => SprungScreen(sprung: s),
                ),
              ),
            ),
          ],
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
        theme.colorScheme.onPrimary,
      ),
      _Zustand.vorbei => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
      _Zustand.kommt => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: flaeche, shape: BoxShape.circle),
      child: zustand == _Zustand.vorbei
          ? Icon(Icons.check, size: 16, color: schrift)
          : Text(
              '$nummer',
              style: theme.textTheme.labelMedium?.copyWith(color: schrift),
            ),
    );
  }
}
