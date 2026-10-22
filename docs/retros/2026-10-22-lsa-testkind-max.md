# Retro 22.10.2026 · LSA-T2 Sechstes Testkind „Max“ und Schalter `nur`

## Gebaut

- `tools/lsa-testkinder/erzeugen.sql`: Max Hoffmann (Klasse 8, Gymnasium, FWG, Lineare Funktionen), der
  jede Aufgabe kanonisch richtig beantwortet: grund überall `sicher`, keine Ausnahmen. Dieselbe Antwort-
  erzeugung wie bei „sicher“ aus LSA-T, nichts Neues an der Wertung.
- Meldung „richtig beantwortet, nicht angenommen“: nach jeder ganz richtigen Abgabe prüft das Skript
  `lsa_responses.correct`; ist ein Teil nicht true, eine NOTICE (task_id, skill_key, input_type, Antwort,
  ohne Name), kein Abbruch. Für Max am Ende die Liste als eigene Ausgabe.
- Schalter `-v nur=Max[,Lina]`: filtert `lsat.kinder` vor dem ersten Schreiben; unbekannter Name →
  Ausnahme mit Liste der bekannten Namen. Alle späteren Blöcke und die Tabelle lesen nur die gefilterte Liste.
- Test: 44 Zusicherungen (vorher 33), lokal im Neuaufbau grün.

## Entscheidungen

- **FWG für Max:** Prod hat einen Schulplan Klasse 8 am FWG (6 Vorhaben, darunter `lineare_funktionen`),
  geprüft per dbread. Behandelt wie bei Sophie (rationale_zahlen, zuordnungen, terme_gleichungen); alle drei
  stehen im FWG-Plan Klasse 7, deshalb `quelle_behandelt = schulplan`.
- **„nicht angenommen“** = mindestens eine Zeile der Abgabe in `lsa_responses` mit `correct` nicht true. Das
  Urteil liest genau diese Spalte (`lsa_urteil_buchen_core`).
- **Abbruch bei unbekanntem Namen testbar:** `\set ON_ERROR_STOP on` steht jetzt nach der Namensprüfung, der
  Rest des Skripts hinter `\if :ERROR … \else … \endif`. So kann der Test den Abbruch in einem Savepoint
  prüfen (`LAST_ERROR_MESSAGE`), und ohne `-v ON_ERROR_STOP=1` läuft nach der Meldung trotzdem nichts weiter.
- Skript auf genau 400 Zeilen gehalten (Kommentare gestrafft).

## Geprüft

- Gegenprobe: Mutation (Max sendet bei `fkt_*` eine andere Antwort) → vier NOTICEs, Liste mit vier
  Einträgen, Test rot an vier Stellen. Original danach wiederhergestellt.
- Eine echte Inkonsistenz lässt sich im Neuaufbau nicht bauen: `lsa_im_pool` nimmt Aufgaben mit fehlender
  Teil-Lösung gar nicht erst auf, und `lsa_antwort_korrekt` nimmt die wörtlich gleiche Lösung immer an.
  Auf Prod schlägt die Liste deshalb nur an, wenn Format-Hinweis und Lösung auseinanderlaufen.

## Befunde

- Im Neuaufbau endet Max nach 05:20 Minuten mit 8–9 Aufgaben über die leere Auswahl, nicht über die Zeit.
- Die Dauern von Lina und Nele schwanken zwischen Läufen im Neuaufbau, auch auf dem Stand vor dieser
  Änderung (drei Läufe: Lina 14:14–15:36, Nele 12:08–14:21). Die Zusicherung „Zeit oder leere Auswahl“ hält
  in jedem Lauf.

## Offen

- Prod-Lauf `nur=Max` durch Rasit, danach die Liste an Lena.
