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

## OP-6 · Admin-Zweig in pruef_sperren wirkt auch auf pruef_entscheiden und pruef_rueckgaengig

`pruef_sperren` ist der gemeinsame Baustein aller schreibenden Lena-Funktionen. Mit G1 kann ein Admin auch über
Lenas Ansicht (`/coach/pruefen/:id`) außerhalb des Piloten oder bei Team-Beanstandung entscheiden — die Oberfläche
macht die Karte bei Team-Beanstandung weiter nur lesbar (`PruefansichtPage.tsx:62–63`). Lena ist unverändert (pgTAP).

## OP-7 · beanstandeAufgabe ohne Aufrufer

`beanstandeAufgabe` und `BEANSTANDUNGS_KATEGORIEN` (`src/lib/supabase/freigabe.ts`) nutzte nur die Strecke. Sie
liegen in `src/lib/` und bleiben (Auftrag F: nichts löschen, was nicht unter `wizard/` liegt).
