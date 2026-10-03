# Retro 2026-10-03 — LSA-Auswahl: Thema, Tiefe, Breite (W3-6)

Branch `feat/lsa-thema-einstieg`. Bericht: `docs/themen/w3-6-lsa-auswahl.md`.

## Was gebaut wurde

- `20261003092850_lsa_thema_einstieg.sql`:
  - `lsa_lead_von_schueler`
  - `lsa_start`, nur Zweig adaptiv: setzt `thema_key`
  - `lsa_select_next_core` mit Phase T, Tiefe bis Minute 12, Breite a/b und Klassengrenze
  - Einstiegsknoten für Linear (3) und Zins (2)
- `20261003093007_lsa_thema_einstieg_kreis.sql`: Einstiegsknoten für Kreis (2), getrennt eingespielt.
- `supabase/tests/inv10_lsa_thema_auswahl.test.sql`: 30 Zusicherungen auf einem eigenen Graphen.
- `supabase/checks/lsa_thema_einstieg_trockenlauf.PRUEFUNG.sql`: begin, Migration, vier Sitzungen, rollback.

## Entscheidungen

- In Phase T werden erst alle Einstiege geprüft, dann folgt der Abstieg. Ein Einstieg, der trägt, belegt seinen Abschluss mit, und spätere Einstiege darin fallen weg.
- Phase T und Breite a ziehen nur Knoten mit einer noch freien Aufgabe und legen keine `ungeprueft`-Zeilen für Themen ohne Aufgaben an. Tiefe und Breite b behalten das alte Verhalten.
- Die Klassengrenze gilt in allen Stufen außer dem Zweitbeleg.
- Rang im Schulplan ist `klasse * 1000 + position`, weil die Position je Klasse neu beginnt.
- Teil 3: `thema_key` und `lsa_abschluss` reichen. Vorbehalt: spätere Änderungen am Graphen wirken auch auf alte Sitzungen.

## Was gut lief

- pgTAP ließ sich ohne Systeminstallation als reines SQL (`pgtap.sql.in` mit sed) in eine Wegwerf-DB laden. Damit lief der CI-Testschritt komplett lokal.
- Die Gegenprobe gegen die alten Funktionen zeigt, dass der Test die Änderung wirklich misst: 17 von 28 (erste Fassung) werden rot.

## Was hakte

- Der Trockenlauf gegen Prod (Schreiben in einer zurückgerollten Transaktion) wurde von der Sitzungsprüfung abgelehnt. Er bleibt bei Rasit.
- Neun verwaiste Sitzungen stehen auf `in_progress` und blockieren nach der Auftragsregel das Einspielen.
- In Prod sind alle Linear- und Zins-Aufgaben noch `draft`. Phase T wirkt für diese Themen erst nach Lenas Freigabe.

## Offene Punkte

1. Die neun `in_progress`-Sitzungen klären, dann einspielen und den Schema-Abzug ziehen.
2. Den Trockenlauf gegen Prod laufen lassen und die Abläufe in den PR übernehmen.
3. Kreis-Einstiege nach dem Kreis-Substrat einspielen.
4. Report: „darunter geprüft“ auf den Themenraum umstellen.
5. Klasse 7 mit Thema Linear bekommt keine Phase T (`klasse_herkunft` 8). Zusammen mit `feat/report-stufen` klären.
