#!/usr/bin/env bash
# runbook.sh — geführter Durchlauf durch alle Phasen.
#
#   bash runbook.sh              # ab der letzten unerledigten Phase
#   bash runbook.sh --from 3     # ab Phase 3
#   bash runbook.sh --only 0     # nur Phase 0
#   bash runbook.sh --status     # Fortschritt zeigen
#
# Lesende Schritte laufen durch. Vor jedem Schreibzugriff auf Produktion hält das
# Skript an, zeigt was passieren wird, und fragt. Abbruch ist jederzeit gefahrlos —
# der Fortschritt steht in .runbook-state.
#
# Voraussetzung: setup-wsl.sh ist gelaufen, DATABASE_URL ist gesetzt.

set -uo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Kein Git-Repo."; exit 1; }
cd "$REPO"
STATE="$REPO/.runbook-state"
LOG="$REPO/.runbook-log"

# ── Ausgabe ─────────────────────────────────────────────────────────────────
b()    { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { echo "  ✓ $*"; }
warn() { echo "  ! $*"; }
bad()  { echo "  ✗ $*"; }
info() { echo "  · $*"; }
phase(){ echo; b "══ Phase $1 · $2"; echo; }

frage() {
  local a; read -rp "  → $1 [j/N] " a </dev/tty
  [[ "$a" =~ ^[jJyY]$ ]]
}
wort() {
  local a; read -rp "  → $1 " a </dev/tty
  [[ "$a" == "$2" ]]
}
halt() { echo; read -rp "  ⏎ weiter, Strg-C zum Abbrechen " </dev/tty; }

erledigt()   { grep -qx "$1" "$STATE" 2>/dev/null; }
markiere()   { echo "$1" >> "$STATE"; }

# ── Argumente ───────────────────────────────────────────────────────────────
FROM=0; ONLY=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)   FROM="$2"; shift 2 ;;
    --only)   ONLY="$2"; shift 2 ;;
    --status) echo "Erledigt:"; cat "$STATE" 2>/dev/null || echo "  (nichts)"; exit 0 ;;
    *) shift ;;
  esac
done
lauf() {  # lauf <nr> -> 0 wenn diese Phase dran ist
  [[ -n "$ONLY" ]] && { [[ "$ONLY" == "$1" ]]; return; }
  [[ "$1" -ge "$FROM" ]] && ! erledigt "phase$1"
}

psqlq() { psql "$DATABASE_URL" -tAc "$1" 2>/dev/null; }

exec > >(tee -a "$LOG") 2>&1
echo; echo "runbook.sh — $(date '+%F %T')"

# ════════════════════════════════════════════════════════════════════════════
# Phase 0 · Bestandsaufnahme
# ════════════════════════════════════════════════════════════════════════════
if lauf 0; then
phase 0 "Bestandsaufnahme (ändert nichts)"

for t in git node jq psql; do
  command -v "$t" >/dev/null && ok "$t" || bad "$t fehlt"
done

# Frueher DBURL — die war nirgends gesetzt, psql fiel auf Socket und
# Benutzernamen zurueck und der Lauf ging still ins Leere.
if [[ -z "${DATABASE_URL:-}" ]]; then
  bad "DATABASE_URL nicht gesetzt — ohne die geht ab Phase 1 nichts."
  echo "     export DATABASE_URL=\"\$(grep '^DATABASE_URL=' .env | cut -d= -f2- | tr -d \"'\\\"\")\""
  exit 1
fi
psqlq "select 1" >/dev/null && ok "Datenbank erreichbar" || { bad "Datenbank nicht erreichbar."; exit 1; }

echo
b "0.1 · supabase/pending/"
if [[ -d supabase/pending ]]; then
  PENDING=$(find supabase/pending -name '*.sql' | wc -l | tr -d ' ')
  [[ "$PENDING" -gt 0 ]] && { warn "$PENDING Migration(en) offen:"; find supabase/pending -name '*.sql' -printf '      %f\n'; } \
                         || warn "Verzeichnis existiert, ist leer — muss noch gelöscht werden"
else
  ok "existiert nicht"
fi

echo
b "0.2 · Historie gegen Repo"
APPLIED=$(psqlq "select version from supabase_migrations.schema_migrations order by version")
echo "  eingespielt: $(wc -l <<<"$APPLIED") · im Repo: $(ls supabase/migrations/*.sql 2>/dev/null | wc -l)"

FEHLEND=""
while IFS= read -r v; do
  [[ -n "$v" ]] || continue
  ls supabase/migrations/"${v}"_*.sql >/dev/null 2>&1 || FEHLEND+="$v "
done <<<"$APPLIED"
[[ -z "$FEHLEND" ]] && ok "jede eingespielte Version hat eine Datei" \
                    || bad "ohne Datei im Repo: $FEHLEND"

echo
b "0.3 · A13 / A14"
for v in a13 a14; do
  DATEI=$(ls supabase/migrations/ 2>/dev/null | grep -i "$v" | head -1)
  EINTRAG=$(psqlq "select version from supabase_migrations.schema_migrations where name ilike '%${v}%' limit 1")
  if   [[ -n "$DATEI" && -n "$EINTRAG" ]]; then ok  "${v^^}: Datei + Eintrag da — nur schema.sql prüfen"
  elif [[ -n "$DATEI" && -z "$EINTRAG" ]]; then warn "${v^^}: Datei da, Historieneintrag fehlt"
  elif [[ -z "$DATEI" && -n "$EINTRAG" ]]; then bad "${v^^}: eingespielt, aber keine Datei — Rekonstruktion nötig"
  else                                          info "${v^^}: weder Datei noch Eintrag — womöglich nie existiert"
  fi
done

echo
b "0.4 · Guard"
if [[ -f scripts/guard-paths.sh ]] && grep -q 'append-only\|ls-files --error-unmatch' scripts/guard-paths.sh; then
  ok "neuer Guard installiert"
else
  warn "alter oder kein Guard — setup-wsl.sh laufen lassen"
fi
jq -e '.. | .command? // empty | select(test("guard-paths"))' .claude/settings.json >/dev/null 2>&1 \
  && ok "Hook registriert" || warn "Hook nicht in .claude/settings.json"

echo
b "0.5 · Aufgabenbestand"
psqlq "select status || ': ' || count(*) from tasks group by status order by 1" | sed 's/^/      /'
for sp in question skill_key status; do
  psqlq "select 1 from information_schema.columns where table_name='tasks' and column_name='$sp'" | grep -q 1 \
    && ok "tasks.$sp" || bad "tasks.$sp fehlt — COL-Mapping in bildbedarf.mjs und Phase 5 anpassen"
done

markiere phase0
echo; b "Phase 0 fertig. Befunde oben lesen, bevor es weitergeht."; halt
fi

# ════════════════════════════════════════════════════════════════════════════
# Phase 1 · pending/ nachziehen  — SCHREIBT IN PRODUKTION
# ════════════════════════════════════════════════════════════════════════════
if lauf 1; then
phase 1 "pending/ nachziehen"

if [[ ! -d supabase/pending ]] || [[ $(find supabase/pending -name '*.sql' | wc -l) -eq 0 ]]; then
  ok "nichts offen"
  markiere phase1
else
  find supabase/pending -name '*.sql' -printf '      %f\n'
  echo
  warn "Diese Dateien werden verschoben und danach in PRODUKTION eingespielt."
  echo

  if frage "Nach supabase/migrations/ verschieben?"; then
    for f in supabase/pending/*.sql; do
      name=$(basename "$f" .sql | sed 's/^[0-9]*_//')
      ts=$(date -u +%Y%m%d%H%M%S)
      git mv "$f" "supabase/migrations/${ts}_${name}.sql" && ok "${ts}_${name}.sql"
      sleep 1
    done
  else
    info "übersprungen"; exit 0
  fi

  echo
  b "Einspielen — einzeln, mit Halt bei Fehler"
  for f in $(git diff --cached --name-only --diff-filter=A | grep '^supabase/migrations/' | sort); do
    echo
    b "  $(basename "$f")"
    echo "  ── erste 20 Zeilen ──"
    head -20 "$f" | sed 's/^/     /'
    echo "  ─────────────────────"
    if frage "In Produktion einspielen?"; then
      scripts/db-migrate.sh "$f" || { bad "gescheitert — angehalten."; exit 1; }
    else
      info "übersprungen — Phase 3 wird das melden"
    fi
  done
  markiere phase1
fi
echo; halt
fi

# ════════════════════════════════════════════════════════════════════════════
# Phase 2 · Guard aktivieren
# ════════════════════════════════════════════════════════════════════════════
if lauf 2; then
phase 2 "Guard aktivieren"

REST=$(find supabase/pending -name '*.sql' 2>/dev/null | wc -l)
[[ "$REST" -gt 0 ]] && { bad "$REST Migration(en) noch in pending/ — erst Phase 1."; exit 1; }

if [[ -d supabase/pending ]]; then
  if frage "supabase/pending/ löschen?"; then
    git rm -r --ignore-unmatch supabase/pending >/dev/null && rm -rf supabase/pending
    ok "gelöscht"
  fi
fi

echo
b "Guard-Test"
t=$(echo '{"tool_name":"Write","tool_input":{"file_path":"supabase/migrations/20991231000000_t.sql"}}' | bash scripts/guard-paths.sh >/dev/null 2>&1; echo $?)
[[ "$t" == 0 ]] && ok "neue Migration erlaubt" || bad "neue Migration blockiert (exit $t)"
V=$(git ls-files supabase/migrations/ | head -1)
if [[ -n "$V" ]]; then
  t=$(echo "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$V\"}}" | bash scripts/guard-paths.sh >/dev/null 2>&1; echo $?)
  [[ "$t" == 2 ]] && ok "bestehende Migration geschützt" || bad "NICHT geschützt (exit $t)"
fi
t=$(echo '{"tool_name":"Write","tool_input":{"file_path":"supabase/pending/x.sql"}}' | bash scripts/guard-paths.sh >/dev/null 2>&1; echo $?)
[[ "$t" == 2 ]] && ok "pending/ blockiert" || bad "pending/ nicht blockiert (exit $t)"

echo
grep -rl 'supabase/pending' CLAUDE.md docs/ 2>/dev/null | sed 's/^/  ! Verweis auf pending\/ in: /'

markiere phase2; echo; halt
fi

# ════════════════════════════════════════════════════════════════════════════
# Phase 3 · Reproduzierbarkeit
# ════════════════════════════════════════════════════════════════════════════
if lauf 3; then
phase 3 "Reproduzierbarkeit"

if command -v supabase >/dev/null && frage "schema.sql neu ziehen?"; then
  supabase db dump --db-url "$DATABASE_URL" -f supabase/schema.sql && { git add supabase/schema.sql; ok "aktualisiert"; }
fi

echo
scripts/check-migration-drift.sh
RC=$?
echo
if [[ "$RC" -eq 0 ]]; then
  ok "Kein Drift."
  markiere phase3
else
  bad "Drift offen. Ab hier nicht weitermachen — ein dauerhaft roter Check wird ignoriert"
  echo "     und ist dann wertlos. Bei fehlenden Dateien: Rekonstruktion aus Prod nötig."
  exit 1
fi
halt
fi

# ════════════════════════════════════════════════════════════════════════════
# Phase 4 · Bildbedarf
# ════════════════════════════════════════════════════════════════════════════
if lauf 4; then
phase 4 "Bildbedarf"

[[ -d node_modules/@supabase/supabase-js ]] || { warn "@supabase/supabase-js fehlt"; frage "npm i?" && npm i @supabase/supabase-js; }

if [[ ! -f .runbook-col-ok ]]; then
  node scripts/bildbedarf.mjs --probe
  echo
  warn "Das COL-Objekt oben in scripts/bildbedarf.mjs an diese Spalten anpassen."
  frage "Angepasst?" && touch .runbook-col-ok || exit 0
fi

echo; b "Stufe 1 — kostenlos, findet tote Bildverweise"
node scripts/bildbedarf.mjs --no-llm || { bad "gescheitert — COL-Mapping prüfen"; exit 1; }

echo
if frage "Vollen Lauf mit LLM starten? (kostet, ~15 Aufrufe)"; then
  node scripts/bildbedarf.mjs --sql
fi

markiere phase4; echo; halt
fi

# ════════════════════════════════════════════════════════════════════════════
# Phase 5 · Freigabe  — ÄNDERT ~500 DATENSÄTZE
# ════════════════════════════════════════════════════════════════════════════
if lauf 5; then
phase 5 "Freigabe"

DANG=0
if [[ -f out/bildbedarf.csv ]]; then
  awk -F';' 'NR>1 && $9 ~ /true/ {gsub(/"/,"",$1); print $1}' out/bildbedarf.csv > .runbook-dangling.txt
  DANG=$(wc -l < .runbook-dangling.txt)
  info "$DANG Aufgabe(n) mit totem Bildverweis"
else
  warn "out/bildbedarf.csv fehlt — Phase 4 nicht gelaufen. Tote Bildverweise werden NICHT ausgeschlossen."
  frage "Trotzdem weiter?" || exit 0
  : > .runbook-dangling.txt
fi

DANGSQL="-1"
[[ "$DANG" -gt 0 ]] && DANGSQL=$(paste -sd, .runbook-dangling.txt)

b "Ausschlussliste bauen"
psql "$DATABASE_URL" -q <<SQL
drop table if exists _runbook_ausschluss;
create table _runbook_ausschluss as
  select t.id, 'keine_loesung'::text as grund
    from tasks t left join task_solutions s on s.task_id = t.id
   where t.status = 'draft' and s.task_id is null
  union all
  select id, 'kein_skill' from tasks
   where status = 'draft' and (skill_key is null or skill_key = '')
  union all
  select id, 'totes_bild' from tasks
   where status = 'draft' and id in ($DANGSQL)
  union all
  select id, 'dublette' from (
    select id, row_number() over (partition by md5(lower(trim(question::text))) order by id) rn
      from tasks where status = 'draft') x
   where rn > 1;
SQL

echo "  Ausgeschlossen:"
psqlq "select '      ' || grund || ': ' || count(distinct id) from _runbook_ausschluss group by grund order by 1"

N=$(psqlq "select count(*) from tasks where status='draft' and id not in (select id from _runbook_ausschluss)")
echo
b "  → $N Aufgaben werden auf 'ready' gesetzt."
echo

if [[ "$N" -lt 300 ]]; then
  warn "Deutlich weniger als erwartet. Erst klären, warum."
  frage "Trotzdem weiter?" || exit 0
fi

# Exakter Rückweg: aktuellen Stand sichern, nicht pauschal zurückschieben
SIC="out/status-vorher-$(date +%Y%m%d%H%M%S).csv"
mkdir -p out
psql "$DATABASE_URL" -c "\copy (select id, status from tasks) to '$SIC' csv header" >/dev/null
ok "Vorzustand gesichert: $SIC"
info "Rückweg: die 14 bereits freigegebenen bleiben damit erhalten — ein pauschales"
info "         'alles zurück auf draft' würde die mitreissen."
echo

if wort "Zum Freigeben genau FREIGEBEN tippen:" "FREIGEBEN"; then
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<SQL
begin;
update tasks set status = 'ready'
 where status = 'draft' and id not in (select id from _runbook_ausschluss);
commit;
SQL
  ok "freigegeben"
  psqlq "select '      ' || status || ': ' || count(*) from tasks group by status order by 1"
  markiere phase5
else
  info "abgebrochen — nichts geändert"
  psql "$DATABASE_URL" -q -c "drop table if exists _runbook_ausschluss"
  exit 0
fi

psql "$DATABASE_URL" -q -c "drop table if exists _runbook_ausschluss"
fi

# ════════════════════════════════════════════════════════════════════════════
echo
b "══ Fertig"
echo
for p in 0 1 2 3 4 5; do
  erledigt "phase$p" && echo "  ✓ Phase $p" || echo "  · Phase $p offen"
done
cat <<'EOF'

  Vor dem Commit:
    echo -e "state/\n.worktrees/\n.runbook-*\nout/" >> .gitignore
    git status
    git commit -m "Migrations-Guard append-only, Drift-Prüfung, Bildbedarf-Lauf"
    git push          # pre-push-Hook prüft mit

  Danach: Orchestrator, Tutorial Teil 1.
EOF
