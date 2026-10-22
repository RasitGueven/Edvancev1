# Retro 22.10.2026 – LSA-V: Auswahl mit Grund (Thema, Grundlage, nächstes Schulthema)

## Ausgang
Testlauf von Testkonto B (6220b7e8, Klasse 9, Reelle Zahlen): Nach der Tiefe, die schon bei Minute 7 endete, lief nur
noch Breite a. Die zog Thales, Gleichungssysteme, Flächen und Zufall, ohne Bezug zum Thema. Bauauftrag
docs/lsa/Bauauftrag-LSA-V.md.

## Gebaut
- Migration `20261022065539_lsa_v_vorschau`: `lsa_select_next_core` ganz (Grundlage 20261021083026, gleich mit
  Prod). Mit Thema nach der Tiefe: Vorschau bis Minute 16 (`c_vorschau_bis`, `c_vorschau_themen = 2`), dann
  Thema vertiefen, dann Rückblick (bisherige Breite a), dann null. Breite b und Schritt 5 nur noch ohne Thema.
  Neue STABLE-Funktion `lsa_schule_von_sitzung` (drei Wege wie R7-9), auch für den Rückblick.
- Rollback `supabase/rollback/20261022065539_lsa_v_vorschau.sql`, auf einer Kopie geprüft: Funktion
  bytegleich mit dev, Hilfsfunktion weg.
- pgTAP `lsa_v_vorschau` (28, synthetischer Graph), `lsa_v_simulation` (9, Testkonto B mit Prod-Daten), inv10 mit drei
  umgestellten Erwartungen.
- `tools/lsa-v-abzug.sh` (Daten aus Prod über dbread), `tools/lsa-v-simulation.sh` (Tabellen vorher/nachher).

- Nachtrag LSA-D Fix A/B (#297, Abschnitte 2 und 7): `lsa_freie_aufgabe` gibt die erste freie Aufgabe eines
  Skills in Auswahlreihenfolge zurück und prüft `lsa_im_pool` zuletzt, nur bis zum ersten Treffer. Phase T,
  Vorschau, Thema vertiefen und Rückblick sortieren ihre Kandidaten nach Urteil und laufen sie der Reihe nach
  durch; die Restzeit genauso über die Aufgaben. pgTAP `lsa_v_gleich` (feste IDs, gleiche Folge wie c5d2c18),
  Messung in docs/lsa/lsa-v-messung.md: ohne Thema im Testpool max. 93 ms → 5 ms.

## Entscheidungen
- Kommende Themen, späterer Stoff und der Rand hängen nur an Plan und Graph. Sie werden einmal je Aufruf
  gerechnet, die Kandidaten in jeder Schleifenrunde gegen die Urteile geprüft.
- Position im Plan wie `aktuellePosition` in plan.ts (Thema, sonst erster Eintrag des Halbjahrs nach
  completed_at/started_at/created_at in Europe/Berlin, sonst Anfang).
- Ohne Plan wie `klpPlan` (Stufe, ab der Klasse), damit Klasse 10 nicht leer ausgeht. Ist bestätigungsbedürftig,
  siehe offene Punkte 5.

## Was auffiel
- Der Neuaufbau trägt denselben Graphen und denselben FWG-Plan wie Prod. Der erste Hash-Vergleich war nur
  wegen der Sortierfolge verschieden.
- Erwartung 17.4 (mehr direkt geprüft im Themenraum) widerspricht den Entscheidungen 10 und 14: Die
  abgeleiteten Bereiche sind mitbelegt und damit nicht „ohne Urteil“.
- Der Abzug aus Prod direkt ins Repo wurde vom Auto-Modus angehalten. Rasit hat danach freigegeben:
  Skill-Schlüssel, Zustände, Themen, Plan und Simulationstabellen, ohne Namen (Testkonto B), ohne IDs und
  Zeitstempel.

- Gleichheitstests brauchen feste Sitzungs- und Aufgaben-IDs, sonst entscheidet md5 über zufällige IDs.
- Fix B als „Pool einmal je Aufruf“ (v_pool_ids) hätte die volle Pool-Prüfung (270–380 ms) in jeden Aufruf
  gezogen. Umgesetzt ist B als „je Kandidat nur bis zum ersten Treffer“.
- Ein Abzug der Inhaltstabellen aus Prod für die Messung wurde angehalten (Personendaten). Gemessen wurde auf dem
  Neuaufbau mit synthetischen Aufgaben.

## Offen
docs/lsa/offene-punkte-lsa-v.md
