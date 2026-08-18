-- R4 — Erzählbausteine des Eltern-Reports: raus aus dem Renderer, rein in die DB.
--
-- Ausgangslage (Report-Durchsicht 2026-08-18 an den beiden echten Sitzungen
-- vom 16.08.):
--
--   * Abschnitt 02 sagte fest verdrahtet "Als sich zeigte, dass sie noch nicht
--     sicher sitzen, sind wir Schritt fuer Schritt tiefer gegangen." Bei BEIDEN
--     Sitzungen traegt das Einstiegsthema (2 von 2), und der Einstiegsskill
--     steht zwei Abschnitte weiter unter "Das traegt". Der Satz widerspricht
--     also den Zahlen, die daneben stehen.
--   * Der Renderer konnte das nicht anders: es gab genau einen Satz, keine
--     Fallunterscheidung, und er stand im Code.
--
-- Entscheidung: dieselbe Bauart wie fehlbild_familien (AF4). Die Saetze leben
-- in der Datenbank, tragen eine Abnahme-Schranke, und der Renderer waehlt nur
-- noch aus. Was nicht abgenommen ist, erreicht die Elternflaeche nicht — auch
-- nicht als Platzhalter (das war die Lehre aus AF4: ein Platzhalter stellt
-- genau die Behauptung auf, die die Abnahme verhindern soll).
--
-- Zwei Tabellen, weil zwei verschiedene Dinge:
--
--   report_bausteine          — SAETZE. Elternsprache, Abnahme-Schranke.
--   report_anlass_zuordnung   — ZUORDNUNG. Welcher von den Eltern genannte
--                               Bereich haengt an welchem Skill / welcher
--                               Fehlbild-Familie. Das ist Konfiguration, kein
--                               Satz — deshalb keine Abnahme-Schranke, aber
--                               auch nichts, was je gerendert wird.
--
-- ----------------------------------------------------------------------------
-- Was diese Migration NICHT tut
-- ----------------------------------------------------------------------------
-- Sie beruehrt lsa_start nicht und legt keinen Pfad von lead_assessments in die
-- Item-Auswahl. Die A3-Invariante (S5/S7) bleibt woertlich bestehen:
-- lead_assessments ist Reveal-Metadatum beim AUSWERTEN, nie Input beim STELLEN.
-- report_anlass_zuordnung wird ausschliesslich vom Report gelesen, nachdem die
-- Sitzung abgeschlossen ist.

begin;

-- ── 1. report_bausteine ─────────────────────────────────────────────────────
--
-- schluessel ist sprechend aufgebaut: <slot>.<fall>.<variante>. Er ist ein
-- interner Bezeichner wie ein Fehlbild-Slug und wird Eltern NIE gezeigt
-- (INV-4.3).
--
-- Warum zwei Varianten je Fall: zwei Kinder derselben Familie oder zwei
-- Geschwister im selben Jahrgang bekommen sonst wortgleiche Dokumente. Der
-- Renderer waehlt deterministisch ueber die Sitzungs-ID — dieselbe Sitzung
-- ergibt immer denselben Satz, zwei verschiedene Sitzungen streuen.

create table if not exists public.report_bausteine (
  schluessel      text primary key,
  slot            text not null,
  fall            text not null,
  variante        text not null,
  text            text not null,
  freigegeben_am  timestamptz,
  freigegeben_von uuid references public.profiles(id),
  constraint report_bausteine_variante_check check (variante in ('a', 'b')),
  constraint report_bausteine_slot_fall_variante_key unique (slot, fall, variante)
);

comment on table public.report_bausteine is
  'R4: die Erzaehlbausteine des Eltern-Reports. Ein Satz je (slot, fall, '
  'variante). Der Renderer bestimmt slot und fall aus den Sitzungsdaten und '
  'waehlt die variante deterministisch ueber die Sitzungs-ID. schluessel ist '
  'ein interner Bezeichner und KEIN Anzeigetext (INV-4.3).';

comment on column public.report_bausteine.slot is
  'Wo im Dokument der Satz steht: suche (Abschnitt 02 Fliesstext), '
  'abstieg_einbruch / abstieg_boden (Abschnitt 02 Kommentar zur Ebenenspur), '
  'befund_traegt (Abschnitt 03 Fusszeile), rueckbezug (Fazit, Aufgriff der '
  'Eltern-Einschaetzung).';

comment on column public.report_bausteine.fall is
  'Der Zustand, fuer den der Satz gilt — der Renderer leitet ihn aus den '
  'Zahlen ab und sucht danach. Ein Fall ohne abgenommenen Baustein faellt '
  'still aus dem Dokument, wie eine Fehlbild-Familie ohne Elterntext.';

comment on column public.report_bausteine.text is
  'Elternsprache: siezen, kein Defizit-Vokabular, keine Note, kein Vergleich '
  'mit anderen Kindern, keine Prognose. Platzhalter in geschweiften Klammern '
  'werden vom Renderer ersetzt ({traegt}, {geprueft}, {ebene}). Die '
  'Sprachregeln stehen in src/test/invariants/inv4-eltern-sprache.test.ts.';

comment on column public.report_bausteine.freigegeben_am is
  'R4 Abnahme-Schranke, woertlich wie fehlbild_familien.freigegeben_am (AF4). '
  'NULL = unabgenommener Entwurf; der Lesepfad (src/lib/supabase/'
  'reportBausteine.ts) liefert solche Zeilen nicht aus, und der Slot bleibt '
  'leer statt einen Entwurf zu zeigen. Abnahme: update report_bausteine set '
  'freigegeben_am = now(), freigegeben_von = ''<profil-uuid>'' where '
  'schluessel = ''<schluessel>'';';

comment on column public.report_bausteine.freigegeben_von is
  'R4: wer abgenommen hat (profiles.id). Belegt die Abnahme, steuert sie '
  'nicht — massgeblich ist allein freigegeben_am.';

-- RLS woertlich wie fehlbild_familien (AF4): Leserecht admin/coach. Die
-- Tabelle ist Registry-Inhalt, aber sie enthaelt Saetze ueber den Lernstand
-- eines Kindes und gehoert nicht in die Hand eines Schueler-Tokens.
alter table public.report_bausteine enable row level security;
drop policy if exists report_bausteine_read on public.report_bausteine;
create policy report_bausteine_read on public.report_bausteine
  for select using (public.get_my_role() = any (array['admin', 'coach']));
grant select on public.report_bausteine to authenticated;


-- ── 2. report_anlass_zuordnung ──────────────────────────────────────────────
--
-- thema traegt WOERTLICH den Wert, der in lead_assessments.weak_topics steht.
-- Das Intake-UI (src/pages/admin/intake/intakeConstants.ts, PARENT_WEAK_TOPICS)
-- schreibt deutsche Labels, keine Codes — es gibt in der Datenbank keinen
-- CHECK darauf, faktisch sind es aber genau sechs feste Werte. Ein Thema ohne
-- Zeile hier bekommt keinen Rueckbezug; das ist der Normalfall fuer
-- Konzentration, Pruefungsangst und Zeiteinteilung.
--
-- ----------------------------------------------------------------------------
-- Warum skill_keys UND fehlbild_familien, und warum sie NICHT dasselbe koennen
-- ----------------------------------------------------------------------------
-- Ein Skill-Urteil ist beidseitig belastbar: 'traegt' ist ein positiver Beleg,
-- 'traegt_nicht' ein negativer. Eine Fehlbild-Familie ist es NICHT — ihre
-- Abwesenheit beweist nichts.
--
-- Beleg aus der Sitzung 920d00ae (16.08.): fuenf falsche Antworten, null
-- fehlbild_slug. Dieselben Aufgaben liefern in der Sitzung d8b0d885 teils einen
-- Slug, teils nicht. Ein Slug entsteht nur, wenn die GEGEBENE Antwort auf ein
-- katalogisiertes Muster passt — fehlt er, war die Antwort nur nicht
-- katalogisiert, nicht etwa fehlerfrei.
--
-- Deshalb die Asymmetrie im Lesepfad (src/lib/report/rueckbezug.ts):
--   skill_keys        -> koennen bestaetigen UND entlasten
--   fehlbild_familien -> koennen NUR bestaetigen
-- Ein Thema ohne skill_keys bekommt also nie einen entlastenden Satz.

create table if not exists public.report_anlass_zuordnung (
  thema             text primary key,
  skill_keys        text[] not null default '{}',
  fehlbild_familien text[] not null default '{}',
  strukturell       boolean not null default false
);

comment on table public.report_anlass_zuordnung is
  'R4: Zuordnung der von Eltern genannten Bereiche (lead_assessments.'
  'weak_topics) auf pruefbare Belege. Ausschliesslich Lesepfad des Reports — '
  'kein Pfad in lsa_start, die A3-Invariante bleibt unberuehrt. Wird NIE '
  'gerendert: hier stehen Schluessel, keine Saetze.';

comment on column public.report_anlass_zuordnung.thema is
  'Woertlich der Wert aus lead_assessments.weak_topics (deutsches Label aus '
  'PARENT_WEAK_TOPICS, kein Code). Themen ohne Zeile bekommen keinen '
  'Rueckbezug — das ist Absicht, nicht Luecke.';

comment on column public.report_anlass_zuordnung.skill_keys is
  'Direkt gepruefte Skills, die diesen Bereich belegen. Beidseitig: traegt -> '
  'entlastend, traegt_nicht/traegt_teilweise -> bestaetigend.';

comment on column public.report_anlass_zuordnung.fehlbild_familien is
  'Fehlbild-Familien, die diesen Bereich belegen. NUR bestaetigend — die '
  'Abwesenheit einer Familie ist kein Beleg fuer Abwesenheit des Problems '
  '(Begruendung im Kopf dieser Migration).';

comment on column public.report_anlass_zuordnung.strukturell is
  'true = der Beleg ist keine Skill-Liste, sondern die Form des Fundaments '
  'selbst (tragen die Ebenen unter dem Einstieg?). Gilt nur fuer '
  '"Grundlagen fehlen".';

alter table public.report_anlass_zuordnung enable row level security;
drop policy if exists report_anlass_zuordnung_read on public.report_anlass_zuordnung;
create policy report_anlass_zuordnung_read on public.report_anlass_zuordnung
  for select using (public.get_my_role() = any (array['admin', 'coach']));
grant select on public.report_anlass_zuordnung to authenticated;


-- ── 3. Zuordnung bestuecken ─────────────────────────────────────────────────
--
-- Drei der sechs PARENT_WEAK_TOPICS sind belegbar. Konzentration,
-- Pruefungsangst und Zeiteinteilung bekommen bewusst KEINE Zeile: es gibt
-- weder einen Skill noch eine Fehlbild-Familie dafuer. Sie aus ausgelassenen
-- Aufgaben oder Bearbeitungsdauern abzuleiten waere eine Verhaltensdeutung auf
-- ein bis zwei Datenpunkten — und ein falscher Rueckbezug ist schaedlicher als
-- gar keiner.

insert into public.report_anlass_zuordnung (thema, skill_keys, fehlbild_familien, strukturell)
values
  -- gleichung_modellieren ist der einzige Skill mit Sachkontext im Label
  -- ("Gleichungen aufstellen (Sachkontext)"). Er traegt die Uebersetzung
  -- Text -> Rechnung und ist damit der direkte Beleg fuer diesen Bereich.
  ('Textverständnis',   '{gleichung_modellieren}', '{sachaufgaben}', false),

  -- Kein Skill: die Skills heissen nach dem VERFAHREN (gleichung_beidseitig),
  -- nicht nach dessen Durchfuehrung. Ob der Rechenweg abbricht, steht in den
  -- Fehlbildern — und die koennen nur bestaetigen. "Rechenwege" bekommt
  -- deshalb nie einen entlastenden Satz.
  ('Rechenwege',        '{}', '{gleichungen_umformen,rechenreihenfolge}', false),

  -- Strukturell: "Grundlagen fehlen" ist keine Aussage ueber einen Bereich,
  -- sondern ueber die Form des Fundaments. Belegt wird sie an den Ebenen
  -- unterhalb der Einstiegstiefe, nicht an einer Skill-Liste.
  ('Grundlagen fehlen', '{}', '{}', true)
on conflict (thema) do update
  set skill_keys        = excluded.skill_keys,
      fehlbild_familien = excluded.fehlbild_familien,
      strukturell       = excluded.strukturell;


-- ── 4. Bausteine bestuecken ─────────────────────────────────────────────────
--
-- Alle Saetze sind hier direkt freigegeben (freigegeben_am = now()), weil sie
-- Teil dieser Migration und ihres Reviews sind — anders als bei AF4, wo die
-- Texte aus einem LLM-Entwurf kamen und eine eigene Abnahme brauchten. Wer
-- einen Satz spaeter aendert, setzt freigegeben_am zurueck und nimmt ihn neu ab.

insert into public.report_bausteine (schluessel, slot, fall, variante, text, freigegeben_am)
values

-- ── slot 'suche' — Abschnitt 02, der Fliesstext ueber der Ebenenspur ────────
--
-- Vier Faelle ueber zwei Achsen: traegt der Einstieg, und traegt das, was
-- darunter liegt. Der bisherige Renderer kannte nur den zweiten Fall und
-- behauptete ihn auch dann, wenn die Zahlen daneben das Gegenteil zeigten.

('suche.einstieg_traegt_fundament_luecken.a', 'suche', 'einstieg_traegt_fundament_luecken', 'a',
 'Beim aktuellen Thema kommt Ihr Kind zurecht. Wir haben trotzdem weiter nach unten geprüft — ein Thema kann auch dann wacklig stehen, wenn es an der Oberfläche hält. Dort zeigt sich, worauf es steht. Insgesamt {geprueft} Bereiche über {ebenen} Ebenen hinweg.',
 now()),
('suche.einstieg_traegt_fundament_luecken.b', 'suche', 'einstieg_traegt_fundament_luecken', 'b',
 'Die Aufgaben zum aktuellen Thema hat Ihr Kind gelöst. Uns interessiert aber, was darunter liegt: Wir sind Ebene für Ebene tiefer gegangen und haben geprüft, ob das Fundament trägt — {geprueft} Bereiche über {ebenen} Ebenen hinweg.',
 now()),

('suche.einstieg_luecken_fundament_luecken.a', 'suche', 'einstieg_luecken_fundament_luecken', 'a',
 'Schon beim aktuellen Thema zeigte sich, dass die Aufgaben noch nicht sicher sitzen. Wir sind deshalb Schritt für Schritt tiefer gegangen — bis zu den Grundlagen, auf denen das Thema aufbaut. Insgesamt {geprueft} Bereiche über {ebenen} Ebenen hinweg.',
 now()),
('suche.einstieg_luecken_fundament_luecken.b', 'suche', 'einstieg_luecken_fundament_luecken', 'b',
 'Das aktuelle Thema trug noch nicht durchgehend. Wir haben daraufhin geprüft, was darunter liegt, und sind so weit nach unten gegangen, bis wir sicheren Boden gefunden haben — {geprueft} Bereiche über {ebenen} Ebenen hinweg.',
 now()),

('suche.einstieg_luecken_fundament_traegt.a', 'suche', 'einstieg_luecken_fundament_traegt', 'a',
 'Beim aktuellen Thema hakte es. Wir haben deshalb die Grundlagen darunter geprüft — und die tragen. Die Schwierigkeit liegt im Thema selbst, nicht in seinem Unterbau. Geprüft haben wir {geprueft} Bereiche über {ebenen} Ebenen.',
 now()),
('suche.einstieg_luecken_fundament_traegt.b', 'suche', 'einstieg_luecken_fundament_traegt', 'b',
 'Die Aufgaben zum aktuellen Thema saßen noch nicht sicher. Der Unterbau darunter hat der Prüfung dagegen standgehalten — dort liegt die Ursache nicht. Geprüft haben wir {geprueft} Bereiche über {ebenen} Ebenen.',
 now()),

('suche.alles_traegt.a', 'suche', 'alles_traegt', 'a',
 'Beim aktuellen Thema kommt Ihr Kind zurecht. Wir haben zusätzlich die Grundlagen darunter geprüft — auch sie tragen, über alle Ebenen hinweg, die wir angesehen haben: {geprueft} Bereiche über {ebenen} Ebenen.',
 now()),
('suche.alles_traegt.b', 'suche', 'alles_traegt', 'b',
 'Wir haben beim aktuellen Thema begonnen und von dort nach unten geprüft. Auf keiner der geprüften Ebenen hat sich ein Bereich gezeigt, der Anlass zur Nachprüfung gäbe — {geprueft} Bereiche über {ebenen} Ebenen.',
 now()),


-- ── slot 'abstieg_einbruch' — die Ebene mit dem groessten Einbruch ──────────
--
-- Der Abstieg ist nicht monoton. Bei d8b0d885 lautet die Spur
-- 2/2 · 2/3 · 0/2 · 1/3 · 1/4 · 3/3: er bricht in der MITTE, nicht unten.
-- "0 von 2" ist der schaerfste Datenpunkt des Dokuments und stand bis R4
-- unkommentiert in einer Zeile.

('abstieg_einbruch.standard.a', 'abstieg_einbruch', 'standard', 'a',
 'Am deutlichsten zeigt es sich {ebene}: Dort trugen {traegt} von {geprueft} geprüften Bereichen.',
 now()),
('abstieg_einbruch.standard.b', 'abstieg_einbruch', 'standard', 'b',
 'Der deutlichste Einbruch liegt {ebene} — {traegt} von {geprueft} geprüften Bereichen haben dort getragen.',
 now()),


-- ── slot 'abstieg_boden' — die unterste gepruefte Ebene traegt vollstaendig ──
--
-- Gute Nachricht, die sonst untergeht: bei beiden Sitzungen vom 16.08. traegt
-- ganz unten alles. Wird nur gerendert, wenn das tatsaechlich so ist.

('abstieg_boden.vollstaendig.a', 'abstieg_boden', 'vollstaendig', 'a',
 'Ganz unten steht das Fundament: Auf der tiefsten Ebene, die wir geprüft haben, trug jeder Bereich.',
 now()),
('abstieg_boden.vollstaendig.b', 'abstieg_boden', 'vollstaendig', 'b',
 'Die unterste geprüfte Ebene trägt vollständig — die Grundlagen ganz unten sind da.',
 now()),


-- ── slot 'befund_traegt' — Fusszeile der Spalte "Das traegt" ────────────────
--
-- Bis R4 stand hier "9 von 17 geprueften Bereichen ohne Anlass zur
-- Nachpruefung" — dieselbe Zahl noch einmal im Aufklappbereich als "die
-- uebrigen neun". Zweimal dieselbe Aussage, beide Male als Abwesenheit von
-- Problemen formuliert. Jetzt einmal, und als Aussage ueber Koennen.

('befund_traegt.standard.a', 'befund_traegt', 'standard', 'a',
 '{traegt} von {geprueft} geprüften Bereichen tragen sicher.',
 now()),
('befund_traegt.standard.b', 'befund_traegt', 'standard', 'b',
 'Von {geprueft} geprüften Bereichen tragen {traegt}.',
 now()),


-- ── slot 'rueckbezug' — der Aufgriff der Eltern-Einschaetzung im Fazit ──────
--
-- Bis R4 nannte Abschnitt 01 woertlich, was die Eltern angegeben hatten, und
-- der Report kam nie darauf zurueck. Dabei ist "Ihre Sorge hat sich so nicht
-- bestaetigt" die staerkste Aussage, die er machen kann.
--
-- Der Fall-Schluessel ist <thema-slug>_<richtung>. Entlastende Saetze nennen
-- IMMER die Grundgesamtheit — auf zwei Aufgaben laesst sich kein Freispruch
-- bauen, und der Satz soll das selbst sagen.

('rueckbezug.textverstaendnis_entlastend.a', 'rueckbezug', 'textverstaendnis_entlastend', 'a',
 'Sie hatten das Textverständnis als Schwierigkeit genannt. In den {belege} Aufgaben mit Sachkontext, die wir gestellt haben, hat Ihr Kind die Rechnung richtig aus dem Text abgeleitet — dieser Punkt hat sich so nicht bestätigt.',
 now()),
('rueckbezug.textverstaendnis_entlastend.b', 'rueckbezug', 'textverstaendnis_entlastend', 'b',
 'Zum Textverständnis, das Sie angesprochen haben: Ihr Kind hat die {belege} Sachaufgaben dieser Analyse richtig in eine Rechnung übersetzt. Dort liegt die Schwierigkeit nach dem, was wir gesehen haben, nicht.',
 now()),

-- Dieselbe Entlastung, aber auf schmaler Grundlage (unter zwei Aufgaben).
-- Kein Weglassen: die Eltern haben den Bereich genannt und bekommen eine
-- Antwort — nur eine, die ihren Ausschnitt selbst benennt. Gegen die echten
-- Sitzungen ist das der REGELFALL: gleichung_modellieren wurde am 16.08. in
-- beiden Sitzungen mit genau EINER Aufgabe geprueft.
('rueckbezug.textverstaendnis_entlastend_schmal.a', 'rueckbezug', 'textverstaendnis_entlastend_schmal', 'a',
 'Sie hatten das Textverständnis als Schwierigkeit genannt. Die eine Aufgabe mit Sachkontext, die in dieser Analyse vorkam, hat Ihr Kind richtig aus dem Text abgeleitet. Das ist ein schmaler Ausschnitt — der Coach sieht sich den Bereich in den ersten Sitzungen genauer an.',
 now()),
('rueckbezug.textverstaendnis_entlastend_schmal.b', 'rueckbezug', 'textverstaendnis_entlastend_schmal', 'b',
 'Zum Textverständnis, das Sie angesprochen haben: In der Sachaufgabe dieser Analyse hat Ihr Kind den richtigen Rechenweg gewählt. Eine Aufgabe ist wenig, um daraus etwas zu schließen — wir prüfen das im Unterricht nach.',
 now()),

('rueckbezug.grundlagen_entlastend_schmal.a', 'rueckbezug', 'grundlagen_entlastend_schmal', 'a',
 'Sie hatten vermutet, dass Grundlagen fehlen. Der eine Bereich unterhalb des aktuellen Themas, den wir geprüft haben, trägt. Das ist noch kein vollständiges Bild — der Coach geht die Ebenen darunter im Unterricht durch.',
 now()),
('rueckbezug.grundlagen_entlastend_schmal.b', 'rueckbezug', 'grundlagen_entlastend_schmal', 'b',
 'Zu Ihrer Vermutung, dass Grundlagen fehlen: Was wir unterhalb des aktuellen Themas angesehen haben, hat getragen. Es war allerdings nur ein Bereich — mehr sagt diese Analyse dazu nicht.',
 now()),

('rueckbezug.textverstaendnis_bestaetigend.a', 'rueckbezug', 'textverstaendnis_bestaetigend', 'a',
 'Ihre Beobachtung zum Textverständnis deckt sich mit unserer: Beim Übersetzen einer Textaufgabe in eine Rechnung ist Ihr Kind noch nicht sicher.',
 now()),
('rueckbezug.textverstaendnis_bestaetigend.b', 'rueckbezug', 'textverstaendnis_bestaetigend', 'b',
 'Was Sie zum Textverständnis gesagt haben, findet sich in der Analyse wieder — der Schritt vom Text zur Rechnung trägt noch nicht.',
 now()),

('rueckbezug.rechenwege_bestaetigend.a', 'rueckbezug', 'rechenwege_bestaetigend', 'a',
 'Sie hatten die Rechenwege genannt. Das deckt sich mit dem, was wir beobachtet haben — der Rechenweg bricht wiederkehrend an derselben Stelle ab.',
 now()),
('rueckbezug.rechenwege_bestaetigend.b', 'rueckbezug', 'rechenwege_bestaetigend', 'b',
 'Zu den Rechenwegen, die Sie angesprochen haben: Wir haben denselben Schritt mehrfach gleich verlaufen sehen. Er steht auf der Liste für die ersten Sitzungen.',
 now()),

-- "Grundlagen fehlen" mit tragendem Boden: die haeufigste und zugleich am
-- staerksten missverstandene Lage. Nicht das Fundament fehlt, sondern Stufen
-- darin.
('rueckbezug.grundlagen_bestaetigend_mitte.a', 'rueckbezug', 'grundlagen_bestaetigend_mitte', 'a',
 'Ihr Eindruck, dass Grundlagen fehlen, bestätigt sich — allerdings nicht ganz unten. Die tiefsten Ebenen, die wir geprüft haben, tragen; die Lücken liegen dazwischen.',
 now()),
('rueckbezug.grundlagen_bestaetigend_mitte.b', 'rueckbezug', 'grundlagen_bestaetigend_mitte', 'b',
 'Sie hatten vermutet, dass Grundlagen fehlen. Das trifft zu, aber genauer gesagt: Nicht das Fundament als Ganzes fehlt, sondern einzelne Stufen darin.',
 now()),

('rueckbezug.grundlagen_bestaetigend_durchgehend.a', 'rueckbezug', 'grundlagen_bestaetigend_durchgehend', 'a',
 'Ihr Eindruck, dass Grundlagen fehlen, bestätigt sich. Die Lücken reichen bis auf die tiefste Ebene, die wir geprüft haben — dort setzen wir an.',
 now()),
('rueckbezug.grundlagen_bestaetigend_durchgehend.b', 'rueckbezug', 'grundlagen_bestaetigend_durchgehend', 'b',
 'Sie hatten vermutet, dass Grundlagen fehlen. Die Analyse zeigt das über mehrere Ebenen hinweg, bis ganz nach unten.',
 now()),

('rueckbezug.grundlagen_entlastend.a', 'rueckbezug', 'grundlagen_entlastend', 'a',
 'Sie hatten vermutet, dass Grundlagen fehlen. Unterhalb des aktuellen Themas hat jeder geprüfte Bereich getragen — dieser Punkt hat sich so nicht bestätigt.',
 now()),
('rueckbezug.grundlagen_entlastend.b', 'rueckbezug', 'grundlagen_entlastend', 'b',
 'Zu Ihrer Vermutung, dass Grundlagen fehlen: Alle Bereiche unterhalb des aktuellen Themas, die wir geprüft haben, tragen.',
 now())

on conflict (schluessel) do update
  set slot     = excluded.slot,
      fall     = excluded.fall,
      variante = excluded.variante,
      text     = excluded.text;

commit;
