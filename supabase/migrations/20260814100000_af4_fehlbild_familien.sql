-- AF4 — Fehlbild-Familien: die Buendelungsebene fuer den Elternreport.
--
-- Ausgangslage (Fehlbild-Audit 2026-08-14, siehe docs/):
--   * 73 Slugs stehen in acceptance->known_errors, 666 Falschwert-Eintraege
--     ueber 302 Aufgaben. fehlbild_labels ist bis heute eine Slug-Registry;
--     AF3 hat genau ZWEI Klartexte als LLM-Entwurf hinterlegt.
--   * Die Slugs sind auf Aufgabenebene geschnitten, nicht auf Gespraechsebene:
--     vorzeichen_ignoriert, betrag_fehler, vorzeichen_beim_umstellen,
--     seiten_verwechselt und falsches_vorzeichen_beim_zusammenfuehren sind fuer
--     einen Coach fuenf unterscheidbare Befunde — fuer Eltern sind sie EIN Satz.
--   * Ohne Buendelung liest ein Elternreport fuenf Absaetze ueber dieselbe
--     Sache. Das wirkt wie fuenf Probleme, wo eines ist.
--
-- Entscheidung: eine Ebene DARUEBER statt Slugs zusammenzulegen. Die Slugs
-- bleiben unangetastet (die Coach-Diagnostik braucht ihre Feinheit), sie
-- bekommen ein Familien-Etikett. Der Elternreport gruppiert auf die Familie und
-- liest EINEN abgenommenen Satz vor.
--
-- ----------------------------------------------------------------------------
-- Die Umwidmung von fehlbild_labels.klartext — bewusst und mit Folge
-- ----------------------------------------------------------------------------
-- AF3 hat klartext als ELTERNSPRACHE angelegt ("Beim Umrechnen einmal statt
-- mehrfach vergroessert"). Mit AF4 wandert die Elternsprache eine Ebene hoch in
-- fehlbild_familien.elterntext, und klartext wird der COACH-Satz — kurz,
-- fachlich, ohne Ruecksicht auf Elternsprache ("x-Terme richtig
-- zusammengefasst, die Konstante addiert statt subtrahiert").
--
-- Damit darf klartext die Eltern-RPC nicht mehr passieren. lsa_fehlbild_-
-- auswertung ist die Quelle des Elternreports (src/lib/supabase/lsaReport.ts →
-- components/edvance/report/ReportBody.tsx); wuerde sie den Coach-Satz weiter
-- ausgeben, stuende nach dem naechsten Apply Fachsprache im Elterngespraech —
-- genau das, was INV-4.3 verhindert. Deshalb VERLIERT die Auswertung ihre
-- klartext-Spalte und gewinnt familie + familie_elterntext (Teil 5).
-- lsa_fehlbild_report (Coach-Sicht) bleibt unberuehrt und behaelt klartext.
--
-- KEIN begin/commit (der Runner klammert).


-- ── 1. fehlbild_familien ────────────────────────────────────────────────────
--
-- Vier Spalten, keine mehr. Die Tabelle traegt einen Satz und dessen Abnahme —
-- alles andere (welche Slugs dazugehoeren) steht auf fehlbild_labels.familie
-- und wird nicht doppelt gefuehrt.
--
-- Die Abnahme-Schranke ist woertlich die aus AF3: freigegeben_am null heisst
-- Entwurf und wird nirgends ausgeliefert. Wieder KEIN Default und KEIN NOT
-- NULL — der Normalzustand einer neuen Familie ist "nicht abgenommen", und ein
-- Default wuerde die Schranke beim naechsten Zuwachs stillschweigend aushebeln.

create table if not exists public.fehlbild_familien (
  schluessel      text primary key,
  elterntext      text,
  freigegeben_am  timestamptz,
  freigegeben_von uuid references public.profiles(id)
);

comment on table public.fehlbild_familien is
  'AF4 Buendelungsebene ueber fehlbild_labels. Mehrere Slugs derselben Art '
  'ergeben fuer Eltern EINEN Satz (elterntext). schluessel ist ein interner '
  'Gruppierungsschluessel wie der Slug — er ist KEIN Anzeigetext und darf '
  'Eltern nie gezeigt werden.';

comment on column public.fehlbild_familien.elterntext is
  'AF4: der eine Satz, den der Elternreport fuer die ganze Familie vorliest. '
  'Elternsprache (siezen, kein Defizit-Vokabular, kein Fachjargon) — die '
  'Regeln stehen in src/test/invariants/inv4-eltern-sprache.test.ts.';

comment on column public.fehlbild_familien.freigegeben_am is
  'AF4 Abnahme-Schranke, woertlich wie fehlbild_labels.freigegeben_am (AF3). '
  'NULL = elterntext ist unabgenommener Entwurf und wird von '
  'lsa_fehlbild_auswertung als NULL ausgeliefert. Abnahme: update '
  'fehlbild_familien set freigegeben_am = now(), freigegeben_von = '
  '''<profil-uuid>'' where schluessel = ''<familie>'';';

comment on column public.fehlbild_familien.freigegeben_von is
  'AF4: wer abgenommen hat (profiles.id). Belegt die Abnahme, steuert sie '
  'nicht — massgeblich ist allein freigegeben_am.';

-- RLS woertlich wie fehlbild_labels (A20): Leserecht admin/coach. Die Tabelle
-- ist Registry-Inhalt, kein Schuelerdatum — aber sie enthaelt Saetze ueber
-- Denkfehler, und die gehoeren nicht in die Hand eines Schueler-Tokens.
alter table public.fehlbild_familien enable row level security;
drop policy if exists fehlbild_familien_read on public.fehlbild_familien;
create policy fehlbild_familien_read on public.fehlbild_familien
  for select using (public.get_my_role() = any (array['admin', 'coach']));
grant select on public.fehlbild_familien to authenticated;


-- ── 2. fehlbild_labels.familie ──────────────────────────────────────────────
--
-- nullable: die Registry hat 73 Slugs, bestueckt werden 20. Ein Slug ohne
-- Familie ist der Normalfall, nicht ein Fehler — er erscheint im Coachreport
-- wie bisher und im Elternreport ohne Buendelsatz.
--
-- FK mit `on update cascade`: der Schluessel ist ein sprechender Text. Wird er
-- je umbenannt, soll die Zuordnung mitwandern statt zu brechen. KEIN
-- `on delete cascade` — eine geloeschte Familie darf keine Labels mitnehmen.

alter table public.fehlbild_labels
  add column if not exists familie text;

alter table public.fehlbild_labels
  drop constraint if exists fehlbild_labels_familie_fkey;
alter table public.fehlbild_labels
  add constraint fehlbild_labels_familie_fkey
  foreign key (familie) references public.fehlbild_familien(schluessel)
  on update cascade;

comment on column public.fehlbild_labels.familie is
  'AF4: Buendel fuer den Elternreport (fehlbild_familien.schluessel). NULL = '
  'noch keiner Familie zugeordnet; der Slug erscheint dann ohne Buendelsatz. '
  'Interner Schluessel, kein Anzeigetext.';

comment on column public.fehlbild_labels.klartext is
  'AF4: der COACH-Satz zum Slug (kurz, fachlich). Bis AF3 war diese Spalte in '
  'Elternsprache gefuehrt — die ist mit AF4 nach fehlbild_familien.elterntext '
  'gewandert. Wird nur von lsa_fehlbild_report ausgegeben (Coach-Sicht), NICHT '
  'von lsa_fehlbild_auswertung (Eltern-Pfad). Hinter der Abnahme-Schranke '
  'freigegeben_am (AF3).';


-- ── 3. Die fuenf Familien ───────────────────────────────────────────────────
--
-- Der Schnitt folgt dem Denkfehler, nicht dem Stoffgebiet: vorzeichen und
-- gleichungen_umformen liegen beide im Gleichungs-Fundament, sind aber zwei
-- verschiedene Sachen — einmal kippt das Vorzeichen, einmal fehlt ein Schritt.
-- Ein Coach, der das Falsche uebt, verliert eine Sitzung.
--
-- Der Freigeber steht als UNTERABFRAGE, nicht als hartkodierte UUID:
-- tools/schema-snapshot.sh baut eine LEERE Datenbank aus test-grundlage.sql +
-- Migrationen. Dort gibt es kein Profil, und eine hartkodierte UUID wuerde am
-- FK auf profiles(id) scheitern — der Schnappschuss waere nicht erzeugbar.
-- Auf einer Datenbank ohne Admin-Profil bleibt freigegeben_von null; die
-- Schranke haengt allein an freigegeben_am, nicht an freigegeben_von.
--
-- ACHTUNG: freigegeben_am wird hier GESETZT. Das ist die Abweichung von AF3,
-- wo die Entwuerfe bewusst unabgenommen liegen blieben. Diese fuenf Saetze und
-- die 20 Coach-Saetze unten sind von Rasit abgenommen; die FACHLICHE Abnahme
-- durch Lena steht aus (siehe PR-Text). Wer sie zurueckziehen will:
--   update public.fehlbild_familien set freigegeben_am = null, freigegeben_von = null;

insert into public.fehlbild_familien (schluessel, elterntext, freigegeben_am, freigegeben_von)
select f.schluessel,
       f.elterntext,
       now(),
       (select p.id from public.profiles p where p.role = 'admin' order by p.created_at limit 1)
  from (values
    ('vorzeichen',
     'Ihr Kind rechnet richtig, verliert beim Rechnen mit negativen Zahlen aber '
     'das Vorzeichen – das Ergebnis kippt ins Gegenteil.'),
    ('gleichungen_umformen',
     'Ihr Kind kennt das Verfahren, überspringt beim Umformen aber Schritte '
     'oder wendet sie in der falschen Richtung an.'),
    ('rechenreihenfolge',
     'Ihr Kind rechnet der Reihe nach von links nach rechts, statt auf die '
     'Rechenreihenfolge zu achten.'),
    ('einheiten_massstab',
     'Ihr Kind erkennt die Aufgabe, rechnet beim Umwandeln aber mit dem '
     'falschen Faktor oder in die falsche Richtung.'),
    ('sachaufgaben',
     'Ihr Kind rechnet sauber, wählt bei Textaufgaben aber den falschen '
     'Rechenweg für die beschriebene Situation.')
  ) as f(schluessel, elterntext)
on conflict (schluessel) do nothing;


-- ── 4. Die 20 Fehlbilder: Familie + Coach-Klartext ──────────────────────────
--
-- UPSERT, nicht UPDATE. Auf der Live-Datenbank stehen alle 20 Slugs schon in
-- der Registry (A20 hat sie aus acceptance->known_errors geseedet) — dort greift
-- also der do-update-Zweig. Auf einer LEEREN Datenbank ist die Registry leer:
-- A20 seedet aus task_solutions, und tools/schema-snapshot.sh baut ohne Inhalte.
-- Ein reines UPDATE haette dort nichts getroffen und die Kontrollzaehlung unter
-- Teil 6 waere nicht erzeugbar gewesen. Mit dem Upsert traegt die Migration ihre
-- 20 Zeilen selbst und ist auf jeder Datenbank deterministisch — genau wie AF3
-- den fehlenden Slug falsche_operation selbst nachgetragen hat.
--
-- `erklaerung` wird bewusst NICHT angetastet: linearer_faktor und
-- faktor_zehn_daneben tragen ab hier den COACH-Satz als klartext, behalten aber
-- die AF3-Elternprosa in erklaerung. Die verlaesst die Datenbank ueber keine RPC
-- und wird beim naechsten Durchgang mit Lena aufgeraeumt (offener Punkt im PR).

insert into public.fehlbild_labels (slug, familie, klartext, freigegeben_am, freigegeben_von)
select v.slug,
       v.familie,
       v.klartext,
       now(),
       (select p.id from public.profiles p
         where p.role = 'admin' order by p.created_at limit 1)
  from (values
  -- Familie vorzeichen — das Vorzeichen kippt, der Rechenweg stimmt
  ('vorzeichen_ignoriert', 'vorzeichen',
   'Lässt die Minuszeichen weg und addiert die Beträge.'),
  ('betrag_fehler', 'vorzeichen',
   'Betrag richtig, Vorzeichen des Ergebnisses gekippt.'),
  ('vorzeichen_beim_umstellen', 'vorzeichen',
   'Betrag richtig, das Minus des Koeffizienten bleibt am Ergebnis hängen.'),
  ('seiten_verwechselt', 'vorzeichen',
   'Subtrahiert in umgekehrter Reihenfolge, Ergebnis mit falschem Vorzeichen.'),
  ('falsches_vorzeichen_beim_zusammenfuehren', 'vorzeichen',
   'x-Terme richtig zusammengefasst, die Konstante addiert statt subtrahiert.'),

  -- Familie gleichungen_umformen — das Verfahren ist da, ein Schritt fehlt
  ('division_vergessen', 'gleichungen_umformen',
   'Umformung richtig, der letzte Schritt (Division durch den Koeffizienten) fehlt.'),
  ('b_ignoriert', 'gleichungen_umformen',
   'Teilt sofort, ohne die Konstante vorher wegzurechnen.'),
  ('addiert_statt_subtrahiert', 'gleichungen_umformen',
   'Addiert die Konstante auf beiden Seiten statt sie abzuziehen.'),
  ('falsche_gegenoperation', 'gleichungen_umformen',
   'Wiederholt die im Term sichtbare Rechenart statt sie umzukehren.'),
  ('variablen_nicht_zusammengefuehrt', 'gleichungen_umformen',
   'Teilt durch den linken Koeffizienten statt durch die Differenz beider.'),

  -- Familie rechenreihenfolge — von links nach rechts statt Punkt vor Strich
  ('vorrang_ignoriert', 'rechenreihenfolge',
   'Rechnet strikt von links nach rechts, Punkt vor Strich ignoriert.'),
  ('mult_add_verwechslung', 'rechenreihenfolge',
   'Führt die Strichoperation als Punktoperation aus.'),

  -- Familie einheiten_massstab — falscher Faktor beim Umwandeln
  ('richtung_vertauscht', 'einheiten_massstab',
   'Teilt durch die Maßstabszahl statt zu multiplizieren.'),
  ('faktor_zehn_daneben', 'einheiten_massstab',
   'Ergebnis um den Faktor 10 daneben, in beide Richtungen.'),
  ('linearer_faktor', 'einheiten_massstab',
   'Nutzt den linearen Umrechnungsfaktor, wo der quadrierte gilt.'),
  ('einheit_uebersprungen', 'einheiten_massstab',
   'Rechnet gar nicht um, die Ausgangszahl bleibt stehen.'),

  -- Familie sachaufgaben — falscher Rechenweg fuer die beschriebene Situation
  ('dezimalverschiebung', 'sachaufgaben',
   'Multipliziert mit der Prozentzahl, ohne durch 100 zu teilen.'),
  ('antiproportional_verwechselt', 'sachaufgaben',
   'Proportional und antiproportional vertauscht.'),
  ('einheit_verrutscht', 'sachaufgaben',
   'Multipliziert den Grundwert direkt mit der neuen Anzahl, der Zwischenschritt fehlt.'),
  ('falsche_richtung', 'sachaufgaben',
   'Rechnet den Kehrwert oder verschiebt das Komma um zwei Stellen.')
) as v(slug, familie, klartext)
on conflict (slug) do update set
  familie         = excluded.familie,
  klartext        = excluded.klartext,
  freigegeben_am  = excluded.freigegeben_am,
  freigegeben_von = excluded.freigegeben_von;


-- ── 5. teilgekuerzt bleibt UNBESTUECKT ──────────────────────────────────────
--
-- Der Slug beschreibt etwas anderes als er tut: in allen 21 belegten Faellen
-- (bruch_add, Klasse 6) ist das Ergebnis GAR NICHT gekuerzt, nicht teilweise —
-- 1/4 + 1/12 kommt als 4/12 statt 1/3, 5/12 + 1/4 als 8/12 statt 2/3.
--
-- Nicht umbenannt: der Slug steht in 21 acceptance->known_errors-Objekten und
-- in lsa_responses. Ein Rename ist eine eigene Migration mit Datenmitzug, kein
-- Nebenprodukt einer Bestueckung. Auch keine Familie und kein Klartext — ein
-- Etikett auf einen falsch benannten Befund kleben macht ihn schwerer zu
-- finden, nicht leichter. Offener Punkt im PR.


-- ── 6. Kontrollzaehlung ─────────────────────────────────────────────────────
--
-- Die Bestueckung oben ist ein UPDATE ueber eine Werteliste. Trifft ein Slug
-- keine Zeile (Tippfehler, Registry-Drift), passiert schlicht nichts — still.
-- Diese Pruefung macht daraus einen Abbruch. Sie laeuft IN der Migration, weil
-- sie den DATENSTAND dieser Migration belegt; die Strukturpruefungen stehen in
-- supabase/checks/fehlbild_familien.PRUEFUNG.sql.

do $$
declare
  v_fam   integer;
  v_lab   integer;
  v_waise integer;
begin
  select count(*) into v_fam from public.fehlbild_familien
   where freigegeben_am is not null;
  if v_fam <> 5 then
    raise exception 'AF4: % freigegebene Familien, erwartet 5', v_fam;
  end if;

  select count(*) into v_lab from public.fehlbild_labels
   where familie is not null and klartext is not null and freigegeben_am is not null;
  if v_lab <> 20 then
    raise exception 'AF4: % bestueckte Fehlbilder, erwartet 20 — ein Slug aus '
                    'der Werteliste steht nicht in der Registry', v_lab;
  end if;

  -- Der FK verhindert eine Familie, die es nicht gibt. Diese Zaehlung faengt
  -- den umgekehrten Fall: eine Familie ohne ein einziges Label.
  select count(*) into v_waise from public.fehlbild_familien f
   where not exists (select 1 from public.fehlbild_labels l where l.familie = f.schluessel);
  if v_waise <> 0 then
    raise exception 'AF4: % Familie(n) ohne zugeordnetes Fehlbild', v_waise;
  end if;

  if exists (select 1 from public.fehlbild_labels
              where slug = 'teilgekuerzt' and (familie is not null or klartext is not null)) then
    raise exception 'AF4: teilgekuerzt wurde bestueckt — der Slug ist bewusst offen';
  end if;

  raise notice 'AF4: 5 Familien, 20 Fehlbilder bestueckt und freigegeben';
end $$;


-- ── 7. lsa_fehlbild_auswertung: klartext raus, Familie rein ─────────────────
--
-- SIGNATURWECHSEL, deshalb drop statt `create or replace`: Postgres laesst den
-- Rueckgabetyp einer bestehenden Funktion nicht ersetzen (42P13). Der drop
-- nimmt die GRANTS mit — sie werden unten wieder gesetzt, sonst faellt die RPC
-- fuer authenticated aus.
--
-- Drei Aenderungen gegenueber AF3, alles andere ist woertlich uebernommen (die
-- Begruendungen zu Einstufung, LEFT JOIN und "was falsch heisst" stehen in AF2
-- und werden hier nicht wiederholt):
--
--   1. klartext ENTFAELLT. Er ist ab AF4 der Coach-Satz und hat im Eltern-Pfad
--      nichts zu suchen (Kopf dieser Datei).
--   2. familie kommt dazu, UNGEFILTERT. Das ist ein Gruppierungsschluessel wie
--      der Slug, kein Text — der Report buendelt darauf. Ihn hinter die Abnahme
--      zu stellen wuerde die Buendelung von der Textabnahme abhaengig machen:
--      ohne Freigabe fielen die Zeilen auseinander statt still zusammenzu-
--      bleiben. Wer familie rendert, verstoesst gegen INV-4.3 wie bei einem
--      rohen Slug.
--   3. familie_elterntext kommt dazu, HINTER DER SCHRANKE. Der eine Satz fuer
--      Eltern, null solange fehlbild_familien.freigegeben_am null ist.
--
-- Der Elternreport gruppiert also selbst: gleiche familie -> eine Karte, Text
-- aus familie_elterntext, Belegzahlen aus der Summe der Zeilen.

drop function if exists public.lsa_fehlbild_auswertung(uuid);

create function public.lsa_fehlbild_auswertung(p_session_id uuid)
returns table (
  fehlbild_slug       text,
  familie             text,
  familie_elterntext  text,
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
         l.familie,
         case when fam.freigegeben_am is null then null else fam.elterntext end,
         g.n,
         g.n_aufgaben,
         g.sk_liste,
         (g.n_skills >= 2),
         case when g.n >= 2 and g.n_aufgaben >= 2 then 'befund' else 'beobachtung' end
    from je_slug g
    left join public.fehlbild_labels l   on l.slug       = g.slug
    -- Zweiter LEFT JOIN aus demselben Grund wie der erste: ein Slug ohne
    -- Familie muss seine Zeile behalten. INNER JOIN liesse 53 der 73 Slugs
    -- aus dem Report verschwinden.
    left join public.fehlbild_familien fam on fam.schluessel = l.familie
   -- Befunde zuerst, darin das haeufigste — der Report liest von oben.
   -- Innerhalb dessen nach Familie, damit gleiche Buendel beieinander stehen
   -- und der Konsument sie in einem Durchlauf zusammenfassen kann.
   order by (case when g.n >= 2 and g.n_aufgaben >= 2 then 0 else 1 end),
            g.n desc, l.familie asc nulls last, g.slug asc
$$;

revoke execute on function public.lsa_fehlbild_auswertung(uuid) from public;
grant execute on function public.lsa_fehlbild_auswertung(uuid) to authenticated, service_role;

comment on function public.lsa_fehlbild_auswertung(uuid) is
  'AF2/AF3/AF4 Eltern-Pfad: Fehlbilder einer LSA-Sitzung ueber alle Skills '
  'hinweg. einstufung=''befund'' bei anzahl>=2 UND aufgaben>=2, sonst '
  '''beobachtung''; skill_uebergreifend bei >=2 verschiedenen Skills. '
  'familie ist der Buendelschluessel (interner Schluessel, KEIN Anzeigetext); '
  'familie_elterntext ist der eine Satz fuer Eltern und null, solange '
  'fehlbild_familien.freigegeben_am null ist (AF4-Abnahme-Schranke). '
  'Gibt bewusst KEIN klartext aus — das ist ab AF4 der Coach-Satz und steht '
  'nur in lsa_fehlbild_report.';
