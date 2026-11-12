#!/usr/bin/env bash
# sp1-vorschau-daten.sh — Fixtures für die Ansichtstests „Session-Aufgaben prüfen“ (SP-1) aus Prod, nur lesend (dbread).
# Ruft die Lesefunktionen mit den Rechten eines Admins (set_config der JWT-Claims, transaktionslokal, read-only) und
# schreibt src/pages/coach/pruefen/bauformen/vorschau/fixtures.json: Plan, Auffällig, Prüffragen und die Prüfansicht
# von EIN-1, KO-1, PAR-2, PAR-3, NP-2 (Lösungsbeispiel) je mit zwei Beispiel-Ziehungen. Keine Personendaten: die
# Prüffragen und Kinder-Listen bleiben leer.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
ADMIN=$(~/bin/dbread -tAc "select id from profiles where role = 'admin' order by created_at limit 1")
~/bin/dbread -q -tA -v admin="$ADMIN" <<'SQL' > src/pages/coach/pruefen/bauformen/vorschau/fixtures.json
begin;
select set_config('request.jwt.claims', json_build_object('sub', :'admin', 'role', 'authenticated')::text, true) \g /dev/null
select (jsonb_build_object(
  'plan', (select jsonb_agg(to_jsonb(p)) from bauform_pruef_plan() p),
  'detail', (select jsonb_object_agg(b.id, jsonb_build_object('s0', bauform_pruef_detail(b.id, 0), 's1', bauform_pruef_detail(b.id, 1)))
               from bauformen b where b.schluessel in ('EIN-1', 'KO-1', 'PAR-2', 'PAR-3', 'NP-2', 'NS-4', 'NF-5')))::text);
rollback;
SQL
sed -i -e '/^BEGIN$/d' -e '/^ROLLBACK$/d' src/pages/coach/pruefen/bauformen/vorschau/fixtures.json
echo "fixtures.json: $(wc -c < src/pages/coach/pruefen/bauformen/vorschau/fixtures.json) Bytes"
