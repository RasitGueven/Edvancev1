#!/usr/bin/env bash
# db-migrate.sh — der einzige Weg, eine Migration einzuspielen.
#
#   scripts/db-migrate.sh supabase/migrations/20260728093000_a22_lsa_fehlbild.sql
#
# Macht die drei Schritte, die bisher auseinandergefallen sind, als einen:
#   1. SQL einspielen
#   2. Eintrag in supabase_migrations.schema_migrations
#   3. Datei stagen
#
# Der entscheidende Punkt ist Schritt 0: das Skript verweigert jede Datei, die nicht
# in supabase/migrations/ liegt. Damit ist die richtige Ablage nicht mehr Disziplin,
# sondern Vorbedingung fürs Einspielen. Genau daran ist es sechsmal gescheitert.
#
# Braucht: DBURL (Postgres-Connection-String der Zieldatenbank)

set -euo pipefail

file="${1:-}"
[[ -n "$file" ]] || { echo "Nutzung: $0 <supabase/migrations/*.sql>" >&2; exit 1; }
[[ -f "$file" ]] || { echo "Datei nicht gefunden: $file" >&2; exit 1; }
[[ -n "${DBURL:-}" ]] || { echo "DBURL nicht gesetzt." >&2; exit 1; }

repo_root=$(git rev-parse --show-toplevel)
rel=$(realpath --relative-to="$repo_root" "$file")

# ── Schritt 0: Ablage erzwingen ─────────────────────────────────────────────
if [[ "$rel" != supabase/migrations/* ]]; then
  cat >&2 <<EOF
Abgelehnt: $rel liegt nicht in supabase/migrations/.

Eingespielt wird nur, was im Repo an der richtigen Stelle liegt. Verschiebe die Datei:

  git mv "$rel" supabase/migrations/\$(date -u +%Y%m%d%H%M%S)_<name>.sql

und starte erneut. Wenn du sie trotzdem von Hand einspielst, driften Repo und Datenbank
auseinander — der Neuaufbau aus dem Repo bricht dann ab.
EOF
  exit 1
fi

base=$(basename "$rel" .sql)
version="${base%%_*}"
name="${base#*_}"

[[ "$version" =~ ^[0-9]{14}$ ]] || {
  echo "Dateiname muss <14-stelliger UTC-Zeitstempel>_<name>.sql sein, ist: $base" >&2
  echo "Vorschlag: $(date -u +%Y%m%d%H%M%S)_${base}.sql" >&2
  exit 1
}

# Schon eingespielt?
if psql "$DBURL" -tAc \
   "select 1 from supabase_migrations.schema_migrations where version = '$version'" \
   | grep -q 1; then
  echo "Version $version ist bereits eingetragen — nichts zu tun."
  git add "$rel" 2>/dev/null || true
  exit 0
fi

echo "→ Spiele ein: $rel"
psql "$DBURL" -P pager=off -v ON_ERROR_STOP=1 -f "$rel"

echo "→ Trage Historie ein: $version ($name)"
grep -q '\$mig\$' "$rel" && { echo "Datei enthält \$mig\$ — Historieneintrag von Hand." >&2; exit 1; }
psql "$DBURL" -P pager=off -v ON_ERROR_STOP=1 <<SQL
insert into supabase_migrations.schema_migrations (version, name, statements)
values ('$version', '$name', array[\$mig\$$(cat "$rel")\$mig\$])
on conflict (version) do update set statements = excluded.statements;
SQL

echo "→ Stage $rel"
git add "$rel"

echo
echo "Fertig. $rel ist eingespielt, eingetragen und gestaged."
echo "Prüfen: scripts/check-migration-drift.sh"
