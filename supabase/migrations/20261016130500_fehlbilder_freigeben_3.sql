-- Freigabe der übrigen 54 Fehlbilder aus Batus Pilot-Aufgaben (Nachtrag zu 20261016130300/130400).
--
-- Grundlage: docs/themen/fehlbilder-freigabe.md (16.10.), von Rasit durchgesehen. 37 Texte bleiben, wie sie sind;
-- bei 17 Slugs werden Rasits bestätigte Gegenvorschläge übernommen (15 Klartexte, 5 Erklärungen).
--
-- 1. Klartext/Erklärung nur dort, wo noch der Vorher-Text steht (WHERE mit Vorher-Text). Weicht der Text ab, bleibt er
--    stehen; die NOTICE meldet dann weniger als 15 bzw. 5 Zeilen.
-- 2. freigegeben_am = now() für alle 54 Slugs, nur wo leer und mit Klartext. freigegeben_von bleibt leer.
--
-- freigegeben_am wird nur in antwort_abgeben (Coach-Live-Strom der Session) und lsa_fehlbild_report (LSA-Report)
-- gelesen; Lenas Board und die Fehlbild-Auswahl im Editor lesen es nicht.
-- Idempotent; kein begin/commit: mig klammert mit psql -1.

do $fbf3$
declare
  v_k integer := 0;
  v_e integer := 0;
  v_n integer;
begin
  update public.fehlbild_labels
     set klartext = 'Verwechselt den Startwert, an dem der Graph die y-Achse schneidet, mit der Stelle, an der er die x-Achse schneidet: bei f(x) = 4x − 6 also 1,5 statt −6.'
   where slug = 'achsenabschnitt_verwechselt'
     and klartext = 'Gibt die Nullstelle als y-Achsenabschnitt an oder umgekehrt.';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  update public.fehlbild_labels
     set klartext = 'Verwechselt im Dreieck mit zwei gleich langen Seiten den Winkel an der Spitze mit einem der beiden gleich großen Winkel an der Grundseite.'
   where slug = 'basiswinkel_falsch_zugeordnet'
     and klartext = 'Verwechselt im gleichschenkligen Dreieck den Winkel an der Spitze mit einem Basiswinkel.';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  update public.fehlbild_labels
     set klartext = 'Holt eine Quadratzahl aus der Wurzel, ohne aus ihr die Wurzel zu ziehen: √72 = 36 · √2 statt 6 · √2.'
   where slug = 'faktor_ohne_wurzel'
     and klartext = 'Zieht beim teilweisen Wurzelziehen den Faktor heraus, ohne aus ihm die Wurzel zu ziehen: √72 = 36·√2.';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  update public.fehlbild_labels
     set klartext = 'Klammert richtig aus, zerlegt den Rest aber nicht weiter mit einer binomischen Formel: 2(x² − 9) statt 2(x + 3)(x − 3).'
   where slug = 'faktorisierung_unvollstaendig'
     and klartext = 'Klammert aus, erkennt die binomische Form darin aber nicht.';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  update public.fehlbild_labels
     set erklaerung = 'Der erste Schritt ist richtig: der gemeinsame Faktor steht vor der Klammer. Was in der Klammer übrig bleibt, ist aber noch einmal eine binomische Form und ließe sich weiter zerlegen. Gerechnet ist also richtig, nur nicht zu Ende. Geübt wird, nach dem Ausklammern ein zweites Mal hinzusehen.'
   where slug = 'faktorisierung_unvollstaendig'
     and erklaerung = 'Der erste Schritt ist richtig: der gemeinsame Faktor steht vor der Klammer. Was in der Klammer übrig bleibt, ist aber noch einmal eine binomische Form und liesse sich weiter zerlegen. Das Ergebnis ist damit nicht falsch, nur nicht zu Ende geführt. Wir üben, nach dem Ausklammern ein zweites Mal hinzusehen.';
  get diagnostics v_n = row_count; v_e := v_e + v_n;

  update public.fehlbild_labels
     set klartext = 'Rechnet die Wahrscheinlichkeit für das Gegenteil aus, etwa „keine Sechs“ statt „mindestens eine Sechs“, und zieht sie am Ende nicht von 1 ab.'
   where slug = 'gegenereignis_nicht_abgezogen'
     and klartext = 'Gibt die Wahrscheinlichkeit des Gegenereignisses an statt der gesuchten.';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  update public.fehlbild_labels
     set erklaerung = 'Der Abstand zum Ursprung stimmt, nur die Richtung ist verloren: ein Punkt links der y-Achse oder unterhalb der x-Achse bekommt eine positive Koordinate. Das ist kein Rechenfehler, sondern eine Frage der Achsenrichtung. Geübt wird, die negativen Abschnitte der Achsen als eigene Richtung zu lesen.'
   where slug = 'koordinate_vorzeichen_verloren'
     and erklaerung = 'Der Abstand zum Ursprung stimmt, nur die Richtung ist verloren: ein Punkt links der y-Achse oder unterhalb der x-Achse bekommt eine positive Koordinate. Das ist kein Rechenfehler, sondern eine Frage der Achsenrichtung. Geuebt wird, die negativen Abschnitte der Achsen als eigene Richtung zu lesen.';
  get diagnostics v_n = row_count; v_e := v_e + v_n;

  update public.fehlbild_labels
     set erklaerung = 'Der Punkt wird richtig gefunden, aber die beiden Werte stehen in der falschen Reihenfolge: zuerst der Wert an der senkrechten Achse, dann der an der waagerechten. Im Koordinatenpaar steht immer zuerst x (nach rechts oder links), dann y (nach oben oder unten). Geübt wird die feste Reihenfolge beim Ablesen und beim Eintragen.'
   where slug = 'koordinaten_vertauscht'
     and erklaerung = 'Der Punkt wird richtig gefunden, aber die beiden Werte stehen in der falschen Reihenfolge: zuerst der Wert an der senkrechten Achse, dann der an der waagerechten. Im Koordinatenpaar steht immer zuerst x (nach rechts oder links), dann y (nach oben oder unten). Geuebt wird die feste Reihenfolge beim Ablesen und beim Eintragen.';
  get diagnostics v_n = row_count; v_e := v_e + v_n;

  update public.fehlbild_labels
     set klartext = 'Übersieht die Lösung x = 0, etwa weil durch x geteilt wurde: Bei x² − 5x = 0 bleibt nur x = 5 übrig.'
   where slug = 'loesung_null_verloren'
     and klartext = 'Teilt durch x und verliert dabei die Lösung x = 0.';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  update public.fehlbild_labels
     set klartext = 'Vergisst beim mittleren Glied das Verdoppeln: (x + 3)² = x² + 3x + 9 statt x² + 6x + 9.'
   where slug = 'mal_zwei_vergessen'
     and klartext = 'Ein nötiges Verdoppeln wurde weggelassen.';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  update public.fehlbild_labels
     set erklaerung = 'In (a + b)² = a² + 2ab + b² kommt das Produkt ab zweimal vor, einmal als a · b und einmal als b · a. Hier wurde es nur einmal gezählt, das mittlere Glied ist deshalb nur halb so groß. Geübt wird, die Klammer einmal als (a + b) · (a + b) auszuschreiben.'
   where slug = 'mal_zwei_vergessen'
     and erklaerung = 'Manche Formeln enthalten ein „mal 2“, etwa weil ein Quader jede Seitenfläche zweimal hat oder ein Zylinder zwei Deckel. Fehlt dieser Faktor, stimmt der Rest der Rechnung oft, ein Teil geht aber nur einfach statt doppelt ein, und das Ergebnis weicht entsprechend ab.';
  get diagnostics v_n = row_count; v_e := v_e + v_n;

  update public.fehlbild_labels
     set klartext = 'Zählt nur einen von mehreren passenden Wegen, etwa nur „erst Kopf, dann Zahl“ und nicht auch „erst Zahl, dann Kopf“.'
   where slug = 'nur_ein_pfad'
     and klartext = 'Berücksichtigt bei einem Ereignis nur einen von mehreren passenden Pfaden.';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  update public.fehlbild_labels
     set klartext = 'Zählt Wahrscheinlichkeiten zusammen, wo sie malgenommen werden müssen, etwa bei „erst …, dann …“ oder bei mehreren Versuchen hintereinander.'
   where slug = 'pfadregel_addiert'
     and klartext = 'Addiert die Wahrscheinlichkeiten entlang eines Pfades, statt sie zu multiplizieren.';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  update public.fehlbild_labels
     set klartext = 'Setzt in der p-q-Formel die Zahl vor dem x mit falschem Vorzeichen ein; beide Lösungen bekommen dadurch das falsche Vorzeichen, etwa −1 und −5 statt 1 und 5.'
   where slug = 'pq_vorzeichen'
     and klartext = 'Setzt p in der p-q-Formel mit falschem Vorzeichen ein, beide Lösungen kippen ins Gegenteil.';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  update public.fehlbild_labels
     set klartext = 'Quadriert eine Klammer mit Plus oder Minus Teil für Teil und vergisst das mittlere Glied: (x + 3)² = x² + 9 statt x² + 6x + 9.'
   where slug = 'quadrat_gliedweise'
     and klartext = 'Quadriert die Klammer gliedweise – das mittlere Glied 2ab fehlt.';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  update public.fehlbild_labels
     set erklaerung = 'Aus (a + b)² wird a² + b² gemacht. Es fehlt das doppelte Produkt der beiden Glieder, 2ab. Die Abkürzung liegt nahe, weil sie bei einem Produkt tatsächlich stimmt: (a · b)² = a² · b². Bei einer Summe stimmt sie nicht. Geübt wird, die Klammer einmal als (a + b) · (a + b) auszuschreiben; dann ist das mittlere Glied sichtbar.'
   where slug = 'quadrat_gliedweise'
     and erklaerung = 'Aus (a+b)² wird a²+b² gemacht. Der Schritt, der fehlt, ist das doppelte Produkt der beiden Glieder. Das ist kein Rechenfehler, sondern eine Abkürzung, die naheliegt, weil sie beim Ausmultiplizieren einer Summe tatsächlich erlaubt wäre. Wir zeigen die Formel deshalb einmal als ausgeschriebene Doppelklammer – danach ist das mittlere Glied sichtbar und der Fehler verschwindet meist schnell.';
  get diagnostics v_n = row_count; v_e := v_e + v_n;

  update public.fehlbild_labels
     set klartext = 'Schreibt bei (a + b)(a − b) am Ende Plus statt Minus: (x + 4)(x − 4) = x² + 16 statt x² − 16.'
   where slug = 'quadratdifferenz_vorzeichen'
     and klartext = 'Vorzeichen im Ergebnis gekippt – a²+b² statt a²−b².';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  update public.fehlbild_labels
     set klartext = 'Schreibt Kommazahlen nicht Stelle unter Stelle und rechnet so Zehntel mit Hundertsteln zusammen: 0,25 + 0,4 = 0,29 statt 0,65.'
   where slug = 'stellenwert_ignoriert'
     and klartext = 'Beim Rechnen mit Kommazahlen wurden die Stellen nicht richtig miteinander verrechnet.';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  update public.fehlbild_labels
     set klartext = 'Behandelt das Minuszeichen beim Hochnehmen falsch: (−3)² = −9 statt 9, oder −2² wie (−2)² gerechnet, also 4 statt −4.'
   where slug = 'vorzeichen_potenz'
     and klartext = 'Beim Hochnehmen einer negativen Zahl wurde das Minuszeichen falsch behandelt.';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  update public.fehlbild_labels
     set klartext = 'Vergisst am Ende das Wurzelziehen: Aus x² = 49 wird x = 49 statt x = 7.'
   where slug = 'wurzel_vergessen'
     and klartext = 'Rechnet bis zum Quadrat richtig, zieht am Ende aber nicht die Wurzel.';
  get diagnostics v_n = row_count; v_k := v_k + v_n;

  raise notice 'fehlbilder_freigeben_3: % Klartext(e), % Erklärung(en) geändert', v_k, v_e;

  update public.fehlbild_labels
     set freigegeben_am = now()
   where slug in (
     'abgeschnitten',
     'achsenabschnitt_verwechselt',
     'additiv_gekuerzt',
     'ausklammern_falsch_geteilt',
     'ausklammern_glied_nicht_geteilt',
     'basis_exponent_vertauscht',
     'basiswinkel_falsch_zugeordnet',
     'differenz_vergessen',
     'faktor_ohne_wurzel',
     'faktorisierung_unvollstaendig',
     'falsche_hoehe',
     'falsche_operation',
     'falsche_stelle',
     'gegenereignis_nicht_abgezogen',
     'halbieren_vergessen',
     'immer_aufgerundet',
     'irrational_verwechselt',
     'komma_ignoriert',
     'komma_nicht_verschoben',
     'kommastellen_zu_viel',
     'kommastellen_zu_wenig',
     'koordinate_vorzeichen_verloren',
     'koordinaten_vertauscht',
     'loesung_null_verloren',
     'loesungsanzahl_verwechselt',
     'm_b_vertauscht',
     'mal_exponent',
     'mal_zwei_vergessen',
     'negative_loesung_vergessen',
     'nicht_alle_glieder_multipliziert',
     'nur_ein_pfad',
     'nur_eine_grundseite',
     'nur_einmal_addiert',
     'parallele_uebersehen',
     'pfadregel_addiert',
     'plus_statt_mal',
     'pq_vorzeichen',
     'quadrat_gliedweise',
     'quadratdifferenz_vorzeichen',
     'rechter_winkel_falsche_ecke',
     'seiten_ungleich_verknuepft',
     'steigung_kehrwert',
     'stellenwert_ignoriert',
     'teilflaeche_vergessen',
     'uebertrag_vergessen',
     'umfang_statt_flaeche',
     'umgekehrt_geteilt',
     'vorzeichen_aus_klammer',
     'vorzeichen_potenz',
     'wurzel_gliedweise',
     'wurzel_halbiert',
     'wurzel_vergessen',
     'ziffern_gelesen',
     'zuruecklegen_ignoriert')
     and freigegeben_am is null
     and nullif(btrim(coalesce(klartext, '')), '') is not null;
  get diagnostics v_n = row_count;
  raise notice 'fehlbilder_freigeben_3: % Fehlbild(er) freigegeben', v_n;
end $fbf3$;
