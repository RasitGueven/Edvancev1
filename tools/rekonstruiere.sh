#!/usr/bin/env bash
# rekonstruiere.sh — schreibt fehlende Migrationsdateien aus supabase_migrations.schema_migrations
# zurück ins Repo, sofern die Spalte `statements` gefüllt ist.
#
#   bash rekonstruiere.sh          # zeigt, was ginge
#   bash rekonstruiere.sh --apply  # schreibt die Dateien

set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
# Verbindung. Der Text hinter :? wird von der Shell EXPANDIERT — dort darf keine
# Kommandosubstitution stehen, sonst landet der Zugangsstring bei jedem
# Fehlschlag im Terminal. Der Weg zum Wert:
#   export DATABASE_URL="$(grep '^DATABASE_URL=' .env | cut -d= -f2- | tr -d "'\"")"
: "${DATABASE_URL:?nicht gesetzt (frueher DBURL) — siehe Kommentar in diesem Skript}"

APPLY=0; [[ "${1:-}" == "--apply" ]] && APPLY=1
ok(){ echo "  ✓ $*"; }; bad(){ echo "  ✗ $*"; }; info(){ echo "  · $*"; }

# Gibt es die Spalte überhaupt?
HAT_ST=$(psql "$DATABASE_URL" -tAc "select 1 from information_schema.columns
                              where table_schema='supabase_migrations'
                                and table_name='schema_migrations'
                                and column_name='statements'")
if [[ "$HAT_ST" != "1" ]]; then
  bad "Spalte 'statements' existiert nicht — Rekonstruktion aus der Historie unmöglich."
  info "Dann bleibt nur der Weg über das Schema. Sag Bescheid."
  exit 1
fi

# Welche Versionen fehlen?
FEHLT=()
while IFS= read -r v; do
  [[ -n "$v" ]] || continue
  ls supabase/migrations/"${v}"_*.sql >/dev/null 2>&1 || FEHLT+=("$v")
done < <(psql "$DATABASE_URL" -tAc "select version from supabase_migrations.schema_migrations order by version")

[[ ${#FEHLT[@]} -eq 0 ]] && { ok "Keine Datei fehlt."; exit 0; }

echo
echo "══ ${#FEHLT[@]} fehlende Version(en)"
echo

OFFEN=()
for v in "${FEHLT[@]}"; do
  read -r name n < <(psql "$DATABASE_URL" -tAF' ' -c \
    "select coalesce(nullif(name,''),'unbenannt'), coalesce(array_length(statements,1),0)
       from supabase_migrations.schema_migrations where version='$v'")

  printf '  %-16s %-34s %s Statement(s)\n' "$v" "$name" "$n"

  if [[ "$n" -eq 0 ]]; then OFFEN+=("$v  $name"); continue; fi

  ziel="supabase/migrations/${v}_${name}.sql"
  if [[ "$APPLY" -eq 1 ]]; then
    {
      echo "-- Rekonstruiert aus supabase_migrations.schema_migrations am $(date -u +%F)."
      echo "-- Inhalt entspricht dem eingespielten SQL, Formatierung kann abweichen."
      echo
      psql "$DATABASE_URL" -tAc \
        "select array_to_string(statements, E';\n\n') || ';'
           from supabase_migrations.schema_migrations where version='$v'"
    } > "$ziel"
    git add "$ziel"
    ok "geschrieben: $ziel  ($(wc -l < "$ziel") Zeilen)"
  else
    info "würde schreiben: $ziel"
  fi
done

if [[ ${#OFFEN[@]} -gt 0 ]]; then
  echo
  bad "Ohne gespeicherte Statements — nicht aus der Historie rekonstruierbar:"
  for x in "${OFFEN[@]}"; do echo "      $x"; done
  info "Diese wurden per psql eingespielt statt über die CLI. Weg über das Schema nötig."
fi

echo
[[ "$APPLY" -eq 0 ]] && info "Trockenlauf. Schreiben mit: bash rekonstruiere.sh --apply" \
                     || { echo "  Prüfen:"; echo "    scripts/check-migration-drift.sh"; }
echo
