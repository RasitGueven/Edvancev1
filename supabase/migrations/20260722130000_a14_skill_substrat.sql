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

COMMENT ON FUNCTION public.lsa_abschluss(p_skill_key text) IS 'Alle transitiv erreichbaren Voraussetzungen eines Skills (ohne den Skill selbst). Immer zur Laufzeit — nie materialisiert.';

--
-- Name: skill_kante_tiefe_guard(); Type: FUNCTION; Schema: public; Owner: -
--

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

ALTER TABLE ONLY public.student_focus_areas
    ADD CONSTRAINT student_focus_areas_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key);

--
-- Name: tasks tasks_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key);
