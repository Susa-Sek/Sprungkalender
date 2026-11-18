import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sprung_rechner.dart';

/// Wie der Tag war — drei Stufen, nicht fünf.
///
/// Drei lassen sich im Vorbeigehen antippen; bei fünf überlegt man, und wer
/// überlegt, trägt irgendwann nichts mehr ein.
enum Stimmung {
  gut('gut', 'Zufrieden'),
  mittel('mittel', 'Wechselhaft'),
  quengelig('quengelig', 'Quengelig');

  const Stimmung(this.id, this.label);

  final String id;
  final String label;

  static Stimmung? byId(String? id) {
    for (final Stimmung s in values) {
      if (s.id == id) return s;
    }
    return null;
  }
}

enum Schlaf {
  gut('gut', 'Gut geschlafen'),
  mittel('mittel', 'Mittel'),
  unruhig('unruhig', 'Unruhig');

  const Schlaf(this.id, this.label);

  final String id;
  final String label;

  static Schlaf? byId(String? id) {
    for (final Schlaf s in values) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// Ein Tag im Tagebuch.
@immutable
class TagebuchEintrag {
  const TagebuchEintrag({
    required this.tag,
    this.stimmung,
    this.schlaf,
    this.notiz = '',
  });

  /// „2026-11-18" — ein Eintrag je Tag.
  final String tag;

  final Stimmung? stimmung;
  final Schlaf? schlaf;
  final String notiz;

  bool get leer => stimmung == null && schlaf == null && notiz.trim().isEmpty;

  TagebuchEintrag mit({
    Stimmung? stimmung,
    Schlaf? schlaf,
    String? notiz,
    bool stimmungLoeschen = false,
    bool schlafLoeschen = false,
  }) =>
      TagebuchEintrag(
        tag: tag,
        stimmung: stimmungLoeschen ? null : (stimmung ?? this.stimmung),
        schlaf: schlafLoeschen ? null : (schlaf ?? this.schlaf),
        notiz: notiz ?? this.notiz,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (stimmung != null) 's': stimmung!.id,
        if (schlaf != null) 'z': schlaf!.id,
        if (notiz.trim().isNotEmpty) 'n': notiz,
      };

  static TagebuchEintrag fromJson(String tag, Map<String, dynamic> json) =>
      TagebuchEintrag(
        tag: tag,
        stimmung: Stimmung.byId(json['s'] as String?),
        schlaf: Schlaf.byId(json['z'] as String?),
        notiz: (json['n'] as String?) ?? '',
      );
}

/// Alles, was die App sich merkt: ein Kind, ein Termin, ein Tagebuch.
///
/// **Ein Speicherschlüssel, ein JSON.** Dasselbe Muster wie der Lernstand in
/// Täglich Klüger: So ist die Sicherung genau das, was auf dem Gerät liegt,
/// und es gibt kein zweites Format, das veraltet.
///
/// **Ein Kind in dieser Version.** Mehrere wären eine Auswahl auf jedem
/// Bildschirm; das kommt, wenn sich das eine bewährt hat.
class KindStore extends ChangeNotifier {
  KindStore({SharedPreferences? preferences, DateTime Function()? clock})
      : _prefs = preferences,
        _now = clock ?? DateTime.now;

  /// Nicht umbenennen — siehe test/naming_test.dart.
  static const String storageKey = 'sprungkalender.kind.v1';

  /// So weit im Voraus werden Erinnerungen geplant.
  static const int horizonDays = 180;

  SharedPreferences? _prefs;
  final DateTime Function() _now;

  DateTime? _termin;
  String _name = '';
  bool _erinnerungen = true;
  bool _abendfrage = false;
  int _abendStunde = 20;
  final Map<String, TagebuchEintrag> _tagebuch = <String, TagebuchEintrag>{};
  bool _geladen = false;

  bool get isLoaded => _geladen;

  /// Der errechnete Termin. `null`, solange nichts eingetragen ist — dann
  /// gibt es keine Rechnung und keine Erinnerung.
  DateTime? get termin => _termin;
  bool get eingerichtet => _termin != null;

  String get name => _name;
  bool get erinnerungen => _erinnerungen;
  bool get abendfrage => _abendfrage;
  int get abendStunde => _abendStunde;

  /// Die Einträge, neueste zuerst.
  List<TagebuchEintrag> get tagebuch {
    final List<TagebuchEintrag> alle = _tagebuch.values.toList()
      ..sort((TagebuchEintrag a, TagebuchEintrag b) => b.tag.compareTo(a.tag));
    return alle;
  }

  TagebuchEintrag eintragFuer(DateTime tag) {
    final String k = tagSchluessel(tag);
    return _tagebuch[k] ?? TagebuchEintrag(tag: k);
  }

  /// Mitternacht des heutigen Tages.
  ///
  /// **Eine Quelle für „heute".** Der Tagebuch-Bildschirm rief anfangs
  /// selbst `DateTime.now()`; damit war er nicht prüfbar, und der Eintrag
  /// konnte zu einem anderen Tag gehören als der Sprungstand daneben. Jetzt
  /// kommt die Zeit von hier — und im Test aus der eingesetzten Uhr.
  DateTime get heute => tagVon(_now());

  /// Was heute ansteht. `null` ohne Termin.
  SprungStand? get stand => _termin == null
      ? null
      : berechne(termin: _termin!, heute: _now());

  Future<void> load() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final String? roh = _prefs?.getString(storageKey);
      if (roh != null && roh.isNotEmpty) uebernehmen(roh);
    } catch (error) {
      debugPrint('Stand nicht lesbar: $error');
    }
    _geladen = true;
    notifyListeners();
  }

  /// Einen gespeicherten Stand einlesen — auch aus einer Sicherung.
  ///
  /// Nachsichtig: Fehlt ein Feld, gilt die Vorgabe. Eine Datei aus einer
  /// älteren Version soll sich weiter lesen lassen.
  void uebernehmen(String roh) {
    final Object? json = jsonDecode(roh);
    if (json is! Map) return;

    final Object? t = json['termin'];
    _termin = t is String ? DateTime.tryParse(t) : null;
    if (_termin != null) _termin = tagVon(_termin!);
    _name = (json['name'] as String?) ?? '';
    _erinnerungen = (json['erinnerungen'] as bool?) ?? true;
    _abendfrage = (json['abendfrage'] as bool?) ?? false;
    _abendStunde = ((json['abendStunde'] as num?)?.toInt() ?? 20).clamp(0, 23);

    _tagebuch.clear();
    final Object? buch = json['tagebuch'];
    if (buch is Map) {
      for (final MapEntry<Object?, Object?> e in buch.entries) {
        if (e.key is! String || e.value is! Map) continue;
        _tagebuch[e.key! as String] = TagebuchEintrag.fromJson(
          e.key! as String,
          Map<String, dynamic>.from(e.value! as Map),
        );
      }
    }
  }

  /// Der ganze Stand als JSON — das, was gespeichert und gesichert wird.
  String ausgeben() => jsonEncode(<String, dynamic>{
        if (_termin != null) 'termin': _termin!.toIso8601String(),
        'name': _name,
        'erinnerungen': _erinnerungen,
        'abendfrage': _abendfrage,
        'abendStunde': _abendStunde,
        'tagebuch': <String, dynamic>{
          for (final MapEntry<String, TagebuchEintrag> e in _tagebuch.entries)
            if (!e.value.leer) e.key: e.value.toJson(),
        },
      });

  Future<void> _schreibe() async {
    notifyListeners();
    try {
      await _prefs?.setString(storageKey, ausgeben());
    } catch (error) {
      debugPrint('Stand nicht speicherbar: $error');
    }
  }

  Future<void> setTermin(DateTime? termin) async {
    _termin = termin == null ? null : tagVon(termin);
    await _schreibe();
  }

  Future<void> setName(String name) async {
    _name = name.trim();
    await _schreibe();
  }

  Future<void> setErinnerungen(bool an) async {
    _erinnerungen = an;
    await _schreibe();
  }

  Future<void> setAbendfrage(bool an) async {
    _abendfrage = an;
    await _schreibe();
  }

  Future<void> setAbendStunde(int stunde) async {
    _abendStunde = stunde.clamp(0, 23);
    await _schreibe();
  }

  /// Einen Tag im Tagebuch ändern. Ein leerer Eintrag wird entfernt, damit
  /// der Speicher nicht mit Leerzeilen wächst.
  Future<void> setzeEintrag(TagebuchEintrag eintrag) async {
    if (eintrag.leer) {
      _tagebuch.remove(eintrag.tag);
    } else {
      _tagebuch[eintrag.tag] = eintrag;
    }
    await _schreibe();
  }

  /// Einen Stand aus einer Sicherung einspielen.
  Future<void> einspielen(String roh) async {
    uebernehmen(roh);
    await _schreibe();
  }

  Future<void> zuruecksetzen() async {
    _termin = null;
    _name = '';
    _erinnerungen = true;
    _abendfrage = false;
    _abendStunde = 20;
    _tagebuch.clear();
    await _schreibe();
  }
}

/// Macht den Stand im Baum verfügbar.
class KindScope extends InheritedNotifier<KindStore> {
  const KindScope({super.key, required KindStore store, required super.child})
      : super(notifier: store);

  static KindStore of(BuildContext context) {
    final KindScope? scope =
        context.dependOnInheritedWidgetOfExactType<KindScope>();
    assert(scope != null, 'Kein KindScope im Widget-Baum');
    return scope!.notifier!;
  }
}
