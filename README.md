# Sprungkalender

Die zehn Entwicklungssprünge des ersten Lebensjahres — gerechnet **ab dem
errechneten Geburtstermin**, mit Tagebuch und Erinnerungen.

```
   ┌──────────────────────────────────┐
   │ Woche 5                          │
   │ korrigiertes Alter               │
   └──────────────────────────────────┘
   ┌──────────────────────────────────┐
   │ Sprung 1 läuft                   │
   │ Wacher und aufmerksamer          │
   │ ▓▓▓▓▓░░░░░░░░░░░░░░░░            │
   │ Noch etwa 4 Tage — das Fenster   │
   │ ist eine Schätzung, kein Termin. │
   └──────────────────────────────────┘
```

## Was diese App ist, und was nicht

Sie tut dasselbe wie „Oje, ich wachse!" / „The Wonder Weeks", ist aber **keine
Kopie davon**:

* Die **Wochenzahlen** (5, 8, 12, 17, 26, 36, 44, 53, 61, 72) sind
  Sachangaben aus dem Modell von Hetty van de Rijt und Frans Plooij und in der
  Fachliteratur dokumentiert.
* **Alle Texte, der Name, die Gestaltung und das Symbol sind eigen.** Nichts
  davon ist aus dem Buch oder seiner App übernommen — keine Formulierungen,
  keine Illustrationen, kein Logo.

Wer die App weitergeben will, sollte das einmal von jemandem mit Markenrecht
ansehen lassen. Das kann diese Datei nicht beurteilen.

## Ab dem Termin, nicht ab der Geburt

Das ist der Kern des Modells und die Stelle, an der ein Nachbau als Erstes
falsch rechnet. Bei einem Kind, das **sechs Wochen zu früh** kam, liegt
zwischen Geburt und errechnetem Termin ein Unterschied von sechs Wochen —
jeder Sprung wäre um anderthalb Monate verschoben.

Wer den Termin nicht weiß, gibt das Geburtsdatum ein und daneben, wie viele
Wochen zu früh oder zu spät; `terminAusGeburt` rechnet ihn daraus
(`lib/state/sprung_rechner.dart`). Ein Test hält genau diesen Fall fest.

## Was die App über sich selbst sagt

Die Sprungwochen sind ein **verbreitetes Modell, keine gesicherte Tatsache.**
Die Grundlage sind Beobachtungsstudien mit kleinen Stichproben; eine
unabhängige Nachuntersuchung von de Weerth und van Geert (1998, *British
Journal of Developmental Psychology*,
[doi 10.1111/j.2044-835X.1998.tb00748.x](https://doi.org/10.1111/j.2044-835X.1998.tb00748.x))
fand **keinen** Zusammenhang zwischen den vorhergesagten Wochen und mehr
Unruhe oder höherem Cortisol.

Das steht auch **in** der App, auf der Startseite und auf jeder Sprungseite —
nicht versteckt in einem Impressum. Eine App, die das verschweigt, verkauft
einen Fahrplan, den es so nicht gibt.

Und genau deshalb ist das **Tagebuch** der eigentliche Wert: Es zeigt
hinterher, ob die Fenster bei *diesem* Kind überhaupt gepasst haben. Tage, die
in einem Sprungfenster lagen, sind in der Liste eingefärbt.

## Die Dauer der Fenster ist geschätzt

Die Startwochen sind belegt, die genauen **Spannen** stehen im Buch — das lag
beim Bauen nicht vor, und erfundene Genauigkeit wäre schlimmer als eine offen
benannte Schätzung. `dauerTage` in `lib/data/spruenge.dart` wächst deshalb
konservativ mit dem Alter, die App nennt die Phase ein „Fenster" und sagt
dazu, dass es eine Schätzung ist.

**Wer das Buch hat, korrigiert zehn Zahlen** — eine Zeile je Sprung, und die
Tests bleiben grün, solange die Fenster sich nicht überschneiden.

## Erinnerungen

Je Sprung zwei, morgens um 9:

* **Drei Tage vor** dem Fenster — damit man weiß, woran man ist, bevor die
  Nacht schlecht wird.
* **Am Ende** des Fensters — „Schau, was neu ist." Das ist der Teil, den man
  sonst verpasst: Nach einer anstrengenden Woche fällt kaum auf, was das Kind
  plötzlich kann.

Dazu eine abschaltbare Abendfrage fürs Tagebuch.

**Ohne eingetragenen Termin gibt es keine Erinnerung** — lieber keine als eine
zur falschen Zeit. Und der Horizont begrenzt nur die Abendfrage, nicht die
Sprünge: Bei einem Kind, das erst in fünf Monaten errechnet ist, läge sonst
sogar der *erste* Sprung jenseits eines halben Jahres, und man bekäme gar
nichts, bis man die App das nächste Mal öffnet.

## Aufbau

```
lib/
├── main.dart                     App, Theme, zwei Bereiche
├── data/spruenge.dart            die zehn Sprünge + die beiden Hinweise
├── state/sprung_rechner.dart     rein: was heute ansteht
├── state/kind_store.dart         Termin, Name, Tagebuch — ein Schlüssel
├── state/meldungen.dart          Erinnerungen, Backend hinter Schnittstelle
├── screens/                      Heute, Sprung, Tagebuch, Einstellungen
└── theme/app_theme.dart          Raster, hell und dunkel
```

Das Muster — reine Funktionen vor den Bildschirmen, Plattformdienste hinter
einer Schnittstelle, ein Speicherschlüssel, eine eingesetzte Uhr — ist aus
**Täglich Klüger** übernommen, derselben Handschrift. Es macht die Randfälle
im Test nachrechenbar, und davon hat diese App viele: vor dem Termin, am
ersten und letzten Tag eines Fensters, zwischen zwei Sprüngen, nach dem
zehnten, im Schaltjahr.

## Entwickeln

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

## Signierschlüssel

Ohne eigenen Schlüssel signiert der Bau mit dem **Debug-Schlüssel**, und den
erzeugt jeder CI-Läufer frisch — jede Version trägt dann eine andere
Signatur, Android verweigert das Drüberinstallieren, und beim Neuinstallieren
sind Termin und Tagebuch weg.

Vier Secrets unter **Settings → Secrets and variables → Actions**:

| Secret | Wert |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Ausgabe von `base64 -w0 upload.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | das Kennwort |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | dasselbe Kennwort |

Derselbe Keystore wie für eine andere App ist in Ordnung, solange die
Paketnamen verschieden sind — hier `de.susasek.sprungkalender`.

## Bewusst offen

* **Ein Kind.** Mehrere wären eine Auswahl auf jedem Bildschirm; das kommt,
  wenn sich das eine bewährt hat.
* **Kein Widget, keine Sicherung, kein Selbst-Update** in dieser Version. Die
  Bausteine dafür liegen in Täglich Klüger bereit und lassen sich übernehmen.
* **Nicht am Gerät gesehen.** Ob die Liste der zehn Sprünge auf einem schmalen
  Telefon gut liest, zeigt erst das Telefon; geprüft ist sie bei 320 px und
  150 % Schrift im Test.
