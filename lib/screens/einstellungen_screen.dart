import 'package:material_ui/material_ui.dart';

import '../state/kind_store.dart';
import '../state/meldungen.dart';
import '../theme/app_theme.dart';
import '../theme/format.dart';
import 'termin_blatt.dart';

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
          const _Ueberschrift('Das Kind'),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Errechneter Termin'),
                  subtitle: Text(
                    store.termin == null
                        ? 'Noch nicht eingetragen'
                        : datumLang(store.termin!),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => TerminBlatt.open(context, store),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Name'),
                  subtitle: Text(
                    store.name.isEmpty ? 'Ohne Namen' : store.name,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _NameDialog.open(context, store),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.xs,
              Insets.sm,
              Insets.xs,
              0,
            ),
            child: Text(
              'Gezählt wird ab dem errechneten Termin, nicht ab der Geburt — '
              'darauf beruht das ganze Modell. Wer den Termin nicht weiß, gibt '
              'das Geburtsdatum ein und daneben, wie viele Wochen zu früh oder '
              'zu spät.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: Insets.xl),
          const _Ueberschrift('Erinnerungen'),
          Card(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Vor und nach einem Sprung'),
                  subtitle: Text(
                    'Drei Tage vorher und am Ende des Fensters, '
                    'morgens um 9${store.eingerichtet ? "" : " — "
                              "braucht einen Termin"}',
                  ),
                  value: store.erinnerungen,
                  onChanged: (bool an) => _schalte(context, store, an),
                ),
                const Divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.edit_calendar_outlined),
                  title: const Text('Abends ans Tagebuch erinnern'),
                  subtitle: Text(
                    'Täglich um '
                    '${store.abendStunde.toString().padLeft(2, '0')}:00',
                  ),
                  value: store.abendfrage,
                  onChanged: (bool an) => store.setAbendfrage(an),
                ),
                if (store.abendfrage)
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Uhrzeit der Abendfrage'),
                    trailing: Text(
                      '${store.abendStunde.toString().padLeft(2, '0')}:00',
                    ),
                    onTap: () async {
                      final TimeOfDay? gewaehlt = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: store.abendStunde,
                          minute: 0,
                        ),
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
              leading: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Alles zurücksetzen',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              subtitle: const Text('Termin, Name und Tagebuch löschen'),
              onTap: () => _zuruecksetzen(context, store),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _schalte(
    BuildContext context,
    KindStore store,
    bool an,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (!an) {
      await store.setErinnerungen(false);
      return;
    }
    final bool ok = await MeldungsDienst().erlaubnis();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Benachrichtigungen sind für die App nicht erlaubt. '
            'In den Android-Einstellungen unter „Benachrichtigungen" '
            'freigeben.',
          ),
        ),
      );
      return;
    }
    await store.setErinnerungen(true);
  }

  static Future<void> _zuruecksetzen(
    BuildContext context,
    KindStore store,
  ) async {
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
    if (ja == true) await store.zuruecksetzen();
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
  late final TextEditingController _feld = TextEditingController(
    text: widget.store.name,
  );

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
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _speichern(),
        decoration: const InputDecoration(hintText: 'Wie heißt das Kind?'),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _speichern, child: const Text('Übernehmen')),
      ],
    );
  }

  Future<void> _speichern() async {
    await widget.store.setName(_feld.text.trim());
    if (mounted) Navigator.of(context).pop();
  }
}

/// Abschnittstitel in der Grundfarbe, etwas eingerückt wie die Karten.
class _Ueberschrift extends StatelessWidget {
  const _Ueberschrift(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.xs, 0, 0, Insets.sm),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
