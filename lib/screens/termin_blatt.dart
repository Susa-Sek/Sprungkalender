import 'package:material_ui/material_ui.dart';

import '../state/kind_store.dart';
import '../state/sprung_rechner.dart';
import '../theme/app_theme.dart';
import '../theme/format.dart';

/// Termin eintragen — direkt, oder aus Geburtsdatum und Abweichung.
///
/// Drei Schritte, von oben nach unten: was man weiß, welches Datum, und —
/// nur über die Geburt — wie viele Wochen zu früh oder zu spät. Darunter
/// steht immer, ab welchem Tag gerechnet wird, bevor man es übernimmt.
class TerminBlatt extends StatefulWidget {
  const TerminBlatt({super.key, required this.store, this.heute});

  final KindStore store;

  /// Nur für Tests; sonst der heutige Tag.
  final DateTime? heute;

  static Future<void> open(BuildContext context, KindStore store) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (BuildContext context) => TerminBlatt(store: store),
      );

  /// Spanne der Plus-Minus-Wahl: bis vier Wochen zu spät, bis sechzehn zu
  /// früh. Ein Kind, das mehr als sechzehn Wochen zu früh kam, ist sehr
  /// selten — und wer das weiß, kennt meist auch den Termin.
  static const int minWochen = -4;
  static const int maxWochen = 16;

  @override
  State<TerminBlatt> createState() => _TerminBlattState();
}

class _TerminBlattState extends State<TerminBlatt> {
  bool _ueberGeburt = false;

  // Getrennt gehalten: Wer zwischen den beiden Wegen wechselt, soll nicht
  // plötzlich den Termin als Geburtsdatum stehen haben.
  DateTime? _termin;
  DateTime? _geburt;
  int _wochenZuFrueh = 0;

  @override
  void initState() {
    super.initState();
    _termin = widget.store.termin;
  }

  DateTime get _heute => tagVon(widget.heute ?? DateTime.now());

  DateTime? get _gewaehlt => _ueberGeburt ? _geburt : _termin;

  DateTime? get _ergebnis {
    if (_ueberGeburt) {
      return _geburt == null
          ? null
          : terminAusGeburt(_geburt!, wochenZuFrueh: _wochenZuFrueh);
    }
    return _termin;
  }

  Future<void> _waehleDatum() async {
    final DateTime heute = _heute;
    // Eine Geburt liegt nie in der Zukunft; ein Termin kann es.
    final DateTime erstes = DateTime(heute.year - 3, heute.month, heute.day);
    final DateTime letztes = _ueberGeburt
        ? heute
        : DateTime(heute.year + 1, heute.month, heute.day);
    DateTime start = _gewaehlt ?? heute;
    if (start.isBefore(erstes)) start = erstes;
    if (start.isAfter(letztes)) start = letztes;

    final DateTime? gewaehlt = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: erstes,
      lastDate: letztes,
      helpText: _ueberGeburt ? 'Geburtsdatum' : 'Errechneter Termin',
      cancelText: 'Abbrechen',
      confirmText: 'Auswählen',
      fieldLabelText: 'Datum',
      fieldHintText: 'TT.MM.JJJJ',
    );
    if (gewaehlt == null || !mounted) return;
    setState(() {
      if (_ueberGeburt) {
        _geburt = gewaehlt;
      } else {
        _termin = gewaehlt;
      }
    });
  }

  Future<void> _uebernehmen() async {
    final DateTime? ergebnis = _ergebnis;
    if (ergebnis == null) return;
    await widget.store.setTermin(ergebnis);
    if (!mounted) return;
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    Navigator.of(context).pop();
    messenger?.showSnackBar(
      SnackBar(
        content: Text('Gespeichert — gezählt wird ab ${datumLang(ergebnis)}.'),
      ),
    );
  }

  Future<void> _loeschen() async {
    await widget.store.setTermin(null);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime? ergebnis = _ergebnis;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Ab wann wird gezählt?', style: theme.textTheme.titleLarge),
          const SizedBox(height: Insets.xs),
          Text(
            'Die Sprünge zählen ab dem errechneten Termin, nicht ab der '
            'Geburt.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Insets.lg),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(
                value: false,
                icon: Icon(Icons.event_available_outlined),
                label: Text('Termin bekannt'),
              ),
              ButtonSegment<bool>(
                value: true,
                icon: Icon(Icons.cake_outlined),
                label: Text('Geburtsdatum'),
              ),
            ],
            selected: <bool>{_ueberGeburt},
            onSelectionChanged: (Set<bool> w) =>
                setState(() => _ueberGeburt = w.first),
          ),
          const SizedBox(height: Insets.lg),
          _DatumFeld(
            titel: _ueberGeburt ? 'Geburtsdatum' : 'Errechneter Termin',
            datum: _gewaehlt,
            onTap: _waehleDatum,
          ),
          AnimatedSize(
            duration: Motion.normal,
            curve: Motion.enter,
            alignment: Alignment.topCenter,
            child: _ueberGeburt
                ? Padding(
                    padding: const EdgeInsets.only(top: Insets.lg),
                    child: _WochenWahl(
                      wert: _wochenZuFrueh,
                      onWert: (int w) => setState(() => _wochenZuFrueh = w),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: Insets.lg),
          AnimatedSwitcher(
            duration: Motion.normal,
            child: ergebnis == null
                ? const SizedBox.shrink(key: ValueKey<String>('leer'))
                : _Ergebnis(
                    key: ValueKey<DateTime>(ergebnis),
                    datum: ergebnis,
                    heute: _heute,
                  ),
          ),
          const SizedBox(height: Insets.lg),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.check),
            label: const Text('Übernehmen'),
            onPressed: ergebnis == null ? null : _uebernehmen,
          ),
          if (widget.store.eingerichtet) ...<Widget>[
            const SizedBox(height: Insets.xs),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: _loeschen,
              child: const Text('Termin löschen'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ein großes, antippbares Feld statt eines kleinen Knopfs: Hier steht das
/// gewählte Datum, und hier wird es geändert.
class _DatumFeld extends StatelessWidget {
  const _DatumFeld({
    required this.titel,
    required this.datum,
    required this.onTap,
  });

  final String titel;
  final DateTime? datum;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme farben = theme.colorScheme;
    return Material(
      color: farben.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.cardShape,
        side: BorderSide(
          color: datum == null ? farben.primary : farben.outlineVariant,
          width: datum == null ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Insets.lg),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: farben.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: farben.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      titel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: farben.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      datum == null ? 'Datum wählen' : datumLang(datum!),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: datum == null ? farben.primary : null,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                datum == null ? Icons.chevron_right : Icons.edit_outlined,
                color: farben.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plus und Minus statt einer Reihe Zahlen mit Vorzeichen: „3 Wochen zu
/// früh" liest sich, „-3" muss man erst übersetzen.
class _WochenWahl extends StatelessWidget {
  const _WochenWahl({required this.wert, required this.onWert});

  final int wert;
  final ValueChanged<int> onWert;

  static String beschreibung(int w) {
    if (w == 0) return 'Am Termin geboren';
    final int n = w.abs();
    final String wochen = n == 1 ? 'Woche' : 'Wochen';
    return w > 0 ? '$n $wochen zu früh' : '$n $wochen zu spät';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Kam das Kind früher oder später?',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: Insets.sm),
        Row(
          children: <Widget>[
            IconButton.filledTonal(
              tooltip: 'Eine Woche später',
              icon: const Icon(Icons.remove),
              onPressed: wert > TerminBlatt.minWochen
                  ? () => onWert(wert - 1)
                  : null,
            ),
            Expanded(
              child: Text(
                beschreibung(wert),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Eine Woche früher',
              icon: const Icon(Icons.add),
              onPressed: wert < TerminBlatt.maxWochen
                  ? () => onWert(wert + 1)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: Insets.xs),
        Text(
          'Plus heißt zu früh, Minus zu spät. Der Mutterpass oder der '
          'Arztbrief nennt die Schwangerschaftswoche bei der Geburt.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Was am Ende gilt — sichtbar, bevor man es übernimmt.
class _Ergebnis extends StatelessWidget {
  const _Ergebnis({super.key, required this.datum, required this.heute});

  final DateTime datum;
  final DateTime heute;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme farben = theme.colorScheme;
    final int tage = tagVon(heute).difference(tagVon(datum)).inDays;
    final String alter = tage < 0
        ? 'noch ${-tage} ${tage == -1 ? "Tag" : "Tage"} bis dahin'
        : 'heute Woche ${tage ~/ 7} im korrigierten Alter';

    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: farben.primaryContainer,
        borderRadius: Radii.cardShape,
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.flag_outlined, color: farben.onPrimaryContainer),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Gezählt wird ab',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: farben.onPrimaryContainer,
                  ),
                ),
                Text(
                  datumLang(datum),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: farben.onPrimaryContainer,
                  ),
                ),
                Text(
                  alter,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: farben.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
