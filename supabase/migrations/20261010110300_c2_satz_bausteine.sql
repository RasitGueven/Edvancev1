-- C2.2 Bausteinkatalog fuer den Satz im Check-out (Bauauftrag Session-P1, Entscheidung 12,
-- offene-punkte-r1 Nr. 12, offene-punkte-c1 Nr. 3).
--
-- Der Coach sagt jedem Kind einen konkreten Satz. Vorschlaege kommen nur aus diesem festen Katalog,
-- nie als freier KI-Text. Bausteine loben Arbeit und Weg, nie das Richtig-Haben, und nennen keine
-- Zahlen zu Quoten. Platzhalter: {vorname}, {skill} (meistgeuebter Skill der Kernarbeit), {anzahl}
-- (bearbeitete Aufgaben). Der Katalog unten ist ein Vorschlag zur Pruefung durch Rasit und Fatih.
--
-- satz_vorschlaege(p_session_id, p_student_id): regelbasiert aus dem Tag des Kindes, zwei Vorschlaege
-- aus zwei verschiedenen Anlaessen (Rangfolge unten), sonst mit 'allgemein' aufgefuellt. Innerhalb
-- eines Anlasses waehlt ein fester Versatz je Kind und Session, damit nicht alle denselben Satz bekommen.
-- Rechte: Coach der Session oder Admin (session_kind_pruefen); im Testlauf erlaubt.

create table public.session_satz_bausteine (
  id           uuid primary key default gen_random_uuid(),
  anlass       text not null check (anlass in ('mastery', 'erklaerung', 'dran_geblieben', 'hinweise',
                                               'selbststaendig', 'exit', 'geuebt', 'allgemein')),
  text         text not null check (length(btrim(text)) between 10 and 300),
  aktiv        boolean not null default true,
  reihenfolge  int not null default 1 check (reihenfolge >= 1),
  angelegt_am  timestamptz not null default now(),
  geaendert_am timestamptz,
  constraint session_satz_bausteine_platzhalter check (
    regexp_replace(text, '\{(vorname|skill|anzahl)\}', '', 'g') !~ '[{}]'),
  -- Keine Quoten und kein Lob fuers Richtig-Haben (Entscheidung 12); Zahlen nur ueber {anzahl}.
  constraint session_satz_bausteine_ohne_quote check (
    text !~ '[0-9%]' and text !~* '(prozent|\mrichtig|\mfalsch|\mfehler)'),
  constraint session_satz_bausteine_eindeutig unique (anlass, reihenfolge)
);

comment on table public.session_satz_bausteine is
  'C2: Bausteinkatalog fuer den Satz des Coaches im Check-out (Entscheidung 12). Lesen nur ueber satz_vorschlaege; pflegen nur Admin.';

alter table public.session_satz_bausteine enable row level security;
create policy session_satz_bausteine_admin on public.session_satz_bausteine
  for all using (coalesce(public.get_my_role(), '') = 'admin')
  with check (coalesce(public.get_my_role(), '') = 'admin');
revoke all on public.session_satz_bausteine from public, anon, authenticated;
grant select, insert, update on public.session_satz_bausteine to authenticated;

insert into public.session_satz_bausteine (anlass, reihenfolge, text) values
  ('mastery', 1, 'Du hast mir {skill} heute ganz allein erklärt. Das zeigt, dass du es wirklich verstanden hast.'),
  ('mastery', 2, 'Wie du deinen Weg bei {skill} erklärt hast, war klar und ruhig. Darauf kannst du bauen.'),
  ('erklaerung', 1, 'Du hast dich heute in {skill} neu hineingedacht und bist drangeblieben, bis es klar war.'),
  ('erklaerung', 2, 'Bei {skill} hast du dir die Erklärung genau angeschaut und es dann selbst ausprobiert. Genau so lernt man Neues.'),
  ('dran_geblieben', 1, 'Als es bei {skill} gehakt hat, hast du nicht aufgegeben, sondern einen neuen Anlauf genommen.'),
  ('dran_geblieben', 2, 'Du bist heute drangeblieben, auch als es schwierig wurde. Das bringt dich am meisten weiter.'),
  ('hinweise', 1, 'Du hast dir Hilfe geholt, als du sie gebraucht hast, und dann selbst weitergemacht. Das ist klug.'),
  ('hinweise', 2, 'Du hast die Hinweise gut genutzt und daraus deinen eigenen Weg gemacht.'),
  ('selbststaendig', 1, 'Du hast heute {anzahl} Aufgaben selbstständig durchgearbeitet und dir deinen Weg selbst gesucht.'),
  ('selbststaendig', 2, 'Bei {skill} hast du heute allein Schritt für Schritt gearbeitet. Mach genau so weiter.'),
  ('exit', 1, 'Bei den Abschlussaufgaben hast du dir Zeit genommen und sauber gearbeitet.'),
  ('exit', 2, 'Du hast die Abschlussaufgaben konzentriert bearbeitet, auch am Ende der Stunde noch.'),
  ('geuebt', 1, 'Du hast heute konzentriert an {skill} gearbeitet. Das bringt dich weiter.'),
  ('geuebt', 2, '{anzahl} Aufgaben zu {skill} in einer Stunde: Da steckt viel Arbeit drin.'),
  ('allgemein', 1, 'Du hast heute gut mitgearbeitet, {vorname}. Ich freue mich auf das nächste Mal.'),
  ('allgemein', 2, 'Du warst heute konzentriert bei der Sache. Das merkt man an deiner Arbeit.'),
  ('allgemein', 3, 'Du hast heute deinen Rechenweg aufgeschrieben. So kann man gut sehen, wie du denkst.');

create function public.satz_vorschlaege(p_session_id uuid, p_student_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_skill    text;
  v_label    text;
  v_vorname  text;
  v_anzahl   int;
  v_hinweise int;
  v_anlaesse text[] := '{}';
  v_versatz  bigint := abs(hashtext(p_session_id::text || p_student_id::text)::bigint);
  v_erg      jsonb := '[]';
  v_mastery  text;
  v_a        text;
  b          record;
begin
  perform public.session_kind_pruefen(p_session_id, p_student_id, 'satz_vorschlaege');

  -- Meistgeuebter Skill der Kernarbeit (ohne eingemischte Aufgaben), sonst des ganzen Tages.
  select t.skill_key into v_skill
    from public.session_antworten r join public.tasks t on t.id = r.task_id
   where r.session_id = p_session_id and r.student_id = p_student_id and t.skill_key is not null
   group by t.skill_key
   order by count(*) filter (where r.phase = 'kern' and not r.eingemischt) desc, count(*) desc, t.skill_key
   limit 1;
  v_label := case when v_skill is not null then public.session_label(v_skill) end;
  v_vorname := (select coalesce(nullif(btrim(l.first_name), ''), nullif(split_part(btrim(l.full_name), ' ', 1), ''))
                  from public.leads l
                 where l.id = public.session_lead_von_kind(p_student_id));
  select count(distinct r.task_id) into v_anzahl
    from public.session_antworten r where r.session_id = p_session_id and r.student_id = p_student_id;
  select count(*) into v_hinweise
    from public.session_ereignisse e
   where e.session_id = p_session_id and e.student_id = p_student_id and e.typ = 'hinweis'
     and (e.payload ->> 'geliefert')::boolean;

  -- Anlaesse in Rangfolge. Mastery mit dem bestaetigten Skill.
  select public.session_label(p.skill_key) into v_mastery
    from public.lernpfad_protokoll p
   where p.session_id = p_session_id and p.student_id = p_student_id and p.aktion = 'mastery'
     and p.neu ->> 'stand_coach' = 'gemeistert'
   order by p.am desc limit 1;
  if v_mastery is not null then
    v_anlaesse := array_append(v_anlaesse, 'mastery');
    v_label := v_mastery;
  end if;
  if exists (select 1 from public.erklaer_fortschritt f where f.session_id = p_session_id
              and f.student_id = p_student_id and f.ergebnis = 'richtig') then
    v_anlaesse := array_append(v_anlaesse, 'erklaerung');
    if v_mastery is null then
      v_label := (select public.session_label(k.skill_key) from public.erklaer_fortschritt f
                    join public.erklaer_kernidee k on k.id = f.kernidee_id
                   where f.session_id = p_session_id and f.student_id = p_student_id order by f.id desc limit 1);
    end if;
  end if;
  -- Nach einer falschen Antwort spaeter am selben Skill wieder richtig.
  if exists (select 1 from public.session_antworten f join public.tasks tf on tf.id = f.task_id
               join public.session_antworten r on r.session_id = f.session_id and r.student_id = f.student_id
                                              and r.zeit > f.zeit and r.ergebnis = 'richtig'
               join public.tasks tr on tr.id = r.task_id and tr.skill_key = tf.skill_key
              where f.session_id = p_session_id and f.student_id = p_student_id and f.ergebnis = 'falsch') then
    v_anlaesse := array_append(v_anlaesse, 'dran_geblieben');
  end if;
  if v_hinweise > 0 then
    v_anlaesse := array_append(v_anlaesse, 'hinweise');
  elsif v_anzahl > 0 then
    v_anlaesse := array_append(v_anlaesse, 'selbststaendig');
  end if;
  if exists (select 1 from public.session_antworten r where r.session_id = p_session_id
              and r.student_id = p_student_id and r.phase = 'checkout') then
    v_anlaesse := array_append(v_anlaesse, 'exit');
  end if;
  if v_anzahl > 0 then
    v_anlaesse := array_append(v_anlaesse, 'geuebt');
  end if;
  v_anlaesse := v_anlaesse || array['allgemein', 'allgemein'];

  foreach v_a in array v_anlaesse loop
    exit when jsonb_array_length(v_erg) >= 2;
    select x.id, x.anlass, x.text into b
      from (select z.*, count(*) over () as n, row_number() over (order by z.reihenfolge) - 1 as i
              from public.session_satz_bausteine z
             where z.aktiv and z.anlass = v_a
               and (v_label is not null or z.text not like '%{skill}%')
               and (v_vorname is not null or z.text not like '%{vorname}%')
               and not exists (select 1 from jsonb_array_elements(v_erg) e where (e ->> 'baustein_id')::uuid = z.id)
               and (v_a = 'allgemein' or not exists (select 1 from jsonb_array_elements(v_erg) e
                                                       where e ->> 'anlass' = v_a))) x
     where x.i = v_versatz % x.n;
    if found then
      v_erg := v_erg || jsonb_build_array(jsonb_build_object(
        'baustein_id', b.id, 'anlass', b.anlass,
        'text', replace(replace(replace(b.text, '{skill}', coalesce(v_label, '')), '{vorname}', coalesce(v_vorname, '')),
                        '{anzahl}', v_anzahl::text)));
    end if;
  end loop;
  return v_erg;
end;
$$;

comment on function public.satz_vorschlaege(uuid, uuid) is
  'C2: zwei Satzvorschlaege fuer den Check-out aus aktiven Bausteinen, regelbasiert (Entscheidung 12). Coach der Session oder Admin.';

revoke all on function public.satz_vorschlaege(uuid, uuid) from public, anon, authenticated;
grant execute on function public.satz_vorschlaege(uuid, uuid) to authenticated;
