# Anforderung · Edvance-Studio (Erklärvideos)

**Für:** Rasit, Ashkan, Tolunay, Lena · **Stand:** 27.10.2026 · **Klick-Dummy:** `claude/studio-dummy.html` (21.10., Abweichungen in Abschnitt 11)
**Grundlage:** Gespräch Rasit 21.10. und 27.10., Session-Rahmen E1/E2a (Erklärsequenz, `erklaer_start`, `erklaer_check_abgeben`, `erklaer_nachlesen`), Anforderung Themenbaum, Remotion-Lizenzbedingungen (abgerufen 27.10.2026)

## 1 · Wozu

Im Studio entstehen die Erklärvideos für die Sessions. Ashkan schreibt, vertont, rendert und reicht zur Prüfung ein. Die Gründer und Lena prüfen und geben frei. Die Schüler-App bekommt nur freigegebene Videos, in der Interessenswelt des Kindes.

**Leitsätze**
1. **Ein Video ist eine neue Darstellungsform der bestehenden Erklärsequenz aus E1, kein zweites System.** Kernidee, Check, Fehlbild und Fortschritt bleiben, wie sie sind. Neu ist: Eine Kernidee kann als Videoabschnitt gezeigt werden, und ein falscher Check kann auf einen Beat zurückspulen.
2. **Beats statt Sekunden.** Ein Skript ist eine Liste von Beats. Ein Beat besteht aus einem Satz, einem Animationsschritt und einer Sprungmarke. Ein Beat dauert so lange wie sein Satz.
3. **Bausteine statt Einzelanimationen.** Jeder Beat wählt einen Baustein aus der Bibliothek und füllt seine Parameter. Pro Sequenz wird kein eigener Animationscode geschrieben.
4. **Die Interessenswelt ist ein Skin.** Varianten tauschen nur Sprechtext und Bildparameter. Mathematik, Zahlen, Reihenfolge und Rücksprünge kommen immer aus dem Skelett.
5. **Nichts erreicht ein Kind ungeprüft.** Erst nach beiden Freigaben und einem Render nach der letzten Änderung.

## 2 · Rollen

| Rolle | Wer | Darf |
|---|---|---|
| Autor | in der Regel Ashkan | Sequenz anlegen, Skript importieren und bearbeiten, Stimmen erzeugen, rendern, einreichen |
| Verständlich bestätigen | ein Gründer, nie der Autor | „Kann ich ohne Vorwissen nachvollziehen“ oder Anmerkung an einem Beat |
| Fachlich prüfen | Lena (Rasit als Vertretung), nie der Autor | Skelett-Video einmal ganz ansehen, „passt“ oder „passt nicht“ an einem Beat; Varianten-Texte freigeben |
| Admin | Rasit | alles, auch zurückziehen |

Die Regel „Prüfer ≠ Autor“ steht in der Datenbank, nicht nur in der Oberfläche.

## 3 · Ablauf einer Sequenz

```
Entwurf → Vertont → Gerendert → In Prüfung → Freigegeben
             ↑__________________________|  (Änderung an Text oder Baustein)
```

1. **Anlegen.** Thema und Skill wählen (Katalog `skill_thema`). Das Studio zeigt, ob es für den Skill schon eine Erklärsequenz aus E1 gibt; die neue Videosequenz hängt sich daran.
2. **Skript mit Claude ausarbeiten** (Abschnitt 4), dann ins Studio einfügen. Das Studio prüft den Import, bevor er gespeichert wird.
3. **Feinschliff im Beat-Editor.** Text, Sprungmarke, Baustein, Parameter, Welten-Reiter, Mini-Checks mit Rücksprung.
4. **Stimmen erzeugen** (Abschnitt 5): je Beat und Welt eine Audiodatei, nur für geänderte Sätze.
5. **Rendern** (Abschnitt 7): je Welt ein MP4, eine Kapiteldatei, Untertitel und ein Vorschaubild.
6. **Einreichen.** Prüfung verständlich und fachlich in beliebiger Reihenfolge, Varianten als Text.
7. **Freigeben.** Sind beide Freigaben erteilt, die Varianten-Texte geprüft und ist der Render aktuell, wird die Sequenz freigegeben. Ab der nächsten Session sehen Kinder sie.
8. **Ändern nach Freigabe.** Jede Text- oder Bausteinänderung setzt die betroffene Freigabe zurück und verlangt einen neuen Render. Bis zur neuen Freigabe sehen Kinder die alte freigegebene Fassung.

## 4 · Skript mit Claude (ohne API-Schlüssel)

- Ashkan arbeitet das Skript in einem **Claude-Projekt „Edvance Studio“** aus. Das Projekt enthält einen Skill mit Beat-Format, Bausteinliste samt Parametern, Sprachregeln und dem Quadratwurzel-Skript als Beispiel.
- Claude gibt am Ende **ein JSON** im Format aus Anhang A aus. Ashkan fügt es im Studio unter „Skript einfügen“ ein.
- So braucht die Plattform keinen `ANTHROPIC_API_KEY` (Entscheidung Rasit 01.10.). Den In-App-Chat aus dem Dummy gibt es deshalb nicht.

**Prüfung beim Import** (blockiert das Speichern mit klarer Meldung):
- Jeder Baustein ist bekannt, jeder Parameter gültig.
- Jede Beat-ID ist eindeutig, jede Sprungmarke höchstens 40 Zeichen lang.
- Jeder Rücksprung zeigt auf einen vorhandenen Beat.
- **Zahlen-Sperre:** Jede Variante nennt dieselben Zahlen wie das Skelett (Ziffern und Zahlwörter).
- Im Sprechtext stehen keine Formeln: „drei Viertel“ statt „3/4“, „x hoch zwei“ statt „x²“. Formeln gehören in die Bildparameter.
- Jedes Fehlbild eines Mini-Checks gibt es im Fehlbild-Katalog der LSA (`known_errors`).

## 5 · Stimme

- **ElevenLabs auf dem Server** über eine Route in Edvancev1. Der Schlüssel liegt nur in den Vercel-Umgebungsvariablen, nie im Browser oder Repo. Aufrufen dürfen nur Autor und Admin.
- **Eine feste Edvance-Stimme** aus der Bibliothek, keine, die nach einer bekannten realen Person klingt. Ein mehrsprachiges Modell für Deutsch. Ein Aussprache-Wörterbuch für Fachbegriffe.
- **Je Beat und Welt eine Datei.** Der Dateiname ist der Fingerabdruck aus Stimme, Modell und Satz. Ein unveränderter Satz wird nie neu vertont, und eine Variante ohne eigenen Satz übernimmt die Datei des Skeletts.
- **Zeitstempel mitspeichern** (Endpunkt „with timestamps“). Für den Start genügt die Beat-Ebene; mit den Zeitstempeln lässt sich später ein einzelnes Wort hervorheben, ohne neu zu vertonen.
- **Kontext mitgeben:** Satz davor und danach, damit die Stimme über Beat-Grenzen nicht abgehackt klingt.
- **Ablage:** Supabase Storage (Frankfurt), privat.
- **Plan:** bezahlter Plan mit kommerziellen Rechten. Die Kosten sind gering. Grob überschlagen kommen 20 Sequenzen mit vier Welten auf deutlich unter eine Million Zeichen.
- **Kennzeichnung:** In der Mediathek steht dezent „Stimme KI-erzeugt“. Ob das nach Art. 50 AI Act nötig ist, klären wir im Termin mit Jan; schaden tut es nicht.

## 6 · Baustein-Bibliothek

Bausteine sind Remotion-Komponenten mit festen Parametern. Jede rendert in jeder Welt, weil Farben, Einheiten und Gegenstände aus dem Skin kommen.

**Satz für den Soft Launch** (Reihenfolge = Bauvorschlag):

| Baustein | Wofür | Beispiel-Parameter |
|---|---|---|
| Titelkarte | Einstieg | Titel, Untertitel |
| Raster | Flächen, Quadratzahlen, Prozent | Zeilen, Spalten, markierte Zellen, Zählen |
| Term-Zeile | Umformen, Hervorheben, Kürzen | Termfolge, Hervorhebung je Schritt, Durchstreichen |
| Zahlenstrahl | Zahlen, Brüche, Intervalle | Bereich, Marken, Sprünge |
| Bruchstreifen | Brüche, Anteile | Teile, gefärbte Teile, Vergleich |
| Waage | Gleichungen | linke und rechte Seite, Operation je Schritt |
| Koordinatensystem | Funktionen, Steigung | Achsen, Graph, Punkte, Steigungsdreieck |
| Geometrie-Figur | Pythagoras, Kreis, Körper | Figur, Beschriftungen, Hervorhebung |
| Merksatz | Kern festhalten | Text, Formel |
| Endkarte | Übergang in die Aufgabe | Frage, Antwortoptionen (Variante B vom 06.10.: Video schrumpft nach links) |

- **Formeln** werden mit derselben MathJax-Pipeline wie in E1.4 gesetzt, damit Video und Karten gleich aussehen.
- **Neue Bausteine** baut ein Claude-Code-Agent als eigenes Paket, mit Vorschau in allen Welten und Abnahme durch Ashkan.
- **Eine Sonderszene** mit eigenem Code für eine einzelne Sequenz gibt es nur mit Freigabe von Rasit, und sie wird danach zum Baustein.
- **Design:** Brand-Tokens aus `tokens.ts`, keine freien Hex-Werte. Matt statt glühend, ruhige Bewegung, „reduzierte Bewegung“ beachten.
- **Welten zum Start:** Skelett, Fußball, Gaming, Musik (wie im Dummy). Weitere Welten kommen nur dazu, wenn sie ein Skin für alle vorhandenen Bausteine mitbringen.

## 7 · Vorschau und Rendern

**Vorschau im Studio.** Der Remotion Player läuft im Admin-Studio. Er spielt die Beats mit den echten Audiodateien ab, und die Zeitleiste zeigt die Beats als Kapitel. Klickt man auf einen Beat, springt die Vorschau dorthin.

**Rendern per Knopf** (Entscheidung Rasit 27.10.). Das Studio startet einen Server-Render je Welt. Vorschlag: Vercel Sandbox, denn das passt zum bestehenden Vercel-Projekt und braucht kein AWS. Ergebnisse je Welt:
- `<skill>_<welt>.mp4` (H.264, 1920 × 1080)
- `kapitel.json` mit Start jedes Beats in Sekunden und Sprungmarke
- `untertitel.vtt` (aus den Sätzen und Beat-Zeiten)
- Vorschaubild aus dem Titel-Beat

Ablage in Supabase Storage. Jeder Render ist ein Auftrag mit Status (wartet, läuft, fertig, Fehler) und dem Fingerabdruck der Inhalte, aus denen er entstand. Ist der Fingerabdruck veraltet, zeigt das Studio „Render veraltet“.

**Rückfall lokal.** Dieselbe Komposition rendert auch auf Ashkans Mac über einen Befehl im Repo. Der Mac lädt die Daten der Sequenz und lädt das Ergebnis hoch. Das ist die Absicherung, falls Server-Rendern ausfällt oder sich die Lizenzlage ändert (Abschnitt 10).

**In der Schüler-App läuft nur MP4 im normalen Videoplayer**, kein Remotion Player. Das funktioniert in der Web-App und später nativ auf dem iPad gleich, und es löst keine Render-Lizenz aus.

## 8 · Prüfung und Freigabe

Wie im Dummy, Reiter „Freigabe“:
1. **Geschrieben:** Autor und Datum.
2. **Verständlich bestätigt:** ein Gründer außer dem Autor.
3. **Fachlich geprüft:** Lena schaut das Skelett-Video einmal ganz. Bei „passt nicht“ tippt sie den Beat an und schreibt, was nicht stimmt. Die Sequenz geht dann an den Autor zurück, und der Kommentar hängt an diesem Beat.
4. **Varianten-Texte:** Lena liest je Welt nur den Text neben dem Skelett; Zahlen und Animation sind gesperrt. Ins Video schaut sie nur, wo das Bild etwas Mathematisches zeigt. Jede Variante hat eine eigene Freigabe; eine offene Variante blockiert das Skelett nicht.
5. **Stimme vollständig**, **Render aktuell**.

Kann eine Welt nicht freigegeben werden, sieht das Kind dieser Welt die Skelett-Fassung.

## 9 · Ausspielung

**Session (vor Ort).**
- `session_naechster_schritt` liefert wie bisher `art = erklaerung`. `erklaer_start` liefert zur Kernidee zusätzlich das Video der Welt des Kindes und den Beat-Bereich.
- `erklaer_check_abgeben` erkennt das Fehlbild wie bisher. Neu ist die Antwortart `ruecksprung`: Beat, Rückmeldung an das Kind, danach dieselbe Frage mit anderen Zahlen. Gibt es zum Fehlbild keinen Rücksprung, gilt die bestehende Variantenlogik.
- Nach `erklaerrunden_bis_signal` Runden kommt das Signal an den Coach, wie bisher.
- Das Kind kann Untertitel einschalten. Vor Ort braucht jeder Platz Kopfhörer.

**Zuhause.**
- Die Mediathek zeigt alle freigegebenen Videos der offenen Kompetenzen (Themenbaum, Regel „offen“), nur zum Ansehen, ohne Mini-Checks. Das entspricht `erklaer_nachlesen`.
- Gespeichert wird höchstens „angesehen“ (FernUSG).

**Eddie** bekommt die freigegebenen Sequenzen mit ihren Sprungmarken und verlinkt „Sequenz X ab Beat bN“. Eine Sequenz im Entwurf verlinkt er nie.

## 10 · Kosten und Lizenz

| Posten | Bis 3 Personen | Ab 4 Personen |
|---|---|---|
| Remotion, Server-Rendern aus dem Studio (Automators) | 0 € | 0,01 $ pro Render, mindestens 100 $ im Monat |
| Remotion, nur lokal auf Ashkans Mac (Creators) | 0 € | 25 $ pro Sitz und Monat |
| ElevenLabs | bezahlter Plan mit kommerziellen Rechten, kleiner Monatsbetrag | gleich |
| Vercel Sandbox | Rechenzeit je Render, gering | gleich |

**Stand 27.10.:** Ihr seid drei Personen, damit gilt die kostenlose Lizenz (Entscheidung Rasit). Erst ab der vierten Person greift die Firmenlizenz; ein Studio mit Render-Knopf fällt dann unter „Automators“. Der lokale Rückfall auf Ashkans Mac bleibt als günstigere Option im Repo.

## 11 · Abweichungen vom Dummy (21.10.)

- Kein Chat mit Claude im Studio. Stattdessen „Skript einfügen“ mit Prüfung beim Import (Abschnitt 4).
- Je Beat ein Baustein mit Parametern statt einer frei beschriebenen Animation.
- Im Reiter Freigabe kommt der Render-Auftrag mit Status und dem Hinweis „Render veraltet“ dazu.
- Untertitel und Vorschaubild sind neu.

## 12 · Daten (Vorschlag, an E1 anzudocken, in S0 prüfen)

- `studio_sequenz` (id, skill_key, erklaer_kernidee_id oder Bezug zur E1-Sequenz, autor_id, status, stimme_id)
- `studio_beat` (sequenz_id, pos, beat_key, titel, baustein, params jsonb, kernidee_key)
- `studio_beat_text` (beat_id, welt, sprechtext, bild_params jsonb). Fehlt eine Zeile, gilt das Skelett.
- `studio_audio` (fingerabdruck, datei, stimme, modell, dauer_ms, zeitstempel jsonb)
- `studio_minicheck` (sequenz_id, nach_beat, check_task_id aus E1) und `studio_ruecksprung` (minicheck_id, fehlbild_key, beat_key, rueckmeldung)
- `studio_render` (sequenz_id, welt, fingerabdruck, status, mp4, kapitel, untertitel, poster, fertig_am)
- `studio_freigabe` (sequenz_id, art: verstaendlich | fachlich | variante:<welt>, person_id, ergebnis, beat_key, kommentar, at); Prüfung `person_id <> autor_id`
- Kinder lesen nur über Funktionen und nur Freigegebenes (wie E1, RLS).

## 13 · Pakete

| Paket | Inhalt | Abnahme |
|---|---|---|
| S0 | Ist-Analyse: E1-Modell, E2a-Player, Storage, Rollen; Abbildung Video ↔ Kernidee festlegen | Abbildungstabelle, offene Punkte |
| S1 | Datenmodell, Import mit Prüfung, Beat-Editor, Welten-Reiter | Quadratwurzel-Skript importiert, Musik-b3 wird gesperrt |
| S2 | Stimme: Route, Fingerabdruck, Ablage, „fehlende erzeugen“ | unveränderter Satz wird nicht neu vertont |
| S3 | Remotion-Paket, Bausteine Titelkarte, Raster, Term-Zeile, Merksatz, Endkarte; Vorschau im Studio | Quadratwurzeln in allen vier Welten in der Vorschau |
| S4 | Render-Auftrag (Server), Kapitel, Untertitel, Poster; lokaler Rückfall | MP4 und Kapitel stimmen auf 0,1 s mit der Vorschau überein |
| S5 | Prüfung und Freigabe | Autor kann nicht freigeben; Änderung setzt Freigabe zurück |
| S6 | Ausspielung: `erklaer_start` mit Video, `ruecksprung`, Mediathek, Eddie-Index | falsche Antwort 32 springt im Fußball-Video auf b5 |

Danach je Baustein ein kleines Paket, in der Reihenfolge der Themen für den Soft Launch.

## 14 · Abnahmefälle

1. Wenn Ashkan ein Skript mit unbekanntem Baustein einfügt, speichert das Studio nichts und nennt den Beat.
2. Wenn eine Variante „fünfzig“ statt „neunundvierzig“ sagt, ist diese Variante gesperrt. Das Skelett bleibt prüfbar.
3. Wenn Ashkan einen Satz ändert, wird nur dieser Satz neu vertont, und der Render steht auf „veraltet“.
4. Wenn Ashkan seine eigene Sequenz freigeben will, ist der Knopf gesperrt, und die Datenbank lehnt es auch direkt ab.
5. Wenn Lena „passt nicht“ an b4 schreibt, geht die Sequenz an Ashkan zurück, und der Kommentar steht an b4.
6. Wenn ein Kind der Welt Fußball im Mini-Check 32 antwortet, sieht es die Rückmeldung, das Video springt auf b5, danach kommt die Frage mit anderen Zahlen.
7. Wenn die Fußball-Variante nicht freigegeben ist, sieht das Fußball-Kind die Skelett-Fassung.
8. Wenn eine freigegebene Sequenz geändert wird, sehen Kinder bis zur neuen Freigabe die alte Fassung.
9. Zuhause zeigt die Mediathek keine Mini-Checks und speichert höchstens „angesehen“.
10. Eddie verlinkt nie eine Sequenz im Entwurf.

## 15 · Offene Fragen

1. Welche Edvance-Stimme? Vorschlag: Ashkan wählt drei Stimmen und vertont damit b1–b3. Die Gründer entscheiden blind.
2. Welche Welten zum Soft Launch? Gilt der Vorschlag Skelett plus drei Welten, oder startet ihr mit Skelett plus einer Welt und erweitert später?
3. Video und Karten-Erklärung (E1) nebeneinander? Vorschlag: Hat eine Kernidee ein freigegebenes Video, zeigt die Session das Video. „Andere Erklärung“ bleibt als Karte.
4. Ist Lenas Zeit für die Prüfung der Videos eingeplant (etwa 10 Minuten je Skill)?

## Anhang A · Import-Format

```json
{
  "skill_key": "wurzel_bedeutung",
  "titel": "Was die Wurzel bedeutet",
  "welten": ["skelett", "fussball", "gaming", "musik"],
  "beats": [
    {
      "id": "b2",
      "titel": "Ein Quadrat aus Kästchen",
      "kernidee": "k1",
      "baustein": "raster",
      "params": { "zeilen": 7, "spalten": 7, "aufbauen": true },
      "text": {
        "skelett": "Stell dir ein Quadrat aus neunundvierzig kleinen Kästchen vor.",
        "fussball": "Stell dir ein quadratisches Trainingsfeld aus neunundvierzig Kunstrasenplatten vor."
      },
      "bild": { "fussball": { "einheit": "Platten" } }
    }
  ],
  "minichecks": [
    {
      "nach_beat": "b7",
      "frage": { "skelett": "Ein Quadrat hat eine Fläche von 64 Kästchen. Wie viele Kästchen lang ist eine Seite?" },
      "optionen": [
        { "antwort": "8", "richtig": true, "rueckmeldung": "Genau. 8 · 8 = 64." },
        { "antwort": "32", "fehlbild": "haelfte_statt_wurzel", "ruecksprung": "b5",
          "rueckmeldung": "32 ist die Hälfte von 64. Zähl, wie viele nebeneinander liegen." }
      ]
    }
  ]
}
```
