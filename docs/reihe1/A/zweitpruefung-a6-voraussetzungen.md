# Zweitprüfung A6 Voraussetzungen (Migration 20261028144703_reihe1_a6_fehlbilder_figuren, sieben Datenmigrationen, Motor)

Frischer Subagent ohne Kontext (28.10.2026), Frage „Was ist falsch, was fehlt, was bricht?“. Kein Blocker. Er hat alle
Migrationen zweimal in einer Transaktion eingespielt (zweiter Lauf: 0 Zeilen, Versionen bleiben 1), `session_bewerten`
auf jede kanonische Antwort und jede bekannte falsche Antwort (beide Minus-Schreibweisen) angewandt, `lsa_acceptance_valid`
für jede gespeicherte Regel geprüft und jede Instanz von GL-1, EIN-1 und QW-1 selbst nachgerechnet: 0 Fehler.
`aufgabe_ziehbar` ist richtig, alle Ziehwege laufen darüber; NP-2/WZ-1 ändern sich nicht.

| # | Befund | Abarbeitung |
|---|---|---|
| 1 | P2: GL-1 Stufe 3 sagt nur „Gib x an.“, Lösung ist ein Bruch | Stufe 3: „Gib x als gekürzten Bruch an.“ Neuer Blindlöser |
| 2 | P2: MC-Teile eines Mehrteilers würden in Prüfung 4 falsch geprüft | `klassisch.eingaben` und pgTAP schicken bei MC-Teilen die Option als Liste (noch nutzt keine Bauform MC-Teile) |
| 3 | P2: kein pgTAP für die Figur-Bedingung | `reihe1_a6_bauformen` Fall 5: ohne `svg_hash` nicht ziehbar, mit ziehbar |
| 4 | P2: wenige Zwillinge in kleinen Zahlenräumen (BIN-1/BIN-2/QW-1 Stufe 1–2) | BIN-1 auf d bis 15 erweitert. BIN-2 und QW-1 sind durch den Zahlenraum begrenzt (QW-1 bis 12² bzw. √225); im Bericht benannt |
| 5 | P2: „d“ in Rückmeldungen nie erklärt | „die Zahl in der Klammer“ |
| 6 | P3: Fehlbild-Werte nur als Bruch | Brüche mit endlicher Dezimalzahl auch als „40,5“/„40.5“ in `known_errors` |
| 7 | P3: Hinweise passten nicht zur Stufe (AUS-1 S1, KO-1) | AUS-1 je Stufe; KO-1 nennt links und unten |
| 8 | P3: Testlauf-Rückfall (`session_ziehen`, #358, Auftrag C) zieht Entwürfe ohne Figur-Prüfung | gehört C; im Bericht als offener Punkt |
