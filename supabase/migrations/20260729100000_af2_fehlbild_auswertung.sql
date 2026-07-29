-- AF2 — Fehlbilder abfragbar machen.
--
-- AF1 (20260726100000) schreibt lsa_responses.fehlbild_slug ueber
-- lsa_fehlbild_match. Gelesen hat die Spalte bisher niemand: die LSA weiss,
-- WARUM ein Kind falsch liegt, und kann es keinem sagen.
--
-- Zwei RPCs, eine Migration. Getrennt gebaut liefen sie auseinander — sie
-- teilen dieselbe Definition von "falscher Antwort" (abgabeart='antwort' und
-- correct is false) und denselben nachsichtigen Registry-Join.
--
-- KEIN begin/commit (der Runner klammert). Die PRUEFUNG steht in
-- supabase/checks/fehlbild_auswertung.PRUEFUNG.sql und laeuft gegen eine
-- bereits migrierte Datenbank.
--
-- ----------------------------------------------------------------------------
-- Zwei gemeinsame Entscheidungen, die beide RPCs tragen
-- ----------------------------------------------------------------------------
--  * FALSCH heisst `abgabeart = 'antwort' and correct is false`. Ein "weiss
--    nicht" oder eine leere Abgabe ist kein Denkfehler (A13); AF1 vergibt dort
--    schon keinen Slug. Die beiden Bedingungen sind heute redundant: der CHECK
--    lsa_responses_correct_nur_bei_antwort haelt correct fuer weiss_nicht/leer
--    zwingend NULL, `correct is false` sortiert sie also allein schon aus. Die
--    abgabeart-Bedingung steht trotzdem da — sie schreibt die Absicht hin,
--    statt sie einem Constraint zu ueberlassen, der eines Tages fallen kann.
--  * LEFT JOIN auf fehlbild_labels, nie INNER. known_errors ist bewusst
--    schemafrei (A11) — ein Slug kann in acceptance stehen, ohne dass A20 ihn
--    kennt. Der generische Marker '__known__' aus der Array-Form von
--    known_errors ist genau so ein Fall und steht per Bauart nie in der
--    Registry. Ein INNER JOIN wuerde diese Zeilen verschwinden lassen: das
--    Fehlbild waere weg, statt als "Label fehlt" sichtbar zu sein. Fehlende
--    Slugs sind ein Befund fuer Lena, kein Grund zum Schweigen.


-- ── RPC 1: lsa_fehlbild_report — operative Sicht fuer den Coach ─────────────
--
-- Nach Skill gruppiert: der Coach arbeitet an einem Skill, nicht an einer
-- Sitzung. `anteil` ist der Anteil an den falschen Antworten DIESES Skills —
-- "3 von 8 Fehlern in Bruechen sind derselbe Denkfehler" ist die Zahl, die eine
-- Foerderentscheidung traegt, nicht die absolute Anzahl.
--
-- Falsche Antworten OHNE Slug bekommen eine eigene Zeile (slug null,
-- klartext 'nicht zugeordnet'). Sie stillschweigend wegzulassen wuerde jeden
-- Anteil aufblaehen und die Luecke der Registry unsichtbar machen — genau die
-- Luecke, die Lena sehen muss.
--
-- Aufgaben ohne skill_key erscheinen mit skill_key null (aufsteigend sortiert
-- also am Ende). Nicht ausblenden: ein Fehler ohne Skill-Zuordnung ist ein
-- Fehler.

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
         case when g.slug is null then 'nicht zugeordnet' else l.klartext end,
         g.n,
         -- Anteil als Bruchteil 0..1, auf 4 Stellen gerundet. Gerundete
         -- Anteile summieren sich nicht zwingend exakt auf 1 — massgeblich
         -- ist `anzahl`.
         round(g.n::numeric / g.n_skill, 4)
    from je_slug g
    left join public.fehlbild_labels l on l.slug = g.slug
   order by g.sk asc, g.n desc, g.slug asc
$$;


-- ── RPC 2: lsa_fehlbild_auswertung — diagnostische Sicht fuer den Report ────
--
-- Warum nicht dieselbe RPC mit einem Schalter: RPC 1 gruppiert nach Skill und
-- macht damit skilluebergreifende Muster unsichtbar. Dasselbe Fehlbild in
-- Bruechen UND in Gleichungen ist der staerkste Befund, den diese Daten
-- hergeben — bei RPC 1 erscheint er als zwei unabhaengige, je schwache Zeilen.
-- Der Elternreport braucht die Sitzungssicht.
--
-- Die Einstufung ist die einzige Schwelle im Haus und bewusst grob:
--   befund       = anzahl >= 2 AND aufgaben >= 2
--   beobachtung  = alles andere
-- Die zweite Bedingung traegt die Aussage. Zwei Treffer in DERSELBEN Aufgabe
-- koennen eine ungluecklich gewaehlte Zahl sein; zwei Treffer in ZWEI Aufgaben
-- sind ein Muster. `anzahl >= 2` allein waere die Regel, die man versehentlich
-- schreibt — die PRUEFUNG haelt dagegen (Fall 3).
--
-- Zeilen ohne Slug fehlen hier absichtlich (anders als bei RPC 1): "nicht
-- zugeordnet" ist kein Fehlbild und liesse sich nicht sinnvoll einstufen. Die
-- Luecke steht in RPC 1, wo sie hingehoert.

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
         l.klartext,
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


-- ── Grants ──────────────────────────────────────────────────────────────────
--
-- Muster A21: Postgres grantet neuen Funktionen automatisch an PUBLIC. Erst
-- wegnehmen, dann gezielt geben — sonst betraete ein anon-Aufruf die Funktion
-- ueberhaupt. lsa_responses hat kein anon/authenticated-Grant; diese beiden
-- SECURITY-DEFINER-RPCs sind der einzige Lesepfad auf fehlbild_slug.
--
-- GRENZE, bewusst und benannt: die RPCs pruefen die Rolle nicht selbst und
-- binden nicht an den Besitz der Sitzung. Wer eine Sitzungs-ID hat und
-- angemeldet ist, sieht deren Fehlbilder. Das entspricht dem Auftrag; eine
-- Bindung an lsa_may_act_for (wie lsa_finish sie hat) waere die naechste Stufe
-- und gehoert in einen eigenen Schritt, nicht nebenbei hier hinein.
-- Loesungsdaten (task_solutions.acceptance, correct_answers) verlassen die
-- Funktionen nicht — nur Slug, Klartext und Zaehlungen.

revoke execute on function public.lsa_fehlbild_report(uuid)      from public;
revoke execute on function public.lsa_fehlbild_auswertung(uuid)  from public;

grant execute on function public.lsa_fehlbild_report(uuid)     to authenticated, service_role;
grant execute on function public.lsa_fehlbild_auswertung(uuid) to authenticated, service_role;

comment on function public.lsa_fehlbild_report(uuid) is
  'AF2 Coach-Sicht: Fehlbilder einer LSA-Sitzung nach Skill gruppiert '
  '(skill_key, fehlbild_slug, klartext, anzahl, anteil an den Falschantworten '
  'des Skills). Falschantworten ohne Slug erscheinen als eigene Zeile mit '
  'klartext ''nicht zugeordnet''. weiss_nicht/leer zaehlen nicht als falsch.';

comment on function public.lsa_fehlbild_auswertung(uuid) is
  'AF2 Report-Sicht: Fehlbilder einer LSA-Sitzung ueber alle Skills hinweg. '
  'einstufung=''befund'' bei anzahl>=2 UND aufgaben>=2, sonst ''beobachtung''; '
  'skill_uebergreifend bei >=2 verschiedenen Skills. Slugs ohne Eintrag in '
  'fehlbild_labels erscheinen mit klartext null (kein INNER JOIN).';
