# Offene Punkte — Admin-Prüfansicht

Abweichungen zwischen Auftrag, Anforderung und Code. Nichts davon ist still umgangen.
Rangfolge bei Widersprüchen: Bauauftrag, dann Dummy, dann Anforderung.

## OP-1 · RPC-Bindung war schon behoben (P0)

Der Auftrag sieht einen ersten Commit „fix: supabase.rpc-Bindung“ vor, falls `const rpc = supabase.rpc as unknown …`
noch vorkommt. dev steht auf 7083abf (#211); alle Fundstellen binden bereits, ein Vitest prüft `this`
(`ist-analyse.md` Abschnitt 1). Kein eigener Commit.

## OP-2 · Wege für Freigeben, Zurückweisen, Freigabe zurücknehmen (Auftrag vor Anforderung)

Die Anforderung nennt `task_status_set(…, 'ready')` (C 17), `lena_beanstande` (C 19) und `task_status_set(…, 'draft')`
(C 20). Der Auftrag legt eigene, protokollierende Funktionen fest: `pruef_admin_freigeben` (G4),
`pruef_admin_zurueckweisen` (G5), `pruef_freigabe_zuruecknehmen` (G4). Umgesetzt ist der Auftrag; die Wirkung
(Status, Stempel, `task_reviews`) ist dieselbe, dazu kommt die Zeile im Admin-Protokoll.

## OP-3 · Vorbefüllt-Kennzeichen (offene Frage 5)

„bestätigt“ setzt nicht nur die Strecke, sondern auch der Editor (`patchFuerSpeichern` ohne `baseline`,
`bestaetigeLoesungsKennzeichen`; `ist-analyse.md` Abschnitt 4). `VorbefuelltContext` und das Feld bleiben deshalb
unverändert. Nach dem Entfernen der Strecke hat nur der `baseline`-Zweig von `patchFuerSpeichern`
(`editorState.ts:291–305`) keinen Aufrufer mehr; er bleibt stehen (getestet, harmlos).
Änderungen in der Prüfkarte (`pruef_speichern`) bestätigen keine Kennzeichen — wie bei Lena.
Frage an Rasit: Soll ein Admin-Speichern in der Prüfkarte die Kennzeichen der geänderten Felder bestätigen?

## OP-4 · Fertigkeit/AFB bei freigegebenen Aufgaben (offene Frage 4)

Umgesetzt wie vorgeschlagen: `pruef_sammel` lässt freigegebene Aufgaben mit dem Grund `freigegeben` aus. Die Freigabe
wird nicht automatisch zurückgenommen.

## OP-5 · Gate-Befunde im Frontend

`freigabe_gate_fehler` ist für Clients nicht freigegeben. Der Kasten „Vor der Freigabe klären“ zeigt deshalb die
blockierenden Flags aus `computeFlags`, deren Regeln das Gate spiegeln (`flags.ts:1–9`). Der Server prüft beim
Freigeben trotzdem das Gate (`task_status_set`); den Gate-Text liefert die Vorschau von `pruef_sammel` (Grund `befund`).

## OP-6 · Admin-Zweig nur fürs Bearbeiten, nicht für Lenas Entscheidung

`pruef_sperren` ist der gemeinsame Baustein aller schreibenden Lena-Funktionen. Der Admin-Zweig (G1) gilt fürs
Speichern; `pruef_entscheiden` und `pruef_rueckgaengig` behalten Lenas Sperren (Pilot, Hand, Team) auch für admin
(`pruef_lena_sperren`, Consensus-Check W1). Sonst hätte ein Admin über Lenas „Passt“ an „erst an Lena“ vorbei
freigeben können. Admins entscheiden über ihre eigene Leiste.

## OP-7 · beanstandeAufgabe ohne Aufrufer

`beanstandeAufgabe` und `BEANSTANDUNGS_KATEGORIEN` (`src/lib/supabase/freigabe.ts`) nutzte nur die Strecke. Sie
liegen in `src/lib/` und bleiben (Auftrag F: nichts löschen, was nicht unter `wizard/` liegt).

## OP-8 · Frühere Team-Beanstandung sperrt die Sammelfreigabe dauerhaft (Consensus-Check G-a)

`pruef_sammel('freigeben')` lässt eine Aufgabe mit „vom Team beanstandet“ aus, sobald es je eine Admin-Zeile in
`task_reviews` gab — auch nach „Zurück an Lena“ und einem neuen „Passt“ von Lena. Das ist genau die Regel von
`pruef_freigabe_erlaubt`/`freigabe_thema` (Lena-Board OP-9, Auftrag G7). Einzeln lässt sie sich freigeben.
Frage an Rasit: Sollen nur Beanstandungen nach dem letzten „Zurück an Lena“ zählen?

## OP-9 · „Zurück an Lena“ einzeln und gesammelt bei Ausschluss (Consensus-Check G-d)

Einzeln setzt `pruef_an_lena` jede Aufgabe außer `ready` auf Offen — bei Ausschluss heißt der Knopf „Auf Offen
setzen“ (Auftrag C 8). Gesammelt lässt `pruef_sammel('an_lena')` Aufgaben mit Ausschluss als „nicht bei Lena“ aus
(Auftrag G7). Bewusst so.

## OP-10 · Zurückweisen im Protokoll ohne Gründe (Consensus-Check H1)

`task_admin_protokoll.grund` hält bei `zurueckweisen` die Notiz („Was genau?“). Die Gründe stehen je Zeile in
`task_reviews` und erscheinen in „Lenas Ergebnis“ als Team-Beanstandung, im Verlauf aber nicht.

## OP-11 · Freigabe zurücknehmen behält die Ausgangsfassung (Consensus-Check H3)

`pruef_freigabe_zuruecknehmen` läuft über `task_status_set(…, 'draft')`, das die Ausgangsfassung nur aus
review/rueckfrage/beanstandet löscht. Öffnet Lena die Aufgabe danach, sieht sie Änderungen des Teams seit ihrer
Ausgangsfassung als „geändert“. Wer das nicht will, schickt die Aufgabe danach „Zurück an Lena“.

## OP-12 · Details von pruef_sammel

- **Grund bei „Aus Lenas Liste nehmen“:** Pflicht nur beim Ausführen (ED422 `grund_fehlt`); die Vorschau zeigt
  schon vorher, was die Aktion trifft (Dummy: Dialog mit Vorschau und Grundfeld).
- **Zusätzliche Gründe:** `ausgeschlossen` (Fertigkeit/AFB bei VERA-8, inaktiv, Typ — wie `pruef_sperren` für
  admin; nur im Editor), `nicht_gefunden`, `fehler` (Fehler beim Schreiben; ED422 bringt den HINT als Grund).
- **Pilot aus** lässt Aufgaben mit Ausschluss nicht aus (Dummy `pilotAus`); nur „Pilot an“ prüft „nicht bei Lena“.
- **Protokoll-Grund bei „Zurück an Lena“:** `p_werte.grund`, sonst die Nachricht an Lena.
- **Pilot einzeln** aus der Prüfansicht läuft über `pruef_sammel` mit einer ID und steht deshalb mit
  `sammel = true` im Protokoll (Auftrag G7).

## OP-13 · Schema-Abzug

`supabase/schema-erwartet.sql`, `schema.sql` und `schema_content.sql` sind nicht angefasst (Auftrag). Der CI-Job
„schema“ endet beim Schemavergleich, bis Rasit eingespielt und `tools/schema-snapshot.sh` gelaufen ist.
`src/types/database.ts` ist nicht neu generiert (Anforderung Daten 5); die Wrapper casten wie `pruefung.ts`.
