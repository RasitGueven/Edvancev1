# Offene Punkte — V5 Pilotvereinbarung (14.10.2026)

Stand: PR offen, Migration `20261014110412_vertrag_pilot.sql` noch nicht eingespielt.

## Für Tolunay (Recht)

1. **Text der Pilotvereinbarung.** `src/pages/admin/vertraege/dokumente/de/pilotvereinbarung.md` ist ein Platzhalter mit
   PLATZHALTER-Hinweis: Parteien, Kind, Zeitraum, Einheiten à 60 Minuten, „ohne Entgelt“, 10-Uhr-Regel,
   Datenschutz-Verweis. Wenn der echte Text kommt, die Fassung in `dokumente/index.ts` hochzählen, als neue Zeile in
   `vertrag_dokumente` eintragen (Migration) und `node tools/dokumente-buendeln.mjs` laufen lassen.
2. **AGB beim Pilot?** Zum Bündel eines Pilots gehören nur Pilotvereinbarung, Datenschutzhinweise und die freiwillige
   Foto-Einwilligung. Die AGB sind bewusst nicht dabei, weil sie Beitrag, Zahlung und Kündigung regeln. Wenn sie dazu
   sollen: `vertrag_dokumente.vertragsarten` der AGB um `'pilot'` ergänzen (Migration) und `NUR_REGULAER` im Bündler
   anpassen.
3. **10-Uhr-Regel im regulären Vertrag.** Der Auftrag sagt „wie im regulären Vertrag“. In `vertrag.md` steht die Regel
   aber noch nicht, dort ist „Ausfallregelungen“ nur angekündigt. In die Pilotvorlage kam deshalb der Wortlaut aus der
   App (`admin.json`): „Bis 10 Uhr am Session-Tag gilt eine Absage als rechtzeitig, danach verbraucht sie die Einheit.“
4. **Mailtexte an Eltern** (`vertraege.json → mail.*Pilot*`): eigene Fassungen für Bestätigung und Unterlagen, ohne
   Widerruf und ohne SEPA. Bitte sprachlich gegenlesen.

## Für Batu (erster Fall)

5. **Der Lead muss auf „Analyse abgeschlossen“ stehen.** `vertrag_starten` verlangt `leads.status = 'lsa_fertig'`.
   Batus Leads stehen in Prod auf `rejected` (Stand 14.10., read-only geprüft). Das gehört vermutlich in den
   parallelen Batu-Tab (Altleads). V5 ändert diese Regel nicht.
6. **Vorschlag für Beginn 01.11.2026:** Ende Fr 16.07.2027, 34 Einheiten. Gezählt werden die Wochen ab 02.11.2026 mit
   mindestens einem Schultag, ohne die volle Weihnachtswoche und die beiden Osterwochen. Beides ist im Formular
   änderbar.

## Fachlich zu entscheiden

7. **Feiertage.** Der Vorschlag kennt nur die Ferien aus `ferien_nrw`. Gesetzliche Feiertage und bewegliche Ferientage
   kennt er nicht. Eine Woche mit einem Schultag zählt voll, auch eine Teilwoche wie der 21./22.12.
8. **Das Ende wird erst beim Versand bzw. Abschluss geprüft** (nicht in den Ferien, nicht nach dem letzten gepflegten
   Ferientag). Das Formular speichert ein Ende in den Ferien noch; die Meldung kommt dann aus der RPC.
9. **Rückfrage: Zählt ein Pilot als „laufender Vertrag“?** Gebaut ist: nein. `summen()` lässt Pilots aus allen drei
   Zahlen weg (laufend, im Widerruf, Abbuchung), also auch aus der Kachel „Verträge“ auf „Heute“. Entscheidung 8 nennt
   nur Umsatz-, Beitrags- und Founders-Kennzahlen. Sollen Pilots als laufende Verträge mitzählen, reicht ein Filter
   allein auf `abbuchungCents` (`src/lib/vertrag/menue.ts`).
   **Reiter-Zähler im Vertragsmenü.** Der Zähler am Reiter „Übersicht“ zählt Pilotverträge mit, weil sie in der Liste
   stehen (mit Kennzeichen). Die Kennzahlen „laufende Verträge“, „im Widerruf“ und „Abbuchung“ sowie der Verzug
   zählen sie nicht. „Auslaufend“ zeigt einen Pilot bewusst, denn von dort startet der Folgevertrag.
10. **„Aktive Schüler“ auf „Heute“** (`adminStats`, zählt aktive Akten) zählt ein Pilotkind mit. Das ist keine Umsatz-
    oder Beitragskennzahl und blieb deshalb unverändert.
11. **Kennzeichen in der Schülerakte nur für Admins.** Es kommt aus `slots_kind`, das Coaches nicht aufrufen
    (Anforderung I 54). Erscheint, sobald ein laufender Vertrag eine Planbilanz hat. Coach-Board und Coach-Akte zeigen
    keins.
12. **Folgevertrag aus einem Pilot** übernimmt keine Bankdaten (es gibt keine). Paket, Laufzeit, IBAN und
    Kontoinhaber trägt der Admin im Folgevertrag ein.
13. **Bankdaten beim Pilot.** Das Formular speichert beim Pilot keine IBAN und verwirft eine eingetippte beim Wechsel
    der Vertragsart. Hat der Vertrag schon Bankdaten, etwa als Folgevertrag eines regulären Vertrags oder weil die IBAN
    vor dem Wechsel gespeichert wurde, löschen `vertrag_versenden` und `vertrag_abschliessen` sie beim Pilot und leeren
    `iban_masked` und `kontoinhaber`. In der Vorbereitung bleiben sie bis dahin stehen, sind aber nirgends sichtbar.
14. **Abschluss nach dem Ende.** `vertrag_pilot_pruefen` lehnt ein Ende in der Vergangenheit nicht ab. Ein verspäteter
    Abschluss ergibt `vertrag_status = 'aktiv'`, `wirksamer_status` ist aber sofort `ausgelaufen`.
15. **Papierweg.** Als Abweichung zählt beim Pilot nur der Beginn. Ändern die Eltern Ende oder Einheiten auf dem
    Papier, lässt sich das nur über einen Vermerk und eine neue Vorbereitung abbilden.
16. **Mandatsreferenz.** Sie entsteht wie bisher per Default und wird beim Pilot nirgends gezeigt: nicht im Kopf von
    Assistent und Detail, nicht im Partnerblock, nicht im Titel der Unterlagen, nicht in der PDF-Fußzeile. Das
    Formular blendet beim Pilot den ganzen SEPA-Block aus. Die Detailseite zeigt beim Pilot weder „Widerruf möglich
    bis“ noch „Zahlung“ noch den Knopf „Widerruf erfassen“.

## Technisch

17. **Dateigrößen.** `VertragPage.tsx` stand vorher bei 435 Zeilen und steht jetzt bei 426: Die Ende-Vorschau ging in
    `useVertragsende.ts`, Section/Feld nach `FormTeile.tsx`. `src/types/slotplan.ts` lag schon über 400 (448 → 452).
    `vertrag_pdf_erzeugen.ts` schrumpfte durch das Auslagern von `vertrag_buendel.ts` von 428 auf 362.
    `VertragDetailPage.tsx` steht bei 389, der Partnerblock ist ausgelagert.
18. **Deno-Tests** (`supabase/functions/_shared/vertrag_pdf_test.ts`, 13 grün) laufen lokal per `npx deno`, nicht in
    der CI.
19. **Edge Functions neu deployen** nach dem Einspielen: `vertrag_pdf`, `mail_senden`, `vertrag_abschluss` (geteilter
    Code in `_shared/`).
