-- R5 — Erzählbausteine nachschärfen: jeder Elternpunkt bekommt eine Antwort,
--      und kein Text behauptet mehr eine Verteilung, die niemand gezählt hat.
--
-- Drei Befunde aus der Durchsicht der v2-Reports (2026-08-18):
--
--   1. Abschnitt 01 nannte bei einem Kind VIER Punkte (Grundlagen,
--      Textverständnis, Rechenwege, Konzentration). Der Schluss behandelte
--      zwei. Die anderen beiden standen unbeantwortet im Dokument — und ein
--      unbeantworteter Punkt liest sich wie ein stillschweigendes
--      "unauffällig".
--
--   2. Der Empfehlungstext sagte "Die Bereiche liegen dicht beieinander und
--      lassen sich zügig aufarbeiten." Die Lücken lagen in ZWEI Themenfamilien
--      (Terme, Geometrie & Größen). Derselbe Fehlertyp wie zuvor bei
--      "gebündelt in der Geometrie": eine Aussage über die Verteilung, ohne
--      sie zu prüfen. Der Text hing allein am Paket.
--
--   3. Die Aufzählung in Abschnitt 01 mischte Formen: "weil Sie Grundlagen
--      fehlen, Textverständnis, Rechenwege und Konzentration als
--      Schwierigkeiten sehen". "Grundlagen fehlen" ist ein Teilsatz, der Rest
--      sind Substantive.
--
-- ----------------------------------------------------------------------------
-- Warum FAZIT und WARUM erst jetzt in die Datenbank wandern
-- ----------------------------------------------------------------------------
-- R4 hat die Erzählbausteine in report_bausteine gelegt, Fazit und
-- Paketbegründung aber im Generator gelassen (scripts/report/paketTexte.ts) —
-- als Rest aus der Zeit davor. Solange sie nur am Paket hingen, fiel das nicht
-- auf. Mit der Fallunterscheidung nach Familienzahl werden es neun Texte je
-- Sorte, und die gehören dorthin, wo die Abnahme-Schranke steht.

begin;

-- ── 1. report_anlass_zuordnung: Anzeigename und Messbarkeit ─────────────────
--
-- Die Tabelle war bis R5 eine Zuordnung für DREI Punkte. Sie wird zur
-- vollständigen Registry aller sechs Werte, die das Intake-UI schreiben kann
-- (PARENT_WEAK_TOPICS in src/pages/admin/intake/intakeConstants.ts) — auch für
-- die, zu denen eine Lernstandsanalyse nichts sagen kann.

alter table public.report_anlass_zuordnung
  add column if not exists anzeigename text,
  add column if not exists messbar     boolean not null default true;

comment on column public.report_anlass_zuordnung.anzeigename is
  'R5: derselbe Punkt als Substantivgruppe, fuer die Aufzaehlung in Abschnitt '
  '01. weak_topics mischt Formen — "Grundlagen fehlen" ist ein Teilsatz, '
  '"Textverstaendnis" ein Substantiv. Der Anzeigename glaettet die Aufzaehlung, '
  'ohne den DB-Wert anzufassen, an dem die Zuordnung haengt.';

comment on column public.report_anlass_zuordnung.messbar is
  'R5: false = eine Lernstandsanalyse kann zu diesem Punkt grundsaetzlich '
  'nichts sagen (Konzentration, Pruefungsangst, Zeiteinteilung). Der Punkt '
  'bekommt trotzdem einen Satz — einen, der genau das ausspricht. Schweigen '
  'liest sich wie "unauffaellig".';

insert into public.report_anlass_zuordnung
  (thema, anzeigename, skill_keys, fehlbild_familien, strukturell, messbar)
values
  ('Textverständnis',   'Textverständnis',
   '{gleichung_modellieren}', '{sachaufgaben}', false, true),

  -- Kein Skill: die Skills heissen nach dem VERFAHREN (gleichung_beidseitig),
  -- nicht nach dessen Durchfuehrung. Ob der Rechenweg abbricht, steht in den
  -- Fehlbildern. gleichungen_umformen trifft es woertlich ("ueberspringt beim
  -- Umformen Schritte"), rechenreihenfolge deckt den zweiten Weg ab, auf dem
  -- ein Rechenweg kippt. vorzeichen bleibt bewusst draussen: ein verlorenes
  -- Minus ist ein Rechenfehler, kein falscher Weg.
  ('Rechenwege',        'Rechenwege',
   '{}', '{gleichungen_umformen,rechenreihenfolge}', false, true),

  ('Grundlagen fehlen', 'fehlende Grundlagen',
   '{}', '{}', true, true),

  -- Die drei ohne Messpfad. Keine Skill-Zuordnung waere hier eine Notluege:
  -- Ausgelassene Aufgaben oder Bearbeitungsdauern sind Verhaltensdeutungen auf
  -- ein bis zwei Datenpunkten, nicht Belege.
  ('Konzentration',     'Konzentration',     '{}', '{}', false, false),
  ('Prüfungsangst',     'Prüfungsangst',     '{}', '{}', false, false),
  ('Zeiteinteilung',    'Zeiteinteilung',    '{}', '{}', false, false)
on conflict (thema) do update
  set anzeigename       = excluded.anzeigename,
      skill_keys        = excluded.skill_keys,
      fehlbild_familien = excluded.fehlbild_familien,
      strukturell       = excluded.strukturell,
      messbar           = excluded.messbar;

-- Erst jetzt not null: die drei Bestandszeilen aus R4 haben oben ihren
-- Anzeigenamen bekommen.
alter table public.report_anlass_zuordnung
  alter column anzeigename set not null;


-- ── 2. Neue Bausteine ───────────────────────────────────────────────────────

insert into public.report_bausteine (schluessel, slot, fall, variante, text, freigegeben_am)
values

-- ── slot 'rueckbezug', Richtung 'offen' ────────────────────────────────────
--
-- Der Punkt IST messbar, diese Sitzung gibt aber nichts her — in keine
-- Richtung. Das ist NICHT dasselbe wie entlastend: In der Sitzung 920d00ae
-- tragen fuenf falsche Antworten null fehlbild_slug. Ein Slug entsteht nur,
-- wenn die gegebene Antwort auf ein katalogisiertes Muster passt; fehlt er, war
-- die Antwort bloss nicht katalogisiert. Der Satz sagt das, statt daraus einen
-- Freispruch zu machen.

('rueckbezug.rechenwege_offen.a', 'rueckbezug', 'rechenwege_offen', 'a',
 'Sie hatten die Rechenwege genannt. In dieser Analyse hat sich dazu kein wiederkehrendes Muster gezeigt — das heißt aber nicht, dass es keines gibt: Dafür waren es zu wenige Aufgaben. Der Coach schaut in den ersten Sitzungen gezielt darauf.',
 now()),
('rueckbezug.rechenwege_offen.b', 'rueckbezug', 'rechenwege_offen', 'b',
 'Zu den Rechenwegen, die Sie angesprochen haben: Aus dieser Analyse lässt sich dazu nichts ablesen — weder in die eine noch in die andere Richtung. Der Coach nimmt den Punkt in die ersten Sitzungen mit.',
 now()),

('rueckbezug.textverstaendnis_offen.a', 'rueckbezug', 'textverstaendnis_offen', 'a',
 'Sie hatten das Textverständnis genannt. In dieser Analyse kam dazu keine Aufgabe vor, aus der sich etwas ablesen ließe. Der Coach sieht sich den Bereich in den ersten Sitzungen an.',
 now()),
('rueckbezug.textverstaendnis_offen.b', 'rueckbezug', 'textverstaendnis_offen', 'b',
 'Zum Textverständnis, das Sie angesprochen haben: Diese Analyse gibt dazu nichts her. Wir prüfen es im Unterricht nach.',
 now()),

('rueckbezug.grundlagen_offen.a', 'rueckbezug', 'grundlagen_offen', 'a',
 'Sie hatten vermutet, dass Grundlagen fehlen. Unterhalb des aktuellen Themas ist in dieser Analyse zu wenig geprüft worden, um das zu beantworten. Der Coach geht die Ebenen darunter im Unterricht durch.',
 now()),
('rueckbezug.grundlagen_offen.b', 'rueckbezug', 'grundlagen_offen', 'b',
 'Zu Ihrer Vermutung, dass Grundlagen fehlen: Diese Analyse ist unterhalb des aktuellen Themas nicht weit genug gekommen, um dazu etwas zu sagen.',
 now()),


-- ── slot 'rueckbezug', Richtung 'nicht_messbar' ────────────────────────────
--
-- Konzentration, Pruefungsangst und Zeiteinteilung zeigen sich im Verhalten
-- ueber Wochen, nicht in zwanzig Aufgaben an einem Nachmittag. Der Satz sagt
-- das offen und verweist auf den Ort, an dem es sichtbar wird.

('rueckbezug.konzentration_nicht_messbar.a', 'rueckbezug', 'konzentration_nicht_messbar', 'a',
 'Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.',
 now()),
('rueckbezug.konzentration_nicht_messbar.b', 'rueckbezug', 'konzentration_nicht_messbar', 'b',
 'Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.',
 now()),

('rueckbezug.pruefungsangst_nicht_messbar.a', 'rueckbezug', 'pruefungsangst_nicht_messbar', 'a',
 'Zur Prüfungsangst sagt diese Analyse nichts. Sie war keine Prüfung, und ohne Prüfungssituation lässt sich dazu nichts beobachten. Der Coach spricht das in den ersten Sitzungen an.',
 now()),
('rueckbezug.pruefungsangst_nicht_messbar.b', 'rueckbezug', 'pruefungsangst_nicht_messbar', 'b',
 'Sie hatten die Prüfungsangst angesprochen. Dieser Termin war bewusst keine Prüfung — dazu kann er deshalb nichts zeigen. Der Coach nimmt den Punkt auf.',
 now()),

('rueckbezug.zeiteinteilung_nicht_messbar.a', 'rueckbezug', 'zeiteinteilung_nicht_messbar', 'a',
 'Zur Zeiteinteilung sagt diese Analyse nichts. Wie Ihr Kind sich eine Woche einteilt, zeigt sich im Lernalltag, nicht an einem Termin. Der Coach schaut in den ersten Sitzungen darauf.',
 now()),
('rueckbezug.zeiteinteilung_nicht_messbar.b', 'rueckbezug', 'zeiteinteilung_nicht_messbar', 'b',
 'Sie hatten die Zeiteinteilung angesprochen. Dazu kann ein einzelner Termin nichts beitragen — das wird über mehrere Wochen sichtbar. Der Coach hat es im Blick.',
 now()),


-- ── slot 'fazit' — nach Zahl der betroffenen Themenfamilien ────────────────
--
-- Bis R5 hing der Text am PAKET und behauptete eine Verteilung, die niemand
-- gezaehlt hatte. Der Fall traegt jetzt die Zahl der Familien, in denen
-- ueberhaupt eine Luecke liegt (src/lib/report/familien.ts, dieselbe Taxonomie
-- wie das Profil-Diagramm daneben). Ein Text, der "dicht beieinander" sagt,
-- existiert nur noch fuer den Fall, in dem das stimmt.
--
-- 'keine' deckt den Fall ab, dass alles Gepruefte traegt.

('fazit.keine.a', 'fazit', 'keine', 'a',
 'Das aktuelle Thema steht, und die Grundlagen darunter tragen. Wir halten dieses Niveau und arbeiten am kommenden Stoff weiter.',
 now()),
('fazit.keine.b', 'fazit', 'keine', 'b',
 'In den geprüften Bereichen hat sich nichts gezeigt, was Nacharbeit nötig macht. Wir bauen auf dem auf, was da ist.',
 now()),

('fazit.eine.a', 'fazit', 'eine', 'a',
 'Was noch nicht sicher ist, gehört zu einem einzigen Thema. Das lässt sich am Stück aufarbeiten, ohne dass der übrige Stoff liegen bleibt.',
 now()),
('fazit.eine.b', 'fazit', 'eine', 'b',
 'Die offenen Bereiche liegen alle in einem Thema. Wir nehmen es geschlossen vor und halten das übrige Niveau parallel.',
 now()),

('fazit.zwei.a', 'fazit', 'zwei', 'a',
 'Die offenen Bereiche verteilen sich auf zwei Themen. Wir nehmen sie nacheinander vor, nicht gleichzeitig — sonst bleibt an beiden Stellen etwas halb fertig.',
 now()),
('fazit.zwei.b', 'fazit', 'zwei', 'b',
 'Was noch nicht trägt, liegt in zwei Themen. Wir beginnen mit dem, was weiter unten liegt, und gehen von dort nach oben.',
 now()),

('fazit.mehrere.a', 'fazit', 'mehrere', 'a',
 'Die offenen Bereiche verteilen sich über mehrere Themen. Wir beginnen unten und arbeiten uns nach oben vor — nacheinander, nicht gleichzeitig.',
 now()),
('fazit.mehrere.b', 'fazit', 'mehrere', 'b',
 'Was noch nicht trägt, liegt in mehreren Themen verteilt. Deshalb gehen wir der Reihe nach vor und fangen bei den Grundlagen an, auf denen das Übrige aufbaut.',
 now()),


-- ── slot 'empfehlung' — Paketbegruendung, ebenfalls nach Verteilung ────────
--
-- Nennt bewusst KEINE Terminzahl: Die steht in der Frequenzzeile daneben,
-- direkt aus tiers. Eine Zahl an zwei Orten driftet — genau das ist am 18.08.
-- passiert, als die Tarife korrigiert wurden und die Prosa stehen blieb.

('empfehlung.keine.a', 'empfehlung', 'keine', 'a',
 'Es gibt nichts nachzuholen. Dieser Rhythmus reicht, um den laufenden Stoff sicher mitzunehmen.',
 now()),
('empfehlung.keine.b', 'empfehlung', 'keine', 'b',
 'Der Lernstand trägt. Dieser Rhythmus genügt, um ihn zu halten.',
 now()),

('empfehlung.eine.a', 'empfehlung', 'eine', 'a',
 'Es geht um ein Thema. Dieser Rhythmus reicht, um es aufzuarbeiten und den laufenden Stoff mitzunehmen.',
 now()),
('empfehlung.eine.b', 'empfehlung', 'eine', 'b',
 'Ein einzelnes Thema lässt sich in diesem Rhythmus aufarbeiten, ohne dass daneben etwas liegen bleibt.',
 now()),

('empfehlung.zwei.a', 'empfehlung', 'zwei', 'a',
 'Zwei Themen nacheinander brauchen mehr Termine als eines — sonst zieht sich das eine, während das andere wartet. Dieser Rhythmus gibt dafür Raum.',
 now()),
('empfehlung.zwei.b', 'empfehlung', 'zwei', 'b',
 'Für zwei Themen nacheinander braucht es Wiederholung in kurzen Abständen. Dafür ist dieser Rhythmus gedacht.',
 now()),

('empfehlung.mehrere.a', 'empfehlung', 'mehrere', 'a',
 'Es sind mehrere Themen, und ein Teil davon liegt unter dem aktuellen Stoff — das braucht Wiederholung in kurzen Abständen.',
 now()),
('empfehlung.mehrere.b', 'empfehlung', 'mehrere', 'b',
 'Mehrere Themen nacheinander aufzuarbeiten und dabei den laufenden Stoff zu halten, geht nur mit dichten Terminen. Dieser Rhythmus ist darauf ausgelegt.',
 now())

on conflict (schluessel) do update
  set slot     = excluded.slot,
      fall     = excluded.fall,
      variante = excluded.variante,
      text     = excluded.text;


-- ── 3. Kontrolle ────────────────────────────────────────────────────────────
-- Im selben Transaktionsblock, damit ein unvollstaendiger Bestand nicht
-- committet wird. scripts/db-migrate.sh klammert nicht selbst.

do $$
declare
  v_fehlend text;
  v_anzahl  integer;
begin
  -- Jeder Fall genau zwei Varianten — sonst faellt die Streuung auf eine
  -- Fassung zusammen oder eine Variante fehlt still.
  select string_agg(slot || '.' || fall || ' (' || n || ')', ', ')
    into v_fehlend
    from (select slot, fall, count(*) as n
            from public.report_bausteine group by slot, fall having count(*) <> 2) q;
  if v_fehlend is not null then
    raise exception 'Faelle ohne genau zwei Varianten: %', v_fehlend;
  end if;

  -- Alle sechs Elternpunkte sind zugeordnet.
  select count(*) into v_anzahl from public.report_anlass_zuordnung;
  if v_anzahl <> 6 then
    raise exception '% Zeilen in report_anlass_zuordnung, erwartet 6', v_anzahl;
  end if;

  select string_agg(thema, ', ') into v_fehlend
    from public.report_anlass_zuordnung
   where anzeigename is null or btrim(anzeigename) = '';
  if v_fehlend is not null then
    raise exception 'Themen ohne Anzeigenamen: %', v_fehlend;
  end if;

  raise notice 'R5: 6 Elternpunkte zugeordnet, alle Faelle mit zwei Varianten';
end $$;

commit;
