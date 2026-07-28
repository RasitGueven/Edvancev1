-- ============================================================================
-- A23: Generator 'dreieck' in die Positivliste von task_figures.generator
--
-- Kein embedded begin/commit (Migrationsrunner umschliesst). ALLOW_MIGRATIONS=0:
-- Datei nach supabase/pending/, Rasit spielt ein.
--
-- ----------------------------------------------------------------------------
-- WARUM
-- ----------------------------------------------------------------------------
--   A19 hat task_figures.generator als POSITIVLISTE angelegt, damit ein
--   Tippfehler beim Einpflegen einer Zeile sofort auffaellt und nicht erst beim
--   Upload ("Unbekannter Generator"). Die Liste kannte bisher
--   'koordinatensystem' (A19) und 'winkel' (A22).
--
--   scripts/figures/dreieck.py + pruefe_dreieck.py sind der dritte Generator
--   (ein Dreieck: waagerechte Grundseite, Hoehe als gestrichelte Linie, Masse
--   aussen). Damit eine task_figures-Zeile ihn benennen darf, muss er in der
--   Liste stehen.
--
--   HISTORIE IST APPEND-ONLY: weder die A19- noch die A22-Migration wird
--   angefasst. Der CHECK traegt den von Postgres vergebenen Namen
--   task_figures_generator_check (inline deklariert, siehe
--   supabase/schema-erwartet.sql). Ein CHECK laesst sich nicht erweitern, also
--   wird er unter DEMSELBEN Namen ersetzt — so zeigt der Schema-Schnappschuss
--   eine geaenderte Zeile und nicht zwei vertauschte Constraints.
--
--   ALT-TEXT: unberuehrt. task_figures_alt_no_digit (alt_text !~ '[0-9]') gilt
--   weiter — ein Screenreader, der die Masse vorliest, loest die Aufgabe. Der
--   alt-Text einer Dreieck-Zeile wird also ohne Ziffer geschrieben ("ein
--   Dreieck mit waagerechter Grundseite und eingezeichneter Hoehe"), nicht mit.
--   Ist die Figur ueber 1:4 gekappt, gehoert das in den alt-Text: die Zeichnung
--   ist dort nicht massstaeblich, und das Zickzack sieht ein Screenreader nicht.
-- ============================================================================

alter table task_figures
  drop constraint if exists task_figures_generator_check;

alter table task_figures
  add constraint task_figures_generator_check
  check (generator in ('koordinatensystem', 'winkel', 'dreieck'));

comment on column task_figures.generator is
  'Positivliste der Abbildungs-Generatoren aus scripts/figures/ (A19: '
  '''koordinatensystem'', A22: ''winkel'', A23: ''dreieck''). Ein Tippfehler '
  'beim Einpflegen faellt hier auf und nicht erst beim Upload. Jeder Eintrag '
  'braucht in upload_figures.py._lade_generator einen Adapter (zeichne/pruefe) '
  '— ohne den wird nichts erzeugt.';
