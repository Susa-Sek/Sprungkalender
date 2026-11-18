import 'package:material_ui/material_ui.dart';

import '../data/spruenge.dart';
import '../state/kind_store.dart';
import '../state/sprung_rechner.dart';
import '../theme/app_theme.dart';
import '../theme/format.dart';

/// Ein Sprung im Einzelnen.
class SprungScreen extends StatelessWidget {
  const SprungScreen({super.key, required this.sprung});

  final Sprung sprung;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final KindStore store = KindScope.of(context);
    final DateTime? termin = store.termin;

    return Scaffold(
      appBar: AppBar(title: Text('Sprung ${sprung.nummer}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Text(
            sprung.titel,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Insets.xs),
          Text(
            termin == null
                ? 'Ab Woche ${sprung.startWoche}, etwa '
                      '${sprung.dauerTage ~/ 7} '
                      '${sprung.dauerTage ~/ 7 == 1 ? "Woche" : "Wochen"} lang'
                : _zeitraum(termin),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: Insets.lg),
          _Abschnitt(
            symbol: Icons.cloud_outlined,
            titel: 'Woran du es merkst',
            text: sprung.anzeichen,
          ),
          const SizedBox(height: Insets.md),
          _Abschnitt(
            symbol: Icons.wb_sunny_outlined,
            titel: 'Was danach oft neu ist',
            text: sprung.danach,
            fussnote: kEntwicklungHinweis,
          ),
          const SizedBox(height: Insets.xl),
          Text(
            kModellHinweis,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  /// „12. Februar bis 19. Februar 2026" — mit dem eingetragenen Termin lässt
  /// sich das Fenster benennen statt nur in Wochen beschreiben.
  String _zeitraum(DateTime termin) {
    final DateTime von = tagVon(termin).add(Duration(days: sprung.startTag));
    final DateTime bis = tagVon(termin).add(Duration(days: sprung.endTag - 1));
    return 'etwa ${datumLang(von)} bis ${datumLang(bis)} · ab Woche '
        '${sprung.startWoche}';
  }
}

class _Abschnitt extends StatelessWidget {
  const _Abschnitt({
    required this.symbol,
    required this.titel,
    required this.text,
    this.fussnote,
  });

  final IconData symbol;
  final String titel;
  final String text;
  final String? fussnote;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: Insets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    symbol,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Text(
                  titel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            Text(text, style: theme.textTheme.bodyMedium),
            if (fussnote case final String f) ...<Widget>[
              const SizedBox(height: Insets.md),
              Text(
                f,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
