import 'package:material_ui/material_ui.dart';

import '../state/kind_store.dart';
import '../state/meldungen.dart';
import '../state/sprung_rechner.dart';
import '../theme/app_theme.dart';

/// Termin, Name, Erinnerungen.
class EinstellungenScreen extends StatelessWidget {
  const EinstellungenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final KindStore store = KindScope.of(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Text('Das Kind', style: theme.textTheme.titleSmall),
          const SizedBox(height: Insets.sm),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Errechneter Termin'),
                  subtitle: Text(store.termin == null
                      ? 'Noch nicht eingetragen'
                      : _datum(store.termin!)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _TerminBlatt.open(context, store),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Name'),
                  subtitle:
                      Text(store.name.isEmpty ? 'Ohne Namen' : store.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _NameDialog.open(context, store),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xs),
          Text(
            'Gezählt wird ab dem errechneten Termin, nicht ab der Geburt — '
            'darauf beruht das ganze Modell. Wer den Termin nicht weiß, gibt '
            'das Geburtsdatum ein und daneben, wie viele Wochen zu früh oder '
            'zu spät.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),

          const SizedBox(height: Insets.xl),
          Text('Erinnerungen', style: theme.textTheme.titleSmall),
          const SizedBox(height: Insets.sm),
          Card(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Vor und nach einem Sprung'),
                  subtitle: Text('Drei Tage vorher und am Ende des Fensters, '
                      'morgens um 9${store.eingerichtet ? "" : " — "
                          "braucht einen Termin"}'),
                  value: store.erinnerungen,
                  onChanged: (bool an) => _schalte(context, store, an),
                ),
                const Divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.edit_calendar_outlined),
                  title: const Text('Abends ans Tagebuch erinnern'),
                  subtitle: Text('Täglich um '
                      '${store.abendStunde.toString().padLeft(2, '0')}:00'),
                  value: store.abendfrage,
                  onChanged: (bool an) => store.setAbendfrage(an),
                ),
                if (store.abendfrage)
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Uhrzeit der Abendfrage'),
                    trailing: Text(
                        '${store.abendStunde.toString().padLeft(2, '0')}:00'),
                    onTap: () async {
                      final TimeOfDay? gewaehlt = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: store.abendStunde,
                            minute: 0),
                      );
                      if (gewaehlt != null) {
                        await store.setAbendStunde(gewaehlt.hour);
                      }
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: Insets.xl),
          Card(
            child: ListTile(
              leading: Icon(Icons.delete_outline,
                  color: theme.colorScheme.error),
              title: const Text('Alles zurücksetzen'),
              subtitle: const Text('Termin, Name und Tagebuch löschen'),
              onTap: () => _zuruecksetzen(context, store),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _schalte(
      BuildContext context, KindStore store, bool an) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (!an) {
      await store.setErinnerungen(false);
      return;
    }
    final bool ok = await MeldungsDienst().erlaubnis();
    if (!ok) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Benachrichtigungen sind für die App nicht erlaubt. '
            'In den Android-Einstellungen unter „Benachrichtigungen" '
            'freigeben.'),
      ));
      return;
    }
    await store.setErinnerungen(true);
  }

  static Future<void> _zuruecksetzen(
      BuildContext context, KindStore store) async {
    final bool? ja = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Alles zurücksetzen?'),
        content: const Text(
          'Termin, Name und alle Tagebucheinträge werden gelöscht. Das lässt '
          'sich nicht rückgängig machen.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
    if (ja == true) await store.zuruecksetzen();
  }

  static const List<String> _monate = <String>[
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ];

  static String _datum(DateTime d) =>
      '${d.day}. ${_monate[d.month - 1]} ${d.year}';
}

/// Termin eintragen — direkt, oder aus Geburtsdatum und Abweichung.
class _TerminBlatt extends StatefulWidget {
  const _TerminBlatt({required this.store});

  final KindStore store;

  static Future<void> open(BuildContext context, KindStore store) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (BuildContext context) => _TerminBlatt(store: store),
      );

  @override
  State<_TerminBlatt> createState() => _TerminBlattState();
}

class _TerminBlattState extends State<_TerminBlatt> {
  bool _ueberGeburt = false;
  DateTime? _datum;
  int _wochenZuFrueh = 0;

  @override
  void initState() {
    super.initState();
    _datum = widget.store.termin;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime? ergebnis = _datum == null
        ? null
        : _ueberGeburt
            ? terminAusGeburt(_datum!, wochenZuFrueh: _wochenZuFrueh)
            : _datum;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Termin', style: theme.textTheme.titleLarge),
            const SizedBox(height: Insets.md),
            SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                    value: false, label: Text('Termin bekannt')),
                ButtonSegment<bool>(
                    value: true, label: Text('Nur Geburtsdatum')),
              ],
              selected: <bool>{_ueberGeburt},
              onSelectionChanged: (Set<bool> w) =>
                  setState(() => _ueberGeburt = w.first),
            ),
            const SizedBox(height: Insets.lg),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(_datum == null
                  ? (_ueberGeburt ? 'Geburtsdatum wählen' : 'Termin wählen')
                  : EinstellungenScreen._datum(_datum!)),
              onPressed: () async {
                final DateTime jetzt = DateTime.now();
                final DateTime? gewaehlt = await showDatePicker(
                  context: context,
                  initialDate: _datum ?? jetzt,
                  firstDate: DateTime(jetzt.year - 4),
                  lastDate: DateTime(jetzt.year + 2),
                );
                if (gewaehlt != null) setState(() => _datum = gewaehlt);
              },
            ),
            if (_ueberGeburt) ...<Widget>[
              const SizedBox(height: Insets.lg),
              Text('Wie viele Wochen zu früh?',
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: Insets.xs),
              Text(
                'Negative Zahl, wenn das Kind zu spät kam.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: Insets.sm),
              Wrap(
                spacing: Insets.sm,
                runSpacing: Insets.sm,
                children: <Widget>[
                  for (final int w in <int>[-2, -1, 0, 1, 2, 3, 4, 6, 8, 10])
                    ChoiceChip(
                      label: Text(w == 0 ? 'pünktlich' : '$w'),
                      selected: _wochenZuFrueh == w,
                      onSelected: (_) => setState(() => _wochenZuFrueh = w),
                    ),
                ],
              ),
            ],
            if (ergebnis != null) ...<Widget>[
              const SizedBox(height: Insets.lg),
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(Insets.md),
                  child: Text(
                    'Gerechnet wird ab '
                    '${EinstellungenScreen._datum(ergebnis)}.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
              ),
            ],
            const SizedBox(height: Insets.lg),
            Row(
              children: <Widget>[
                if (widget.store.eingerichtet)
                  TextButton(
                    onPressed: () async {
                      await widget.store.setTermin(null);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Löschen'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: ergebnis == null
                      ? null
                      : () async {
                          await widget.store.setTermin(ergebnis);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                  child: const Text('Übernehmen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.store});

  final KindStore store;

  static Future<void> open(BuildContext context, KindStore store) =>
      showDialog<void>(
        context: context,
        builder: (BuildContext context) => _NameDialog(store: store),
      );

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

/// Eigenes Widget, damit der Controller mit dem Dialog lebt und stirbt.
class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _feld =
      TextEditingController(text: widget.store.name);

  @override
  void dispose() {
    _feld.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Name'),
      content: TextField(
        controller: _feld,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Wie heißt das Kind?',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () async {
            await widget.store.setName(_feld.text);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Übernehmen'),
        ),
      ],
    );
  }
}
