# Offene Punkte LSA-V (Auswahl mit Grund)

Stand 22.10.2026, Branch feat/rasit-lsa-vorschau, Migration 20261022065539_lsa_v_vorschau.

## Für die Gründer

1. **Erwartung 17.4 nicht erreichbar mit den Entscheidungen 10 und 14.** Thema vertiefen nimmt nur Knoten
   „ohne Urteil in dieser Sitzung“. Bei Testkonto B sind die 9 nicht direkt geprüften Bereiche des Themenraums
   aber mitbelegt (lsa_mitbelegung schreibt `traegt`, `belegt_direkt = false`, sobald ein Knoten darüber
   trägt), haben also ein Urteil. Die Simulation zeigt deshalb vorher wie nachher 5 von 14 direkt geprüft.
   Selbst wenn die Auswahl einen mitbelegten Knoten zöge, bliebe das Urteil abgeleitet:
   lsa_urteil_buchen_core überschreibt ein finales Urteil nie (Wertung, Entscheidung 14).
   Vorschlag, wenn 17.4 gelten soll (eigener Auftrag, betrifft die Wertung): Thema vertiefen nimmt auch
   mitbelegte Knoten ohne eigene Antwort, und eine direkte Probe ersetzt ein mitbelegtes Urteil.
   Der Test sichert heute nur „nicht weniger als vorher“ zu.
2. **Die Vorschau reicht bei Testkonto B nur für das erste Plan-Thema.** Von 10:00 bis 15:00 kommen fünf Aufgaben
   (term_einsetzen, gleichung_modellieren, term_binom_quadrat zweimal, geo_koordinaten), dann ist Minute 16
   erreicht. Der Rand von „Kreise, Prismen und Zylinder“ (Flächen, Umfang, Größen, Potenzen, Proportionalität,
   Runden) kommt nicht dran. Das gehört zur offenen Frage „Reichen 4 Minuten, oder bis 17?“.
3. **Kurze LSA für echte Kinder.** Mit dem Pool eines echten Kindes (nur `ready`) endet dieselbe Sitzung nach
   7 Aufgaben bei Minute 7:30 (vorher 8 Aufgaben, die achte aus Breite b). Von den 24 Vorschau-Kandidaten
   haben nur 5 genug Freigaben (docs/lsa/freigabeliste-vorschau.md). c_vorschau_themen = 3 hilft
   hier nicht, solange die Aufgaben fehlen.
4. **Rückblick nach Minute 16 bleibt ohne Bezug zum Thema.** Bei Testkonto B zieht er wie vorher Thales und
   Gleichungssysteme (Entscheidung 2c: Breite a unverändert). Ob der Rückblick dieselbe Begründung braucht wie
   die Vorschau, entscheidet R7-12 bzw. ein Folgeauftrag.

4b. **Randknoten über der Klassengrenze fallen ersatzlos weg** (Zweitprüfung). Ersetzt durch den eigenen Rand
   wird nur, was zu einem Thema gehört, das laut Plan noch kommt (Rest der Klasse, Klasse + 1). Ein Randknoten
   mit klasse_herkunft > Klasse aus einem Thema, das nicht im Plan steht, wird nur verworfen; seine
   Voraussetzungen kommen nicht dran. Testkonto B ist nicht betroffen. Gemessen über alle Plan-Positionen der lokalen
   DB: Klasse 5 hat 99 solche Knoten an 94 Positionen (z. B. potenzen, groessen_flaechen), Klasse 6/7 je 2–4.
   Vorschlag: auch über Knoten mit klasse_herkunft > Klasse in ihren Rand absteigen. Wortlaut von Entscheidung 7
   ist heute erfüllt.

## Auslegungen, die ich getroffen habe (bitte bestätigen)

5. **Ohne Plan, Klasse 6, 8, 10:** Entscheidung 6 sagt „themen mit diesem Fach und dieser Klasse“. themen.klasse
   steht aber je Stufe auf dem ersten Jahr (Klasse 9 für 9/10), ein Kind der Klasse 10 fände also nichts.
   Umgesetzt wie klpPlan in plan.ts (R7-9, Nachbesserung zu Entscheidung 7): die Themen der Stufe mit
   klasse ≥ Klasse des Kindes, sonst die ganze Stufe, nach sort. Für Klasse 9 ist das dasselbe wie der Wortlaut.
   „Später nach Kernlehrplan“ (für die Ersetzung durch den Rand) = alle Themen mit größerem sort.
6. **Kandidat ohne freie Aufgabe (7 und 9):** Die Kandidatenliste nimmt nur Knoten mit freier Aufgabe
   (Entscheidung 7). Das Urteil `ungeprueft` aus Entscheidung 9 bleibt als Sicherung, greift damit aber nur,
   wenn zwischen Kandidat und Aufgabe etwas verschwindet. Folge: Ein Randknoten ohne Aufgaben öffnet keinen
   Abstieg in seinen Abschluss.
7. **Schule:** lsa_schule_von_sitzung geht wie R7-9 über students.lead_id, nicht über
   leads.converted_student_id. Breite a fand die Schule bisher über lsa_lead_von_schueler (beide Wege). Für
   ein konvertiertes Kind ohne students.schule_id fehlt der Plan jetzt, wie im Report. vertrag_abschliessen und
   vertrag_starten schreiben school_name; ob sie auch schule_id setzen, habe ich nicht geprüft.
8. **Mehrfach-Randknoten:** „gehört zu mehreren kommenden Themen“ zählt nach dem Rand (auch nach Ersetzung),
   nicht nach skill_thema. Tiefere Knoten zählen nie als mehrfach; ihr Rang ist der kleinste ihrer Randknoten.

## Technisch

9. **CI schema/neuaufbau** ist bis zum Snapshot rot: Die Funktion und lsa_schule_von_sitzung weichen von
   supabase/schema-erwartet.sql ab. Laut Auftrag macht Rasit `tools/schema-snapshot.sh` nach dem Einspielen.
10. **Simulation mit Daten aus Prod** (supabase/tests/lsa_v_daten.sql, tools/lsa-v-abzug.sh): FWG-Plan,
    Aufgabenbestand je Skill, Zustände von Testkonto B, Themen seines Leads. Freigegeben von Rasit (22.10.2026):
    Skill-Schlüssel, Zustände, Themen, Plan; keine Namen, Antworttexte, Zeitstempel, Lead- oder Schüler-IDs.
    Ändert sich der Bestand in Prod, zeigt ein neuer Abzug die neue Lage; die Zusicherungen gelten dann neu.
11. Die Simulation bucht Multi-Part- und Term-Aufgaben als NUMERIC. Für die Auswahl zählt nur Skill, MC ja/nein
    und Sondierrang; die Wertung einer freien Eingabe ist für richtig/falsch/„weiß nicht“ gleich.
12. **Datum fürs Halbjahr:** Die LSA nimmt während der Sitzung started_at, der Report completed_at. Abweichung nur,
    wenn eine Sitzung über den Halbjahreswechsel (31.01./01.02., 31.07./01.08., Berlin) läuft.
13. Der Report (Lernweg „Kommt noch“) und die Vorschau nutzen dieselbe Positionsregel, aber zwei Umsetzungen
    (TypeScript und SQL). Eine gemeinsame Prüfung (gleiche Fälle in plan.test.ts und lsa_v_vorschau) wäre
    ein kleiner Folgeauftrag.
14. **LSA-D Fix C** (freigabe_gate_fehler/pruef_ausschluss billiger) ist nicht Teil dieses Pakets. Nach A/B prüft
    die Auswahl lsa_im_pool nur noch bis zum ersten Treffer je Kandidat; v_mit_thema (Einstiege des Themas)
    prüft weiter alle Einstiegsaufgaben, das sind wenige.
15. Die Messung lief auf dem Neuaufbau mit synthetischen Aufgaben, nicht mit dem Inhaltsabzug aus Prod wie in #297
    (vom Auto-Modus angehalten, Personendaten). Ein Vergleich mit den Zahlen aus #297 ist nur der Größenordnung nach
    möglich; den echten Wert zeigt pg_stat_statements (platz_submit) nach dem Einspielen.
