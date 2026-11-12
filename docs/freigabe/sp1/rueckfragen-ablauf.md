# SP-1 · Rückfragen zu Bauformen abarbeiten

Lena schickt eine Rückfrage, wenn sie an einer Bauform etwas kommentiert. Die Bauform steht dann auf „Rückfrage“ und
wird überarbeitet. Sie geht **ohne zweite Prüfung durch Lena** auf „zur Freigabe“, sobald
(a) jeder Kommentar mit einer kurzen Notiz erledigt ist, (b) die Prüfmaschine für die neue Version grün ist und
(c) der Blindlöser bestanden ist. Das prüft die Datenbank selbst (Trigger `bauform_rueckfrage_automatisch`,
Funktion `bauform_rueckfrage_erledigt`); die Reihenfolge der Schritte ist egal.

## 1 · Rückfragen holen

```bash
bash tools/bauform-rueckfragen.sh        # nur lesend (dbread) → docs/freigabe/sp1/rueckfragen/<KEY>.md
```

Je Bauform eine Datei mit jedem Kommentar: Ort (Grundgerüst, Stufen, Typische Fehler, Beispiel), Gründe, Text, bei
Beispielen die Instanz mit Aufgabentext, Lösung, Parametern und Lösungsweg, dazu die Kommentar-ID.

## 2 · Bauform anpassen

- Generator `scripts/bauformen/bauformen/<key>.py` ändern (Text, Stufen, Fehlbilder, Hinweise, Lösungsweg, Zahlenwahl).
- Betrifft der Kommentar nur Klartext (Stufen-Beschreibung, Titel) oder die Zeit: kein Generator, sondern eine
  Datenmigration auf `bauform_stufen` bzw. `bauformen.titel` (Klartext ändert die Version nicht).
- Vorher per dbread prüfen, dass die Bauform noch auf `rueckfrage` steht (nicht pausiert, `offen.md` O3).

## 3 · Prüfmaschine und Blindlöser

```bash
bash tools/bauform.sh <KEY>                       # erzeugen, Prüfmaschine, Blindlöser-Texte
bash tools/bauform.sh <KEY> --blind <antworten>   # Blindlöser auswerten, Migration schreiben
```

**Der Agent, der die Bauform angepasst hat, löst nicht selbst.** Den Blindlöser startet der Orchestrator als frischen
Subagenten ohne Kontext (Ablauf wie `docs/reihe1/A/blindloeser.md`). Ist die Prüfmaschine über 30 % rot oder der
Blindlöser durchgefallen, bleibt die Bauform in Überarbeitung; Lena sieht sie nicht.

## 4 · Erledigt-Notizen in derselben Datenmigration

Ans Ende der von `tools/bauform.sh` erzeugten Migration (nach dem Export-Block) je Kommentar eine Zeile mit kurzer
Notiz, was geändert wurde, und zum Schluss die Bestätigung:

```sql
-- SP-1 Rückfrage <KEY>: Kommentare erledigt (Notiz: was wurde geändert). Systemaufruf transaktionslokal, sonst gilt
-- die Migration in der CI-Grundlage als anon (Muster „Upsert in Migration braucht Systemrolle“).
select set_config('request.jwt.claims', '{"role": "service_role"}', true);
select public.bauform_kommentar_erledigen(k.id, 'Rechnung in Stufe 3 korrigiert: (a·x)² statt a·x² im Lösungsweg')
  from public.bauform_kommentare k
 where k.id = '<kommentar-id>' and k.status = 'offen';
-- … je Kommentar eine Zeile …
select public.bauform_rueckfrage_erledigt(b.id, b.version)
  from public.bauformen b
 where b.schluessel = '<KEY>' and b.status = 'rueckfrage';
```

- Die `where`-Bedingungen machen die Migration auf einer leeren Datenbank (CI-Neuaufbau) zu einem leeren Schritt.
- `bauform_rueckfrage_erledigt` wirft mit Grund (`kommentar_offen`, `pruefmaschine`, `blindloeser`, `version`), wenn
  etwas fehlt; dann bricht die Migration ab und nichts ist eingespielt.
- Ist der automatische Übergang schon passiert, liefert der Aufruf einfach `zur_freigabe`.

## 5 · Einspielen und prüfen

Wie jede Migration (CLAUDE.md §10). Danach per dbread:

```sql
select b.schluessel, b.version, b.status,
       count(*) filter (where k.status = 'offen') as offen, count(*) as kommentare
  from bauformen b join bauform_kommentare k on k.bauform_id = b.id
 where b.schluessel = '<KEY>' group by 1, 2, 3;      -- → zur_freigabe, offen 0
```

Die Bauform erscheint in der Liste unter „Zur Freigabe“, nicht unter „Zu prüfen“. Ein Admin sieht in der Prüfansicht
die Kommentare mit Notizen und gibt über die Sammelfreigabe frei.
