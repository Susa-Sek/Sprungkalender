import 'package:flutter/foundation.dart';

/// Ein Entwicklungssprung.
///
/// ## Woher die Zahlen kommen
///
/// Die **Startwochen** (5, 8, 12, 17, 26, 36, 44, 53, 61, 72) sind
/// Sachangaben aus dem Modell von Hetty van de Rijt und Frans Plooij und in
/// der Fachliteratur dokumentiert. Gezählt werden sie ab dem **errechneten
/// Geburtstermin**, nicht ab der Geburt — siehe [sprung_rechner.dart].
///
/// Die **Dauer** ist etwas anderes: Die genauen Spannen stehen im Buch, und
/// das habe ich nicht vorliegen. [dauerTage] trägt deshalb eine konservative
/// Schätzung, die mit dem Alter wächst — **keine Zahl aus dem Buch.** Die App
/// nennt die Phase darum ein „Fenster" und nicht einen Termin, und sie sagt
/// das auch. Wer das Buch hat, korrigiert hier zehn Zahlen.
///
/// Die Titel und Texte sind **selbst geschrieben**. Sie beschreiben, was
/// Kinder in diesem Alter oft zeigen, und stützen sich auf allgemein
/// dokumentierte Entwicklungsschritte — nicht auf Formulierungen aus dem
/// Buch oder seiner App.
@immutable
class Sprung {
  const Sprung({
    required this.nummer,
    required this.startWoche,
    required this.dauerTage,
    required this.titel,
    required this.anzeichen,
    required this.danach,
  });

  /// 1 bis 10.
  final int nummer;

  /// Wochen nach dem errechneten Termin, an denen das Fenster beginnt.
  final int startWoche;

  /// Wie lange die unruhige Phase etwa dauert. Eine Schätzung.
  final int dauerTage;

  /// Eine kurze Überschrift — was in dieser Zeit neu dazukommt.
  final String titel;

  /// Was Eltern in der unruhigen Phase oft beobachten.
  final String anzeichen;

  /// Welche Fähigkeiten danach bei vielen Kindern auftauchen.
  final String danach;

  int get startTag => startWoche * 7;
  int get endTag => startTag + dauerTage;
}

/// Die zehn Sprünge des Modells.
const List<Sprung> kSpruenge = <Sprung>[
  Sprung(
    nummer: 1,
    startWoche: 5,
    dauerTage: 7,
    titel: 'Wacher und aufmerksamer',
    anzeichen: 'Mehr Weinen ohne erkennbaren Grund, unruhiger Schlaf, will '
        'lieber getragen werden als liegen.',
    danach: 'Schaut Gesichter länger an und folgt ihnen mit den Augen. Das '
        'erste echte Lächeln als Antwort kommt bei vielen Kindern in diesen '
        'Wochen. Die Sinne werden wacher: Geräusche, Gerüche und Berührungen '
        'werden deutlicher unterschieden.',
  ),
  Sprung(
    nummer: 2,
    startWoche: 8,
    dauerTage: 7,
    titel: 'Hände entdecken',
    anzeichen: 'Quengelig am Abend, braucht mehr Körperkontakt, trinkt '
        'unregelmäßiger.',
    danach: 'Betrachtet die eigenen Hände und führt sie zum Mund. Schlägt '
        'nach Dingen, die über ihm hängen. Die ersten Laute jenseits des '
        'Weinens — Gurren und Vokale.',
  ),
  Sprung(
    nummer: 3,
    startWoche: 12,
    dauerTage: 7,
    titel: 'Fließendere Bewegungen',
    anzeichen: 'Schläft schlechter ein, ist leichter überreizt, langweilt '
        'sich schneller.',
    danach: 'Die Bewegungen werden runder statt ruckartig. Der Kopf wird in '
        'Bauchlage sicher gehalten. Lautes Lachen, Kreischen, erste '
        'Drehversuche.',
  ),
  Sprung(
    nummer: 4,
    startWoche: 17,
    dauerTage: 14,
    titel: 'Greifen und begreifen',
    anzeichen: 'Wacht nachts häufiger auf, will ständig beschäftigt werden, '
        'ist ohne Nähe schwer zu beruhigen.',
    danach: 'Greift gezielt nach einem Gegenstand und steckt ihn in den '
        'Mund. Gibt Dinge von einer Hand in die andere. Merkt, dass eigenes '
        'Tun etwas auslöst — und wiederholt es deshalb.',
  ),
  Sprung(
    nummer: 5,
    startWoche: 26,
    dauerTage: 21,
    titel: 'Nähe und Entfernung',
    anzeichen: 'Fremdeln beginnt, klammert beim Weggehen, schläft '
        'unruhiger — oft der Sprung, der Eltern am meisten zusetzt.',
    danach: 'Sitzt mit wenig Hilfe. Begreift, dass Dinge und Menschen auch '
        'dann noch da sind, wenn man sie nicht sieht — daher das Fremdeln '
        'und die Freude an Verstecken. Silbenketten wie „ba-ba-ba".',
  ),
  Sprung(
    nummer: 6,
    startWoche: 36,
    dauerTage: 28,
    titel: 'Sortieren und erkennen',
    anzeichen: 'Stimmungswechsel, probiert Grenzen aus, will überall dabei '
        'sein.',
    danach: 'Robbt oder krabbelt. Nimmt Kleines zwischen Daumen und '
        'Zeigefinger. Erkennt wieder, was zusammengehört: Hund und Hund, '
        'Ball und Ball. Zeigt auf Dinge, die es haben will.',
  ),
  Sprung(
    nummer: 7,
    startWoche: 44,
    dauerTage: 28,
    titel: 'Eins nach dem anderen',
    anzeichen: 'Schlechter Schlaf, großes Theater beim Anziehen und Wickeln, '
        'braucht viel Aufmerksamkeit.',
    danach: 'Zieht sich zum Stehen hoch und läuft an Möbeln entlang. Steckt '
        'Dinge ineinander und holt sie heraus. Winken, Klatschen, erste '
        'Wörter mit Bedeutung.',
  ),
  Sprung(
    nummer: 8,
    startWoche: 53,
    dauerTage: 28,
    titel: 'Eigene Vorhaben',
    anzeichen: 'Will selbst bestimmen, wird wütend, wenn etwas nicht geht, '
        'wechselt zwischen Anhänglichkeit und Trotz.',
    danach: 'Erste freie Schritte bei vielen Kindern. Führt kleine Vorhaben '
        'aus: Schublade öffnen, Inhalt ausräumen, weitergehen. Versteht '
        'einfache Aufforderungen.',
  ),
  Sprung(
    nummer: 9,
    startWoche: 61,
    dauerTage: 35,
    titel: 'Grenzen ausprobieren',
    anzeichen: 'Testet Reaktionen, sagt „nein", Wutausbrüche, schläft '
        'schlechter ein.',
    danach: 'Klettert, rennt, kritzelt. Probiert aus, was passiert, wenn es '
        'etwas Verbotenes tut — und beobachtet dabei das Gesicht der Eltern. '
        'Der Wortschatz wächst merklich.',
  ),
  Sprung(
    nummer: 10,
    startWoche: 72,
    dauerTage: 28,
    titel: 'Ich und die anderen',
    anzeichen: 'Starker eigener Willen, „meins", Streit um Kleinigkeiten, '
        'braucht trotzdem viel Nähe.',
    danach: 'Sagt „ich" und „meins" und meint sich damit. Spielt etwas vor — '
        'füttert eine Puppe, telefoniert mit einem Klotz. Merkt, dass andere '
        'anders fühlen als es selbst.',
  ),
];

/// Der Satz, der unter jeder Sprungseite steht.
///
/// **Warum er dort steht.** Die Sprungwochen sind ein beliebtes Modell, keine
/// gesicherte Tatsache: Die Grundlage sind Beobachtungsstudien mit kleinen
/// Stichproben, und eine Replikation von de Weerth und van Geert (1998) fand
/// keinen Zusammenhang zwischen den vorhergesagten Wochen und mehr Quengeln.
/// Eine App, die das verschweigt, verkauft einen Fahrplan, den es so nicht
/// gibt.
const String kModellHinweis =
    'Die Sprungwochen sind ein verbreitetes Modell, keine gesicherte '
    'Tatsache: Eine unabhängige Nachuntersuchung (de Weerth und van Geert, '
    '1998) fand keinen Zusammenhang zwischen den vorhergesagten Wochen und '
    'mehr Unruhe. Nimm die Fenster als grobe Orientierung — und schau im '
    'Tagebuch nach, ob sie bei deinem Kind überhaupt passen.';

/// Der Satz, der unter jeder Entwicklungsbeschreibung steht.
const String kEntwicklungHinweis =
    'Kinder entwickeln sich sehr unterschiedlich schnell. Diese Angaben sind '
    'eine Orientierung und keine Prüfliste. Wenn dich etwas beunruhigt, '
    'frag die Kinderärztin oder den Kinderarzt — nicht eine App.';
