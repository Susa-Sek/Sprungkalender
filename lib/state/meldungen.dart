import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/spruenge.dart';
import 'sprung_rechner.dart';

/// Eine geplante Meldung.
@immutable
class GeplanteMeldung {
  const GeplanteMeldung({
    required this.id,
    required this.wann,
    required this.titel,
    required this.text,
  });

  final int id;
  final DateTime wann;
  final String titel;
  final String text;

  @override
  String toString() => '#$id $wann — $titel';
}

/// Der Teil des Benachrichtigungssystems, den die App benutzt.
///
/// Hinter einer Schnittstelle, damit die Planung ohne Gerät prüfbar ist —
/// dasselbe Muster wie in Täglich Klüger.
abstract class MeldungsBackend {
  Future<void> init();

  /// Fragt das System. `false`, wenn der Nutzer ablehnt.
  Future<bool> requestPermission();

  Future<void> schedule(GeplanteMeldung meldung);

  Future<void> cancelAll();
}

/// Die echte Umsetzung.
class LokaleMeldungen implements MeldungsBackend {
  LokaleMeldungen([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'sprung_meldungen';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _bereit = false;

  @override
  Future<void> init() async {
    if (_bereit) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _bereit = true;
    } catch (error) {
      debugPrint('Benachrichtigungen nicht verfügbar: $error');
    }
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    try {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final IOSFlutterLocalNotificationsPlugin? ios =
          _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
      return false;
    } catch (error) {
      debugPrint('Berechtigung nicht erfragbar: $error');
      return false;
    }
  }

  @override
  Future<void> schedule(GeplanteMeldung meldung) async {
    await init();
    try {
      await _plugin.zonedSchedule(
        id: meldung.id,
        title: meldung.titel,
        body: meldung.text,
        scheduledDate: tz.TZDateTime.from(meldung.wann, tz.local),
        // Ungenaue Planung reicht und erspart die Sonderberechtigung für
        // exakte Alarme: Ein Sprungfenster ist Wochen lang, keine Minute.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Sprünge und Tagebuch',
            channelDescription:
                'Meldet, wenn ein Sprungfenster beginnt oder endet.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (error) {
      debugPrint('Meldung nicht planbar: $error');
    }
  }

  @override
  Future<void> cancelAll() async {
    await init();
    try {
      await _plugin.cancelAll();
    } catch (error) {
      debugPrint('Meldungen nicht löschbar: $error');
    }
  }
}

/// Wie viele Tage vor einem Fenster die Vorwarnung kommt.
const int kVorlaufTage = 3;

/// Die Meldungen der nächsten [horizonTage] Tage — rein und testbar.
///
/// Je Sprung zwei:
///
/// * **Vorher**, [kVorlaufTage] Tage vor dem Fenster: damit man weiß, woran
///   man ist, bevor die Nacht schlecht wird.
/// * **Am Ende** des Fensters: „Schau, was neu ist." Das ist der Teil, den
///   man sonst verpasst — nach einer anstrengenden Woche fällt kaum auf, was
///   das Kind plötzlich kann.
///
/// **Ohne Termin keine Meldung.** Lieber keine als eine zur falschen Zeit;
/// das Modell rechnet ab dem errechneten Termin, und den kennt nur, wer ihn
/// eingetragen hat.
///
/// Vergangenes wird übersprungen: Eine Meldung mit einem Zeitpunkt in der
/// Vergangenheit stellt Android sofort zu, und das wäre bei einem Sprung von
/// vor vier Monaten unsinnig.
///
/// **[horizonTage] begrenzt nur die Abendfrage, nicht die Sprünge.** Der
/// zehnte Sprung liegt über 500 Tage nach dem Termin, und bei einem Kind,
/// das erst in fünf Monaten kommt, läge sogar der **erste** jenseits eines
/// halben Jahres — mit einem Horizont über allem bekäme man dann gar keine
/// Meldung, bis man die App das nächste Mal öffnet. Zwanzig Sprungmeldungen
/// sind für Android nichts; die tägliche Abendfrage ist der Teil, der ohne
/// Grenze ins Uferlose wüchse.
List<GeplanteMeldung> planeMeldungen({
  required DateTime? termin,
  required DateTime jetzt,
  bool erinnerungen = true,
  bool abendfrage = false,
  int abendStunde = 20,
  String name = '',
  int horizonTage = 180,
}) {
  if (termin == null || !erinnerungen) return const <GeplanteMeldung>[];

  final DateTime t = tagVon(termin);
  final String wen = name.trim().isEmpty ? 'dein Kind' : name.trim();
  final List<GeplanteMeldung> meldungen = <GeplanteMeldung>[];

  for (final Sprung s in kSpruenge) {
    // Morgens um 9 — nicht nachts, und nicht mitten im Abendchaos.
    final DateTime vorher = t
        .add(Duration(days: s.startTag - kVorlaufTage))
        .add(const Duration(hours: 9));
    final DateTime ende =
        t.add(Duration(days: s.endTag)).add(const Duration(hours: 9));

    if (vorher.isAfter(jetzt)) {
      meldungen.add(GeplanteMeldung(
        id: 1000 + s.nummer * 2,
        wann: vorher,
        titel: 'Sprung ${s.nummer} steht an',
        text: 'In $kVorlaufTage Tagen beginnt das Fenster — $wen wird '
            'vielleicht unruhiger. Es geht vorbei.',
      ));
    }
    if (ende.isAfter(jetzt)) {
      meldungen.add(GeplanteMeldung(
        id: 1000 + s.nummer * 2 + 1,
        wann: ende,
        titel: 'Sprung ${s.nummer} ist durch',
        text: '${s.titel}. Schau mal, was $wen jetzt kann.',
      ));
    }
  }

  if (abendfrage) {
    for (int tag = 0; tag < horizonTage; tag++) {
      final DateTime wann = tagVon(jetzt)
          .add(Duration(days: tag))
          .add(Duration(hours: abendStunde));
      if (!wann.isAfter(jetzt)) continue;
      meldungen.add(GeplanteMeldung(
        // Ein eigener Bereich, der die Sprung-Kennungen nicht überschreibt.
        id: 5000 + tag,
        wann: wann,
        titel: 'Wie war der Tag?',
        text: 'Zwei Tipps fürs Tagebuch — später weiß man es nicht mehr.',
      ));
    }
  }

  meldungen.sort((GeplanteMeldung a, GeplanteMeldung b) =>
      a.wann.compareTo(b.wann));
  return meldungen;
}

/// Plant die Meldungen auf dem Gerät.
class MeldungsDienst {
  MeldungsDienst({MeldungsBackend? backend})
      : _backend = backend ?? LokaleMeldungen();

  final MeldungsBackend _backend;

  Future<bool> erlaubnis() => _backend.requestPermission();

  /// Alles verwerfen und neu planen.
  ///
  /// Beim Start und beim Zuklappen der App: Ändert sich der Termin, muss der
  /// ganze Plan neu geschrieben werden, und eine halb alte Reihe von
  /// Meldungen wäre schlimmer als keine.
  Future<void> neuPlanen({
    required DateTime? termin,
    required DateTime jetzt,
    bool erinnerungen = true,
    bool abendfrage = false,
    int abendStunde = 20,
    String name = '',
  }) async {
    await _backend.cancelAll();
    for (final GeplanteMeldung m in planeMeldungen(
      termin: termin,
      jetzt: jetzt,
      erinnerungen: erinnerungen,
      abendfrage: abendfrage,
      abendStunde: abendStunde,
      name: name,
    )) {
      await _backend.schedule(m);
    }
  }
}
