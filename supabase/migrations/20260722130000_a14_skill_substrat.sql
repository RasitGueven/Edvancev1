-- 20260722130000_a14_skill_substrat
--
-- Rekonstruiert aus dem Prod-Schema am 2026-07-28.
-- Der ursprüngliche Wortlaut ist verloren; die Version steht bereits in
-- supabase_migrations.schema_migrations. Massgeblich ist allein, dass ein
-- Neuaufbau aus dem Repo denselben Zustand erreicht.
--
-- NICHT einspielen. Die Version gilt als angewandt.

--
-- Name: FUNCTION lsa_abschluss(p_skill_key text); Type: COMMENT; Schema: public; Owner: -

--
-- Name: skill_kante_tiefe_guard(); Type: FUNCTION; Schema: public; Owner: -
--

ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS skill_key text;

CREATE FUNCTION public.skill_kante_tiefe_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  v_tiefe_skill      int;
  v_tiefe_voraussetzt int;
begin
  select fundament_tiefe into v_tiefe_skill
    from public.skills where skill_key = new.skill_key;
  select fundament_tiefe into v_tiefe_voraussetzt
    from public.skills where skill_key = new.voraussetzt_skill_key;

  if v_tiefe_voraussetzt >= v_tiefe_skill then
    raise exception
      'skill_kante: % (Tiefe %) setzt % (Tiefe %) voraus — eine Voraussetzung muss ECHT flacher liegen',
      new.skill_key, v_tiefe_skill, new.voraussetzt_skill_key, v_tiefe_voraussetzt
      using errcode = '23514';
  end if;
  return null;
end;
$$;

--
-- Name: COLUMN lead_assessments.weak_topics; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.lead_assessments.weak_topics IS 'Optionale Themen-Tags (an leads.known_weak_topics angelehnt). Reveal-Metadatum, NICHT der Ziehalgorithmus. lsa_start liest diese Spalte nicht.';

--
-- Name: skill_kante; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_kante (
    skill_key text NOT NULL,
    voraussetzt_skill_key text NOT NULL
);

--
-- Name: TABLE skill_kante; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.skill_kante IS 'Direkte Voraussetzungen zwischen Skills. Transitive Huellen werden abgefragt, nicht gespeichert.';

--
-- Name: skill_voraussetzung; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_voraussetzung (
    thema_key text NOT NULL,
    skill_key text NOT NULL,
    tragkraft integer NOT NULL,
    CONSTRAINT skill_voraussetzung_tragkraft_check CHECK ((tragkraft = ANY (ARRAY[1, 2])))
);

--
-- Name: COLUMN skill_voraussetzung.tragkraft; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skill_voraussetzung.tragkraft IS '1 = ohne dieses Fundament ist das Thema unzugaenglich, 2 = erschwert.';

--
-- Name: skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skills (
    skill_key text NOT NULL,
    label text NOT NULL,
    fach text DEFAULT 'mathematik'::text NOT NULL,
    klasse_herkunft integer NOT NULL,
    fundament_tiefe integer NOT NULL,
    CONSTRAINT skills_fundament_tiefe_check CHECK (((fundament_tiefe >= 1) AND (fundament_tiefe <= 8)))
);

--
-- Name: TABLE skills; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.skills IS 'Die Fundament-Skills der LSA-Auswahl. fundament_tiefe = Stufe im Fundament (1 traegt alles), nicht Schwierigkeit.';

--
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS sondierrang integer;

-- Name: COLUMN tasks.sondierrang; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tasks.sondierrang IS 'Reihenfolge innerhalb eines Skills beim Sondieren. NULL = noch nicht gesetzt; Handarbeit (Rasit/Lena), siehe docs/sondierrang_vorschlag.md.';

--
-- Name: themen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.themen (
    thema_key text NOT NULL,
    fach text NOT NULL,
    klasse integer NOT NULL,
    label text
);

--
-- Name: skill_kante skill_kante_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_kante
    ADD CONSTRAINT skill_kante_pkey PRIMARY KEY (skill_key, voraussetzt_skill_key);

--
-- Name: skill_voraussetzung skill_voraussetzung_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_voraussetzung
    ADD CONSTRAINT skill_voraussetzung_pkey PRIMARY KEY (thema_key, skill_key);

--
-- Name: skills skills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (skill_key);

--
-- Name: themen themen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.themen
    ADD CONSTRAINT themen_pkey PRIMARY KEY (thema_key);

--
-- Name: skill_kante_voraussetzt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX skill_kante_voraussetzt_idx ON public.skill_kante USING btree (voraussetzt_skill_key);

--
-- Name: tasks_skill_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tasks_skill_key_idx ON public.tasks USING btree (skill_key) WHERE (skill_key IS NOT NULL);
--
--
-- Name: skill_kante skill_kante_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_kante
    ADD CONSTRAINT skill_kante_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key) ON DELETE CASCADE;

--
-- Name: skill_kante skill_kante_voraussetzt_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_kante
    ADD CONSTRAINT skill_kante_voraussetzt_skill_key_fkey FOREIGN KEY (voraussetzt_skill_key) REFERENCES public.skills(skill_key) ON DELETE CASCADE;

--
-- Name: skill_voraussetzung skill_voraussetzung_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_voraussetzung
    ADD CONSTRAINT skill_voraussetzung_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key) ON DELETE CASCADE;

--
-- Name: skill_voraussetzung skill_voraussetzung_thema_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_voraussetzung
    ADD CONSTRAINT skill_voraussetzung_thema_key_fkey FOREIGN KEY (thema_key) REFERENCES public.themen(thema_key) ON DELETE CASCADE;

--
-- Name: student_focus_areas student_focus_areas_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -

--
-- Name: tasks tasks_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key);

-- Stammdaten. Aus Produktion nachgetragen; pg_dump --schema-only
-- enthält keine Daten, deshalb fehlten sie in der Rekonstruktion.

-- skills (32 Zeilen)
INSERT INTO public.skills VALUES ('dezimal_add_sub', 'Dezimalzahlen addieren/subtrahieren', 'mathematik', 5, 1) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('bruch_kuerzen', 'Brüche kürzen', 'mathematik', 6, 1) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('vorzeichen_add_sub', 'Negative Zahlen addieren/subtrahieren', 'mathematik', 7, 1) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('dezimal_mult', 'Dezimalzahlen multiplizieren', 'mathematik', 6, 2) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('bruch_add', 'Brüche addieren', 'mathematik', 6, 2) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('bruch_mult', 'Brüche multiplizieren', 'mathematik', 6, 2) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('vorzeichen_mult_div', 'Negative Zahlen multiplizieren/dividieren', 'mathematik', 7, 2) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('runden_ueberschlag', 'Runden und Überschlag', 'mathematik', 5, 2) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('dezimal_div', 'Dezimalzahlen dividieren', 'mathematik', 6, 3) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('bruch_div', 'Brüche dividieren', 'mathematik', 6, 3) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('bruch_dezimal', 'Bruch in Dezimalzahl', 'mathematik', 6, 4) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('groessen_laengen', 'Längen umrechnen', 'mathematik', 5, 3) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('groessen_massen', 'Massen umrechnen', 'mathematik', 5, 3) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('vorzeichen_vorrang', 'Vorrangregeln mit Vorzeichen', 'mathematik', 7, 4) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('groessen_zeit', 'Zeitspannen umrechnen', 'mathematik', 5, 4) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('potenzen', 'Potenzen und Quadratzahlen', 'mathematik', 7, 4) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('proportionalitaet', 'Dreisatz, proportionale Zuordnung', 'mathematik', 7, 4) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('term_zusammenfassen', 'Terme zusammenfassen', 'mathematik', 7, 4) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('groessen_flaechen', 'Flächeneinheiten', 'mathematik', 6, 5) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('groessen_volumen', 'Volumeneinheiten', 'mathematik', 6, 6) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('groessen_gemischt', 'Gemischte Schreibweise', 'mathematik', 6, 5) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('term_ausmultiplizieren', 'Ausmultiplizieren', 'mathematik', 7, 5) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('gleichung_einschrittig', 'Einschrittige Gleichungen', 'mathematik', 7, 5) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('term_minusklammer', 'Minusklammer auflösen', 'mathematik', 7, 6) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('gleichung_zweischrittig', 'Zweischrittige Gleichungen', 'mathematik', 7, 6) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('prozent_prozentwert', 'Prozentwert berechnen', 'mathematik', 7, 6) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('term_ausklammern', 'Ausklammern', 'mathematik', 7, 7) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('gleichung_neg_koeffizient', 'Gleichungen mit negativem Koeffizienten', 'mathematik', 7, 7) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('gleichung_beidseitig', 'Beidseitige Gleichungen', 'mathematik', 7, 7) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('prozent_grundwert', 'Grundwert berechnen', 'mathematik', 7, 7) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('prozent_prozentsatz', 'Prozentsatz berechnen', 'mathematik', 7, 7) ON CONFLICT DO NOTHING;
INSERT INTO public.skills VALUES ('prozent_veraenderung', 'Prozentuale Veränderung', 'mathematik', 7, 8) ON CONFLICT DO NOTHING;

-- themen (8 Zeilen)
INSERT INTO public.themen VALUES ('terme_binomische_formeln', 'mathematik', 8, 'Terme und binomische Formeln') ON CONFLICT DO NOTHING;
INSERT INTO public.themen VALUES ('lineare_gleichungen_lgs', 'mathematik', 8, 'Lineare Gleichungen und LGS') ON CONFLICT DO NOTHING;
INSERT INTO public.themen VALUES ('lineare_funktionen', 'mathematik', 8, 'Lineare Funktionen') ON CONFLICT DO NOTHING;
INSERT INTO public.themen VALUES ('zinsrechnung', 'mathematik', 8, 'Zinsrechnung') ON CONFLICT DO NOTHING;
INSERT INTO public.themen VALUES ('kreis', 'mathematik', 8, 'Kreis') ON CONFLICT DO NOTHING;
INSERT INTO public.themen VALUES ('prismen_zylinder', 'mathematik', 8, 'Prismen und Zylinder') ON CONFLICT DO NOTHING;
INSERT INTO public.themen VALUES ('zufallsexperimente', 'mathematik', 8, 'Zufallsexperimente') ON CONFLICT DO NOTHING;
INSERT INTO public.themen VALUES ('daten_streumasse', 'mathematik', 8, 'Daten und Streumaße') ON CONFLICT DO NOTHING;

-- skill_kante (41 Zeilen)
INSERT INTO public.skill_kante VALUES ('dezimal_mult', 'dezimal_add_sub') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('dezimal_div', 'dezimal_mult') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('runden_ueberschlag', 'dezimal_add_sub') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('bruch_add', 'bruch_kuerzen') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('bruch_mult', 'bruch_kuerzen') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('bruch_div', 'bruch_mult') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('bruch_dezimal', 'bruch_kuerzen') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('bruch_dezimal', 'dezimal_div') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('vorzeichen_mult_div', 'vorzeichen_add_sub') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('vorzeichen_vorrang', 'vorzeichen_mult_div') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('groessen_laengen', 'dezimal_mult') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('groessen_massen', 'dezimal_mult') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('groessen_zeit', 'dezimal_add_sub') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('potenzen', 'dezimal_mult') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('potenzen', 'vorzeichen_mult_div') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('proportionalitaet', 'dezimal_div') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('groessen_flaechen', 'groessen_laengen') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('groessen_flaechen', 'potenzen') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('groessen_volumen', 'groessen_flaechen') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('groessen_gemischt', 'groessen_laengen') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('groessen_gemischt', 'groessen_zeit') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('term_zusammenfassen', 'vorzeichen_add_sub') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('term_ausmultiplizieren', 'term_zusammenfassen') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('term_ausmultiplizieren', 'vorzeichen_mult_div') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('term_minusklammer', 'term_ausmultiplizieren') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('term_ausklammern', 'term_ausmultiplizieren') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('gleichung_einschrittig', 'vorzeichen_add_sub') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('gleichung_einschrittig', 'dezimal_div') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('gleichung_zweischrittig', 'gleichung_einschrittig') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('gleichung_neg_koeffizient', 'gleichung_zweischrittig') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('gleichung_neg_koeffizient', 'vorzeichen_mult_div') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('gleichung_beidseitig', 'gleichung_zweischrittig') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('gleichung_beidseitig', 'term_zusammenfassen') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('prozent_prozentwert', 'proportionalitaet') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('prozent_prozentwert', 'dezimal_mult') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('prozent_prozentsatz', 'prozent_prozentwert') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('prozent_prozentsatz', 'dezimal_div') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('prozent_grundwert', 'prozent_prozentwert') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('prozent_grundwert', 'gleichung_einschrittig') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('prozent_veraenderung', 'prozent_prozentwert') ON CONFLICT DO NOTHING;
INSERT INTO public.skill_kante VALUES ('prozent_veraenderung', 'prozent_grundwert') ON CONFLICT DO NOTHING;


ALTER TABLE public.tasks ADD CONSTRAINT tasks_sondierrang_check CHECK (((sondierrang IS NULL) OR (sondierrang >= 1)));

-- CONSTRAINT TRIGGER: pg_dump gibt ihn als CREATE TRIGGER aus, mein Zuordner
-- hat die DEFERRABLE-Variante nicht erkannt.
CREATE CONSTRAINT TRIGGER skill_kante_tiefe AFTER INSERT OR UPDATE ON public.skill_kante DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION skill_kante_tiefe_guard();
