# SP-1 · Abnahme (S5)

Stand 12.11.2026, origin/dev nach #397. Belege:
- **pgTAP** `supabase/tests/sp1_bauform_kommentare.test.sql`, 67/67 in einer Wegwerf-DB aus allen 423 Migrationen
  (Nummern unten = Zusicherung), CI `neuaufbau` grün.
- **Ansichtstests** `e2e-sessionpruefung/*.spec.ts` (34/34, je 1180 × 820 und 1440 × 900) gegen die Vorschau mit
  Prod-Fixtures (`tools/sp1-vorschau-daten.sh`, read-only); Fotos in `abnahme/`.
- **Ablauf-Probe** `rueckfragen-ablauf.md` §4 in der Wegwerf-DB (Ausgabe unten), **dbread** gegen Prod.

| Fall | Beleg | Ergebnis |
|---|---|---|
| a) EIN-1 ohne Klick „Passt“ → zur Freigabe, nächste Bauform öffnet sich | pgTAP 4–6; Ansicht `abnahme.spec.ts` a (öffnet „Punkt im Koordinatensystem ablesen“), Foto `abnahme-a-*` | ✓ |
| b) Kommentar an Beispiel 3, „Rechnung falsch“ → „Rückfrage senden (1 Kommentar)“, danach Rückfrage, Kommentar mit Instanz | Ansicht b, Foto `abnahme-b-*`; pgTAP 15, 17–20 | ✓ |
| c) Kommentar ohne Grund und Text: Senden gesperrt | Ansicht c (gesperrt, Tooltip, Satz), Foto `abnahme-c-*`; pgTAP 7 (Server lehnt ab) | ✓ |
| d) „Andere Beispiele“ lässt das kommentierte Beispiel stehen | Ansicht d; pgTAP 60 (`p_behalten`) | ✓ |
| e) Zeit Stufe 3 von 1 auf 1,5: gespeichert, Version unverändert, Session-Planung nutzt den neuen Wert | pgTAP 27–29 (`aufgabe_zeit_sek` = 90 s), 21–23, 30–32; Ablauf-Probe `zeit Stufe 3: 1.5` | **teilweise:** gespeichert und je Aufgabe lesbar; die Session-Planung liest heute keine Aufgabenzeit (`offen.md` O1) |
| f) Rückfrage erledigt mit Notizen, Prüfmaschine grün, Blindlöser bestanden → zur Freigabe, nicht unter „Zu prüfen“; Admin sieht Kommentare und Notizen | pgTAP 40–42, 47–49, 52–53; Ablauf-Probe; Vitest `BauformDetailPage.test.tsx` „Admin sieht die letzte Rückfrage“ | ✓ |
| g) dasselbe mit einer fehlenden Notiz: kein Wechsel | pgTAP 43–46; Ablauf-Probe `eine Notiz fehlt: rueckfrage` | ✓ |
| h) Lena sieht keine Freigabe-Knöpfe und kann nichts auf ready setzen | Ansicht h, `liste.spec.ts`; pgTAP 33–39 | ✓ |
| i) kein Schlüssel im sichtbaren Text außer dem Kürzel (Liste und Prüfansicht) | Ansicht i (Liste + EIN-1, KO-1, PAR-2, PAR-3, NP-2), Vitest Liste/Prüfansicht | ✓ — „{“ wird als Platzhalter `{name}` gesucht: „L = {0; 18}“ ist Mathematik der Lösungsmenge, kein Schlüssel |
| j) `aufgabe_ziehen` und die Sammelfreigabe unverändert | Funktionskörper in `schema-erwartet.sql` vor SP-1 (`77098887`) und nach #397 byte-gleich: `aufgabe_ziehen`, `aufgabe_zwilling`, `aufgabe_werten`, `aufgabe_payload`, `task_status_set`, `bauform_freigeben`, `bauform_pruefen` | ✓ |
| k) PAR-2 und PAR-3: Achsen, Gitter, Achsenzahlen jeder Option lesbar wie im Player; KO-1 unverändert | `pruefansicht.spec.ts` (Untergrund nicht weiß); Fotos `k-PAR-2-optionen-vorschau-*` neben `k-PAR-2-optionen-player-*` (Player: edvance-app `/aufgaben/vorschau` mit denselben PAR-2-Bildern), `s4-PAR-3-*-beispiele.png`, `s4-KO-1-*` | ✓ |

## Ablauf-Probe (Wegwerf-DB, `rueckfragen-ablauf.md` §4)

Lena (lokales Profil mit Prüfrecht) sendet zu EIN-1 eine Rückfrage mit zwei Kommentaren (Beispiel Stufe 3 „Rechnung
falsch“ mit Text; Stufen „Zahlen anders wählen“) und Zeit Stufe 3 → 1,5. `tools/bauform-rueckfragen.sh` (mit
`DBREAD` auf die Wegwerf-DB) schreibt `rueckfragen/EIN-1.md` mit beiden Kommentaren, Instanz, Lösung und Lösungsweg.
Danach wie eine Export-Migration:

```
nach Export: rueckfrage v2
g) eine Notiz fehlt: rueckfrage
f) erledigt: zur_freigabe
f) zu pruefen: 0
e) zeit Stufe 3: 1.5, Aenderungen: 1
```

## Prod nach dem Auftrag (dbread)

```
bauformen: 47, alle zur_pruefung, titel 47 (verschieden), version 1
bauform_stufen: 112, davon 100 mit Klartext; bauform_kommentare 0; bauform_pruefungen 0
has_function_privilege(authenticated, bauform_pruefen) = f
```
