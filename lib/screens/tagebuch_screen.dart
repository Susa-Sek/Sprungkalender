import 'package:material_ui/material_ui.dart';

import '../data/spruenge.dart';
import '../state/kind_store.dart';
import '../state/sprung_rechner.dart';
import '../theme/app_theme.dart';
import '../theme/format.dart';

/// Das Tagebuch — und der Grund, warum es hier das Wichtigste ist.
///
/// Die Sprungwochen sind ein Modell, keine Tatsache. Was wirklich war, steht
/// nur hier: Wenn die Fenster bei diesem Kind gepasst haben, sieht man es an
/// den eingefärbten Zeilen; wenn nicht, auch.
class TagebuchScreen extends StatefulWidget {
  const TagebuchScreen({super.key});

  @override
  State<TagebuchScreen> createState() => _TagebuchScreenState();
}

class _TagebuchScreenState extends State<TagebuchScreen> {
  @override
  Widget build(BuildContext context) {
    final KindStore store = KindScope.of(context);
    // „Heute" kommt aus dem Speicher und nicht aus DateTime.now(): So gehört
    // der Eintrag zum selben Tag wie der Sprungstand daneben.
    final DateTime heute = store.heute;
    final String heuteSchluessel = tagSchluessel(heute);
    final List<TagebuchEintrag> frueher = store.tagebuch
        .where((TagebuchEintrag e) => e.tag != heuteSchluessel)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagebuch'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          _HeuteEintrag(tag: heute, store: store),
          const SizedBox(height: Insets.xl),
          // Heute steht oben schon in voller Länge; in „Was war" gehört es
          // nicht noch einmal hin.
          if (frueher.isEmpty)
            _NochLeer(hatTermin: store.eingerichtet)
          else ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(left: Insets.xs),
              child: Text(
                'Was war',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: Insets.sm),
            for (final TagebuchEintrag e in frueher)
              _Zeile(eintrag: e, termin: store.termin, jahr: heute.year),
          ],
        ],
      ),
    );
  }
}

/// Der heutige Tag, immer oben und immer offen.
class _HeuteEintrag extends StatelessWidget {
  const _HeuteEintrag({required this.tag, required this.store});

  final DateTime tag;
  final KindStore store;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TagebuchEintrag e = store.eintragFuer(tag);
    final Sprung? sprung = store.termin == null
        ? null
        : sprungAmTag(termin: store.termin!, tag: tag);

    return Card(
      child: Padding(
        padding: Insets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Heute', style: theme.textTheme.titleMedium),
                      Text(
                        datumMitWochentag(tag, bezugsJahr: tag.year),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (sprung != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: Radii.chipShape,
                    ),
                    child: Text(
                      'Sprung ${sprung.nummer}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Insets.md),
            _Wahl<Stimmung>(
              frage: 'Stimmung',
              werte: Stimmung.values,
              gewaehlt: e.stimmung,
              label: (Stimmung s) => s.label,
              onWahl: (Stimmung? s) => store.setzeEintrag(
                s == null ? e.mit(stimmungLoeschen: true) : e.mit(stimmung: s),
              ),
            ),
            const SizedBox(height: Insets.md),
            _Wahl<Schlaf>(
              frage: 'Schlaf',
              werte: Schlaf.values,
              gewaehlt: e.schlaf,
              label: (Schlaf s) => s.label,
              onWahl: (Schlaf? s) => store.setzeEintrag(
                s == null ? e.mit(schlafLoeschen: true) : e.mit(schlaf: s),
              ),
            ),
            const SizedBox(height: Insets.md),
            TextFormField(
              key: ValueKey<String>('notiz-${e.tag}'),
              initialValue: e.notiz,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notiz',
                hintText: 'Was war heute?',
              ),
              onChanged: (String text) =>
                  store.setzeEintrag(e.mit(notiz: text)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drei Knöpfe, und ein zweiter Tipp nimmt die Wahl zurück.
class _Wahl<T> extends StatelessWidget {
  const _Wahl({
    required this.frage,
    required this.werte,
    required this.gewaehlt,
    required this.label,
    required this.onWahl,
  });

  final String frage;
  final List<T> werte;
  final T? gewaehlt;
  final String Function(T) label;
  final void Function(T?) onWahl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(frage, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Insets.xs),
        Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: <Widget>[
            for (final T w in werte)
              ChoiceChip(
                label: Text(label(w)),
                selected: gewaehlt == w,
                // Noch einmal antippen nimmt zurück — wer sich vertippt,
                // soll nicht mit einer falschen Angabe leben müssen.
                onSelected: (bool an) => onWahl(an ? w : null),
              ),
          ],
        ),
      ],
    );
  }
}

/// Eine vergangene Zeile. Lag der Tag in einem Fenster, ist sie eingefärbt.
class _Zeile extends StatelessWidget {
  const _Zeile({
    required this.eintrag,
    required this.termin,
    required this.jahr,
  });

  final TagebuchEintrag eintrag;
  final DateTime? termin;
  final int jahr;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime? tag = DateTime.tryParse(eintrag.tag);
    final Sprung? sprung = (termin == null || tag == null)
        ? null
        : sprungAmTag(termin: termin!, tag: tag);

    return Card(
      margin: const EdgeInsets.only(bottom: Insets.sm),
      color: sprung != null
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    tag == null
                        ? eintrag.tag
                        : datumMitWochentag(tag, bezugsJahr: jahr),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                if (sprung != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: Radii.chipShape,
                    ),
                    child: Text(
                      'Sprung ${sprung.nummer}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            if (eintrag.stimmung != null || eintrag.schlaf != null) ...<Widget>[
              const SizedBox(height: Insets.xs),
              Text(
                <String>[
                  if (eintrag.stimmung != null) eintrag.stimmung!.label,
                  if (eintrag.schlaf != null) eintrag.schlaf!.label,
                ].join(' · '),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (eintrag.notiz.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: Insets.xs),
              Text(eintrag.notiz, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _NochLeer extends StatelessWidget {
  const _NochLeer({required this.hatTermin});

  final bool hatTermin;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xl),
      child: Column(
        children: <Widget>[
          Icon(Icons.edit_note, size: 36, color: theme.hintColor),
          const SizedBox(height: Insets.sm),
          Text(
            hatTermin
                ? 'Noch keine Einträge. Zwei Tipps am Tag reichen — später '
                      'weiß man nicht mehr, wie die Woche war.'
                : 'Noch keine Einträge. Trag den Termin ein, dann färbt das '
                      'Tagebuch die Sprungwochen mit ein.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
