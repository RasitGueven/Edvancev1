# Retro 22.10.2026 – Diagnose LSA-D „Weiter“-Hänger

**Gebaut:** nur Diagnose. Bericht `docs/lsa/diagnose-weiter.md`, Messskript `tools/lsa-weiter-messung.sql`
(nur Wegwerf-DB), temporäre Zeitmessung in edvance-app PR #45.

**Befund:** Die Restzeit-Abfrage in `lsa_select_next_core` prüft `lsa_im_pool` für ~890 Aufgaben vor dem
billigen Ausschluss. Im Testlauf-Pool sind das ~400 ms lokal und 1–3 s in Prod (`platz_submit` Ø 464 ms,
max. 3,3 s). Dazu kommt `platz_next` als überflüssige zweite Runde und ein strikt sequenzieller Übergang.
Vercel liegt nicht im Pfad (keine Funktionen), es gibt keinen Cold Start.

**Entscheidungen:** gemessen gegen den CI-Neuaufbau plus Inhalts-Fixture, weil der reine Neuaufbau keine
Aufgabe im Pool hat. Prod nur lesend (`pg_stat_statements`).

**Offen:** Fix A (Migration Restzeit), Fix D/E/F (App). Messung am iPad mit PR #45, danach Zeitmessung
ausbauen. Nebenbefund: echter Pool endet für Kl. 8 / reelle_zahlen nach 10 Aufgaben.
