-- ============================================================================
-- A22: Generator 'winkel' in die Positivliste von task_figures.generator
--
-- Kein embedded begin/commit (Migrationsrunner umschliesst). ALLOW_MIGRATIONS=0:
-- Datei nach supabase/pending/, Rasit spielt ein.
--
-- ----------------------------------------------------------------------------
-- WARUM
-- ----------------------------------------------------------------------------
--   A19 hat task_figures.generator als POSITIVLISTE angelegt, damit ein
--   Tippfehler beim Einpflegen einer Zeile sofort auffaellt und nicht erst beim
--   Upload ("Unbekannter Generator"). Die Liste kannte bisher nur
--   'koordinatensystem'.
--
--   scripts/figures/winkel.py + pruefe_winkel.py sind der zweite Generator (ein
--   Winkel: zwei Schenkel, Winkelzeichen, Gradzahl). Damit eine
--   task_figures-Zeile ihn benennen darf, muss er in der Liste stehen.
--
--   HISTORIE IST APPEND-ONLY: die A19-Migration wird nicht angefasst. Der CHECK
--   traegt den von Postgres vergebenen Namen task_figures_generator_check
--   (inline deklariert, siehe supabase/schema-erwartet.sql). Ein CHECK laesst
--   sich nicht erweitern, also wird er unter DEMSELBEN Namen ersetzt — so zeigt
--   der Schema-Schnappschuss eine geaenderte Zeile und nicht zwei vertauschte
--   Constraints.
--
--   ALT-TEXT: unberuehrt. task_figures_alt_no_digit (alt_text !~ '[0-9]') gilt
--   weiter — ein Screenreader, der die Gradzahl vorliest, loest die Aufgabe.
--   Der alt-Text einer Winkel-Zeile wird also ohne Ziffer geschrieben
--   ("ein Winkel mit zwei Schenkeln und einem Bogen"), nicht mit.
-- ============================================================================

alter table task_figures
  drop constraint if exists task_figures_generator_check;

alter table task_figures
  add constraint task_figures_generator_check
  check (generator in ('koordinatensystem', 'winkel'));

comment on column task_figures.generator is
  'Positivliste der Abbildungs-Generatoren aus scripts/figures/ (A19: '
  '''koordinatensystem'', A22: ''winkel''). Ein Tippfehler beim Einpflegen '
  'faellt hier auf und nicht erst beim Upload. Jeder Eintrag braucht in '
  'upload_figures.py._lade_generator einen Adapter (zeichne/pruefe) — ohne den '
  'wird nichts erzeugt.';
