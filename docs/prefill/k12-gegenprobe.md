# K12 – Gegenprobe zur Vorzeichen-Normalisierung im Skill-Urteil

Migration: `supabase/migrations/20261003101556_lsa_grade_vorzeichen_normalisierung.sql` (nicht eingespielt).
Befund: `docs/prefill/befunde-k9-kreis.md`, Abschnitt K12.

## Ursache

`lsa_grade` liest die Zahl über `lsa_split_value_unit`. Dessen Muster `^-?[0-9]+…` fängt `+11`, `- 3` und `−3` (U+2212)
nicht. Der Zahlteil bleibt leer, `lsa_grade` fällt auf den Textvergleich gegen `canonical` zurück, das Urteil lautet
„nicht". `lsa_is_correct` dagegen findet dieselbe Schreibweise in `correct_answers` und setzt `correct = true`.

Aufrufer laut `pg_proc` (Prod, 03.10.2026): `lsa_split_value_unit` wird nur von `lsa_parse_fraction`, `lsa_is_reduced`
und `lsa_grade` gerufen. `lsa_is_correct`, `lsa_fehlbild_match` und `lsa_normalize_term` nutzen nur
`lsa_normalize_answer` und bleiben unverändert.

## Änderung

- Neu: `lsa_normalize_number(text)` = `lsa_normalize_answer` + U+2212/U+2013/U+2014 → `-`, führendes `+` vor einer Ziffer
  weg, Leerzeichen zwischen Vorzeichen und Ziffer weg, außen getrimmt. Grants wie die Geschwister (nur `service_role`).
- `lsa_split_value_unit` ruft `lsa_normalize_number` statt `lsa_normalize_answer`. Muster, Signatur, Grants unverändert.

## Gegenprobe

1. **Prod, nur lesend (`dbread`):** jede Variante aus `correct_answers` der Chargen `edvance_fundament_vorlauf` und
   `edvance_k8_linfkt` durch `lsa_grade` geschickt, einmal roh (vorher) und einmal mit der neuen Normalisierung als
   SQL-Ausdruck vorab angewendet (nachher). Gleichwertig, weil `lsa_split_value_unit` neu = alt ∘ Normalisierung.
2. **Lokal, echte neue Funktion:** alle 3044 Prüfpaare des Prod-Bestands (jede Variante in `correct_answers`, jeder
   Schlüssel in `known_errors`, NUMERIC/SHORT_TEXT/TERM und MULTI_PART-Teile) lesend exportiert und in einem Neuaufbau
   aus allen Migrationen mit der neuen `lsa_grade` bewertet.

| Prüfung | vorher | nachher | Anzahl | Einheiten |
|---|---|---|---|---|
| richtige Variante | nicht | voll | 93 | 47 (17 Vorlauf, 30 Lin. Fkt.) |
| richtige Variante | voll | voll | 1010 | 613 |
| Fehlbild-Schlüssel | nicht | nicht | 1920 | 426 |
| Fehlbild-Schlüssel | teilweise | teilweise | 21 | 21 |

Keine richtige Variante wird schlechter, kein Fehlbild wird „voll". In den beiden Chargen sind alle 172 Varianten jetzt
„voll" (Vorlauf 44, Lineare Funktionen 128).

Hinweis: Bei MULTI_PART bildet `lsa_urteil_buchen_core` das Urteil aus `correct` der Teilzeilen, nicht über `lsa_grade`.
Die zwölf Teilaufgaben aus Vorlauf (`vorlauf-koord-*`) waren im gebuchten Urteil deshalb schon richtig; die Tabelle
rechnet sie wie K12 je Teil über `lsa_grade` nach.

### Die 93 Varianten, die sich ändern

| Quelle | Aufgabe | Variante | Urteil vorher | Urteil nachher |
|---|---|---|---|---|
| Vorlauf | vorlauf-einsetzen-01 | `- 3` | nicht | voll |
| Vorlauf | vorlauf-einsetzen-01 | `−3` | nicht | voll |
| Vorlauf | vorlauf-einsetzen-02 | `+11` | nicht | voll |
| Vorlauf | vorlauf-einsetzen-03 | `+12` | nicht | voll |
| Vorlauf | vorlauf-einsetzen-04 | `+15` | nicht | voll |
| Vorlauf | vorlauf-einsetzen-06 | `+14` | nicht | voll |
| Vorlauf | vorlauf-koord-01 T1 | `+4` | nicht | voll |
| Vorlauf | vorlauf-koord-01 T2 | `+3` | nicht | voll |
| Vorlauf | vorlauf-koord-02 T1 | `- 4` | nicht | voll |
| Vorlauf | vorlauf-koord-02 T1 | `−4` | nicht | voll |
| Vorlauf | vorlauf-koord-02 T2 | `+2` | nicht | voll |
| Vorlauf | vorlauf-koord-03 T1 | `- 2` | nicht | voll |
| Vorlauf | vorlauf-koord-03 T1 | `−2` | nicht | voll |
| Vorlauf | vorlauf-koord-03 T2 | `- 5` | nicht | voll |
| Vorlauf | vorlauf-koord-03 T2 | `−5` | nicht | voll |
| Vorlauf | vorlauf-koord-04 T1 | `+3` | nicht | voll |
| Vorlauf | vorlauf-koord-04 T2 | `- 2,5` | nicht | voll |
| Vorlauf | vorlauf-koord-04 T2 | `−2,5` | nicht | voll |
| Vorlauf | vorlauf-koord-05 T1 | `- 4` | nicht | voll |
| Vorlauf | vorlauf-koord-05 T1 | `−4` | nicht | voll |
| Vorlauf | vorlauf-koord-05 T2 | `+2` | nicht | voll |
| Vorlauf | vorlauf-koord-06 T1 | `+4` | nicht | voll |
| Vorlauf | vorlauf-koord-06 T2 | `- 3` | nicht | voll |
| Vorlauf | vorlauf-koord-06 T2 | `−3` | nicht | voll |
| Lin. Fkt. | linfkt-gleichung-01 | `+10` | nicht | voll |
| Lin. Fkt. | linfkt-gleichung-02 | `- 1` | nicht | voll |
| Lin. Fkt. | linfkt-gleichung-02 | `−1` | nicht | voll |
| Lin. Fkt. | linfkt-gleichung-03 | `+19` | nicht | voll |
| Lin. Fkt. | linfkt-gleichung-04 | `- 2` | nicht | voll |
| Lin. Fkt. | linfkt-gleichung-04 | `−2` | nicht | voll |
| Lin. Fkt. | linfkt-gleichung-05 | `+11` | nicht | voll |
| Lin. Fkt. | linfkt-gleichung-05 | `+11 €` | nicht | voll |
| Lin. Fkt. | linfkt-gleichung-05 | `+11€` | nicht | voll |
| Lin. Fkt. | linfkt-gleichung-06 | `+15` | nicht | voll |
| Lin. Fkt. | linfkt-gleichung-06 | `+15 cm` | nicht | voll |
| Lin. Fkt. | linfkt-gleichung-06 | `+15cm` | nicht | voll |
| Lin. Fkt. | linfkt-graph-01 | `+1` | nicht | voll |
| Lin. Fkt. | linfkt-graph-02 | `- 1` | nicht | voll |
| Lin. Fkt. | linfkt-graph-02 | `−1` | nicht | voll |
| Lin. Fkt. | linfkt-graph-03 | `+0,5` | nicht | voll |
| Lin. Fkt. | linfkt-graph-03 | `+0.5` | nicht | voll |
| Lin. Fkt. | linfkt-graph-03 | `+1/2` | nicht | voll |
| Lin. Fkt. | linfkt-graph-04 | `- 1` | nicht | voll |
| Lin. Fkt. | linfkt-graph-04 | `−1` | nicht | voll |
| Lin. Fkt. | linfkt-graph-05 | `+2` | nicht | voll |
| Lin. Fkt. | linfkt-graph-06 | `+2` | nicht | voll |
| Lin. Fkt. | linfkt-graph-06 | `+2 €` | nicht | voll |
| Lin. Fkt. | linfkt-graph-06 | `+2€` | nicht | voll |
| Lin. Fkt. | linfkt-nullstelle-01 | `+4` | nicht | voll |
| Lin. Fkt. | linfkt-nullstelle-02 | `- 2` | nicht | voll |
| Lin. Fkt. | linfkt-nullstelle-02 | `−2` | nicht | voll |
| Lin. Fkt. | linfkt-nullstelle-03 | `+2,5` | nicht | voll |
| Lin. Fkt. | linfkt-nullstelle-03 | `+2.5` | nicht | voll |
| Lin. Fkt. | linfkt-nullstelle-03 | `+5/2` | nicht | voll |
| Lin. Fkt. | linfkt-nullstelle-04 | `- 6` | nicht | voll |
| Lin. Fkt. | linfkt-nullstelle-04 | `−6` | nicht | voll |
| Lin. Fkt. | linfkt-nullstelle-05 | `+5` | nicht | voll |
| Lin. Fkt. | linfkt-nullstelle-05 | `+5 h` | nicht | voll |
| Lin. Fkt. | linfkt-nullstelle-05 | `+5h` | nicht | voll |
| Lin. Fkt. | linfkt-nullstelle-06 | `- 6` | nicht | voll |
| Lin. Fkt. | linfkt-nullstelle-06 | `−6` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-01 | `+3` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-02 | `+2` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-03 | `- 2` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-03 | `−2` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-04 | `+0,5` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-04 | `+0.5` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-04 | `+1/2` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-05 | `+1,5` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-05 | `+1,5 €` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-05 | `+1,5€` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-05 | `+1,50` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-05 | `+1,50 €` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-05 | `+1,50€` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-05 | `+1.5` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-05 | `+1.5 €` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-05 | `+1.5€` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-05 | `+1.50` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-05 | `+1.50 €` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-05 | `+1.50€` | nicht | voll |
| Lin. Fkt. | linfkt-steigung-06 | `+9` | nicht | voll |
| Lin. Fkt. | linfkt-yabschnitt-01 | `+5` | nicht | voll |
| Lin. Fkt. | linfkt-yabschnitt-02 | `+7` | nicht | voll |
| Lin. Fkt. | linfkt-yabschnitt-03 | `- 6` | nicht | voll |
| Lin. Fkt. | linfkt-yabschnitt-03 | `−6` | nicht | voll |
| Lin. Fkt. | linfkt-yabschnitt-04 | `- 2` | nicht | voll |
| Lin. Fkt. | linfkt-yabschnitt-04 | `−2` | nicht | voll |
| Lin. Fkt. | linfkt-yabschnitt-05 | `+8` | nicht | voll |
| Lin. Fkt. | linfkt-yabschnitt-05 | `+8 €` | nicht | voll |
| Lin. Fkt. | linfkt-yabschnitt-05 | `+8€` | nicht | voll |
| Lin. Fkt. | linfkt-yabschnitt-06 | `+120` | nicht | voll |
| Lin. Fkt. | linfkt-yabschnitt-06 | `+120 cm` | nicht | voll |
| Lin. Fkt. | linfkt-yabschnitt-06 | `+120cm` | nicht | voll |
