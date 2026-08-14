-- AF3 — Fehlbild-Klartexte in Elternsprache, mit Abnahme-Schranke.
--
-- Ausgangslage (Bestueckungsanalyse 2026-08-12):
--   * fehlbild_labels hat 72 Zeilen — klartext und erklaerung sind in ALLEN 72
--     null. Die Tabelle ist heute eine reine Slug-Registry.
--   * AF2 gibt klartext bereits aus beiden RPCs heraus. Er ist nur leer.
--   * 3 Aufgaben referenzieren den Slug 'falsche_operation', der in der
--     Registry fehlt (73 verwendete Slugs gegen 72 gepflegte).
--   * Real aufgetreten sind in 129 Antworten bisher GENAU ZWEI Fehlbilder:
--     linearer_faktor (2x) und faktor_zehn_daneben (1x).
--
-- Entscheidung (Stufe 2, Punkt a): Klartexte werden NICHT auf Vorrat fuer alle
-- 72 Slugs geschrieben, sondern nur fuer die real auftretenden. Ein Klartext,
-- den nie jemand liest, ist unbelegte Arbeit — und jeder ungeprueft
-- ausgelieferte Satz ueber das Denken eines Kindes ist ein Risiko im
-- Elterngespraech.
--
-- ----------------------------------------------------------------------------
-- Die Abnahme-Schranke — warum sie in der RPC sitzt und nicht im Client
-- ----------------------------------------------------------------------------
-- Die Texte unten sind LLM-ENTWUERFE. Sie sind fachlich plausibel, aber nicht
-- abgenommen. Lena nimmt ab, indem sie freigegeben_am setzt (siehe Kommentar
-- am Tabellenende).
--
-- Die Schranke steht in lsa_fehlbild_auswertung/-report, nicht in der React-
-- Schicht: ein Klartext ohne Abnahme darf ueberhaupt nicht ueber die
-- Datenbankgrenze treten. Sonst haengt die Zusicherung an der Disziplin jedes
-- kuenftigen Konsumenten — und der Elternreport ist genau die Flaeche, auf der
-- ein durchgerutschter Entwurf am teuersten ist. Der Client sieht klartext null
-- und zeigt seinen neutralen Fallback; er muss die Regel nicht kennen.
--
-- KEIN begin/commit (der Runner klammert).


-- ── 1. Abnahme-Spalten ──────────────────────────────────────────────────────
--
-- freigegeben_am null  = Entwurf, wird nirgends ausgeliefert.
-- freigegeben_am gesetzt = von einem Menschen abgenommen, wird ausgeliefert.
--
-- Bewusst KEIN NOT NULL und kein Default: der Normalzustand einer neuen Zeile
-- ist "nicht abgenommen". Ein Default würde die Schranke beim naechsten
-- Registry-Zuwachs stillschweigend aushebeln.

alter table public.fehlbild_labels
  add column if not exists freigegeben_am  timestamptz,
  add column if not exists freigegeben_von uuid references public.profiles(id);

comment on column public.fehlbild_labels.freigegeben_am is
  'AF3 Abnahme-Schranke. NULL = klartext/erklaerung sind unabgenommener '
  'Entwurf und werden von lsa_fehlbild_auswertung/-report als NULL '
  'ausgeliefert. Abnahme: update fehlbild_labels set freigegeben_am = now(), '
  'freigegeben_von = ''<profil-uuid>'' where slug = ''<slug>'';';

comment on column public.fehlbild_labels.freigegeben_von is
  'AF3: wer abgenommen hat (profiles.id). Zusammen mit freigegeben_am zu '
  'setzen — die Spalte belegt die Abnahme, sie steuert sie nicht.';


-- ── 2. Fehlender Slug: falsche_operation ────────────────────────────────────
--
-- Nebenbefund der Bestueckungsanalyse. Drei Aufgaben referenzieren ihn in
-- acceptance->known_errors, die Registry kennt ihn nicht. Alle drei stehen auf
-- status draft, der Slug ist also noch nie im Report aufgetaucht — die Luecke
-- zu schliessen ist trotzdem richtig, bevor eine der drei auf ready geht.
--
-- Ohne Klartext: er ist real nie aufgetreten, faellt also unter dieselbe Regel
-- wie die uebrigen 69.

insert into public.fehlbild_labels (slug, klartext, erklaerung)
values ('falsche_operation', null, null)
on conflict (slug) do nothing;


-- ── 3. Klartext-Entwuerfe fuer die zwei real aufgetretenen Fehlbilder ───────
--
-- Sprachregeln (INV-4, siehe src/test/invariants/inv4-eltern-sprache.test.ts):
--   * Siezen. Der Report wird Eltern vorgelegt, nicht Kindern.
--   * Kein Defizit-Vokabular ueber das Kind ("kann nicht", "Schwaeche",
--     "Fehler des Kindes"). Beschrieben wird der DENKSCHRITT, nicht das Kind.
--   * Kein Fachjargon aus der Registry ("linearer Faktor", "Slug", "Fehlbild").
--   * klartext ist die Ueberschrift im Gespraech (kurz, benennt den Schritt),
--     erklaerung der Satz, den der Coach vorliest.

update public.fehlbild_labels set
  klartext   = 'Beim Umrechnen einmal statt mehrfach vergrößert',
  erklaerung =
    'Wenn eine Länge verdoppelt wird, vervierfacht sich die Fläche und der '
    'Rauminhalt wird achtmal so groß. Hier wurde der Faktor genau einmal '
    'angewendet — der Rechenweg stimmt, nur die Anzahl der Schritte nicht. '
    'Das ist ein sehr häufiger Zwischenschritt und lässt sich gezielt üben.'
where slug = 'linearer_faktor';

update public.fehlbild_labels set
  klartext   = 'Um eine Stelle verrutscht',
  erklaerung =
    'Das Ergebnis ist zehnmal zu groß oder zehnmal zu klein. Der Rechenweg '
    'war richtig, verrutscht ist die Kommastelle beziehungsweise die '
    'Zehnerstufe der Einheit. Wir üben das über eine kurze Größenabschätzung '
    'vor dem Rechnen.'
where slug = 'faktor_zehn_daneben';

-- Die Entwuerfe sind bewusst NICHT freigegeben. Bis Lena abnimmt, liefert die
-- RPC null und der Report zeigt seinen neutralen Text.


-- ── 4. Die zwei RPCs um die Schranke ergaenzen ──────────────────────────────
--
-- Identisch zu AF2 (20260729100000), EINZIGE Aenderung: der klartext-Ausdruck
-- passiert die Abnahme-Schranke. Der Rest steht hier nur, weil `create or
-- replace function` den ganzen Koerper braucht — die Begruendungen zu
-- Einstufung, LEFT JOIN und "was falsch heisst" stehen in AF2 und werden hier
-- nicht wiederholt.

create or replace function public.lsa_fehlbild_report(p_session_id uuid)
returns table (
  skill_key     text,
  fehlbild_slug text,
  klartext      text,
  anzahl        bigint,
  anteil        numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with falsch as (
    select t.skill_key     as sk,
           r.fehlbild_slug as slug
      from public.lsa_responses r
      join public.tasks t on t.id = r.task_id
     where r.session_id = p_session_id
       and exists (
         select 1 from public.lsa_sessions s
          where s.id = p_session_id
            and coalesce(public.lsa_may_act_for(s.student_id), false)
       )
       and r.abgabeart  = 'antwort'
       and r.correct is false
  ),
  je_slug as (
    -- group by trifft slug null als eigene Gruppe (NULLs gelten hier als
    -- gleich) — das ist die "nicht zugeordnet"-Zeile.
    -- Das Fenster ueber der Aggregation liefert den Nenner je Skill, ohne die
    -- Basis ein zweites Mal zu lesen.
    select f.sk,
           f.slug,
           count(*)                            as n,
           sum(count(*)) over (partition by f.sk) as n_skill
      from falsch f
     group by f.sk, f.slug
  )
  select g.sk,
         g.slug,
         -- "nicht zugeordnet" bleibt unabhaengig von der Abnahme sichtbar: es
         -- ist kein Klartext ueber ein Kind, sondern ein Befund ueber die
         -- Registry — genau die Luecke, die Lena sehen muss (AF2).
         case when g.slug is null then 'nicht zugeordnet'
              when l.freigegeben_am is null then null
              else l.klartext end,
         g.n,
         -- Anteil als Bruchteil 0..1, auf 4 Stellen gerundet. Gerundete
         -- Anteile summieren sich nicht zwingend exakt auf 1 — massgeblich
         -- ist `anzahl`.
         round(g.n::numeric / g.n_skill, 4)
    from je_slug g
    left join public.fehlbild_labels l on l.slug = g.slug
   order by g.sk asc, g.n desc, g.slug asc
$$;

create or replace function public.lsa_fehlbild_auswertung(p_session_id uuid)
returns table (
  fehlbild_slug       text,
  klartext            text,
  anzahl              bigint,
  aufgaben            bigint,
  skills              text[],
  skill_uebergreifend boolean,
  einstufung          text
)
language sql
stable
security definer
set search_path = public
as $$
  with falsch as (
    select r.fehlbild_slug as slug,
           r.task_id       as task_id,
           t.skill_key     as sk
      from public.lsa_responses r
      join public.tasks t on t.id = r.task_id
     where r.session_id = p_session_id
       and exists (
         select 1 from public.lsa_sessions s
          where s.id = p_session_id
            and coalesce(public.lsa_may_act_for(s.student_id), false)
       )
       and r.abgabeart  = 'antwort'
       and r.correct is false
       and r.fehlbild_slug is not null
  ),
  je_slug as (
    -- `aufgaben` zaehlt AUFGABEN, nicht Zeilen: zwei Teilaufgaben desselben
    -- Items sind eine Aufgabe. Genau darauf steht die Einstufung.
    -- count(distinct sk) ignoriert NULL — eine Aufgabe ohne Skill ist kein
    -- zweiter Skill und macht ein Fehlbild nicht uebergreifend.
    select f.slug,
           count(*)                  as n,
           count(distinct f.task_id) as n_aufgaben,
           count(distinct f.sk)      as n_skills,
           coalesce(
             array_agg(distinct f.sk order by f.sk) filter (where f.sk is not null),
             '{}'::text[])           as sk_liste
      from falsch f
     group by f.slug
  )
  select g.slug,
         case when l.freigegeben_am is null then null else l.klartext end,
         g.n,
         g.n_aufgaben,
         g.sk_liste,
         (g.n_skills >= 2),
         case when g.n >= 2 and g.n_aufgaben >= 2 then 'befund' else 'beobachtung' end
    from je_slug g
    left join public.fehlbild_labels l on l.slug = g.slug
   -- Befunde zuerst, darin das haeufigste — der Report liest von oben.
   order by (case when g.n >= 2 and g.n_aufgaben >= 2 then 0 else 1 end),
            g.n desc, g.slug asc
$$;

comment on function public.lsa_fehlbild_auswertung(uuid) is
  'AF2/AF3 Report-Sicht: Fehlbilder einer LSA-Sitzung ueber alle Skills '
  'hinweg. einstufung=''befund'' bei anzahl>=2 UND aufgaben>=2, sonst '
  '''beobachtung''; skill_uebergreifend bei >=2 verschiedenen Skills. '
  'klartext ist null, solange fehlbild_labels.freigegeben_am null ist '
  '(AF3-Abnahme-Schranke) oder der Slug nicht in der Registry steht.';

comment on function public.lsa_fehlbild_report(uuid) is
  'AF2/AF3 Coach-Sicht: Fehlbilder einer LSA-Sitzung nach Skill gruppiert. '
  'Falschantworten ohne Slug erscheinen als eigene Zeile mit klartext '
  '''nicht zugeordnet''. klartext ist null, solange fehlbild_labels.'
  'freigegeben_am null ist (AF3-Abnahme-Schranke).';
