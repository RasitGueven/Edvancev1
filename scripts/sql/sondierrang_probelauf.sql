-- sondierrang_probelauf.sql
--
-- Beweist, dass sondierrang_setzen.sql durchgeht und die Pruefung danach
-- besteht — ohne zu wirken. Setzen und Pruefen stehen in einer Transaktion,
-- die am Ende verworfen wird.
--
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/sql/sondierrang_probelauf.sql
--
-- Der Lauf endet mit ROLLBACK. Der Aufruf erfolgt aus dem Repo-Wurzelverzeichnis;
-- die \i-Pfade sind relativ dazu.
--
-- supabase/checks/sondierrang.PRUEFUNG.sql enthaelt keine eigene
-- Transaktionsklammer (die 'begin' dort sind PL/pgSQL-Bloecke innerhalb von
-- do $$ … $$, keine SQL-Anweisungen), deshalb laesst es sich hier einbinden,
-- ohne es zu aendern.
--
-- Das scharfe Setzen macht Rasit, nach Durchsicht von out/sondierrang-bericht.md:
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/sql/sondierrang_setzen.sql
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/checks/sondierrang.PRUEFUNG.sql

\set ON_ERROR_STOP on

begin;

\echo '— setzen (wird verworfen) —'
\i scripts/sql/sondierrang_setzen.sql

\echo '— pruefen —'
\i supabase/checks/sondierrang.PRUEFUNG.sql

rollback;

\echo '— verworfen: die Datenbank ist unveraendert —'
