-- sondierrang_setzen.sql
--
-- Setzt tasks.sondierrang auf 1 und 2 — je 38 Skills genau eine Aufgabe je
-- Rang, 76 Anweisungen. Alles Weitere bleibt NULL und wird zufaellig gezogen.
--
-- Erzeugt von scripts/content/sondierrang_vorschlag.py. Die Begruendung je
-- Skill steht in out/sondierrang-bericht.md — vor dem scharfen Lauf lesen.
--
-- Keine Transaktionsklammer hier; die setzt der Aufrufer.
-- Idempotent: 'sondierrang is distinct from N' laesst den zweiten Lauf leer.
-- source/status stehen in jedem where mit, damit die Anweisung auch dann noch
-- das Richtige trifft, wenn eine Aufgabe inzwischen zurueckgezogen wurde.
--
-- Probelauf (schreibt nicht):
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/sql/sondierrang_probelauf.sql
-- Scharf:
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/sql/sondierrang_setzen.sql

-- bruch_kuerzen — Brüche kürzen
update tasks set sondierrang = 1
 where id = '9a70682a-428d-4b75-8567-e5d9f7cb607e'  -- brueche-kuerzen-07
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '9a6bf378-2cd4-4ca5-afeb-bb856d5853f8'  -- brueche-kuerzen-03
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- dezimal_add_sub — Dezimalzahlen addieren/subtrahieren
update tasks set sondierrang = 1
 where id = '024143bf-840e-4ad5-aefe-b18c223aefcf'  -- dezimal-addieren-05
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'be8ce7e4-d8f2-4b45-b6b1-447b102cf500'  -- dezimal-addieren-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- vorzeichen_add_sub — Negative Zahlen addieren/subtrahieren
update tasks set sondierrang = 1
 where id = 'e96cd37d-0254-4051-bf2d-71a6f7fa2aaf'  -- vorzeichen-addieren-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '27f51c08-6a47-4ceb-b189-f5f07cbcf1cf'  -- vorzeichen-addieren-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- bruch_add — Brüche addieren
update tasks set sondierrang = 1
 where id = 'c81ae9db-193f-4154-9db9-d6062f21a587'  -- brueche-addieren-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'd0c1132b-4d85-4f7a-867e-22d6f36f6415'  -- brueche-addieren-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- bruch_mult — Brüche multiplizieren
update tasks set sondierrang = 1
 where id = '590b9c87-620f-4d53-90fc-fe6d40d16cba'  -- brueche-multiplizieren-02
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'f7175bad-c4e5-469c-bbf4-6b8c1ca0215e'  -- brueche-multiplizieren-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- dezimal_mult — Dezimalzahlen multiplizieren
update tasks set sondierrang = 1
 where id = '3038721a-abdd-4030-b683-33b3e8d3efb9'  -- dezimal-multiplizieren-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '3d066cef-b5e1-45db-b560-dd86d1c5b38c'  -- dezimal-multiplizieren-02
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- runden_ueberschlag — Runden und Überschlag
update tasks set sondierrang = 1
 where id = '0cd53103-432c-41a2-9f48-383c1f7580cd'  -- runden-02
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '4ff59e5f-dab3-4ef4-80bd-ad7e96e11080'  -- runden-08
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- vorzeichen_mult_div — Negative Zahlen multiplizieren/dividieren
update tasks set sondierrang = 1
 where id = '0438a9f9-bdb4-4f29-ab59-adc7946ade36'  -- vorzeichen-punktrechnung-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '2e8ce53f-1357-48b2-8d76-0633ae836980'  -- vorzeichen-punktrechnung-02
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- bruch_div — Brüche dividieren
update tasks set sondierrang = 1
 where id = '6e2e4f8f-3442-4cf9-90da-2623554106f0'  -- brueche-dividieren-02
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '802069f8-d538-4d03-a4cb-e31af86593a6'  -- brueche-dividieren-03
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- dezimal_div — Dezimalzahlen dividieren
update tasks set sondierrang = 1
 where id = '6b531762-47e8-4b29-aeee-ce70b560486a'  -- dezimal-dividieren-06
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'bdf4d10a-9cf2-4ed5-a59b-54fec4b3851f'  -- dezimal-dividieren-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- geo_flaeche_rechteck — Fläche von Rechteck und Quadrat
update tasks set sondierrang = 1
 where id = '008adff9-e38e-4620-a6aa-97862f85367d'  -- geo-flaeche-rechteck-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'af8ccf14-4373-4bb9-b892-c650265dd0cd'  -- geo-flaeche-rechteck-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- geo_umfang — Umfang von Rechteck und Dreieck
update tasks set sondierrang = 1
 where id = '485f81e3-48fb-47c7-b333-964baa6ad10c'  -- geo-umfang-03
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'e09a9496-8650-4a39-b2be-e54e512b8cab'  -- geo-umfang-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- geo_winkel_summe — Winkelsummen im Dreieck und Viereck
update tasks set sondierrang = 1
 where id = 'c3e86490-5d41-4f55-9aa8-b170123409b8'  -- geo-winkel-summe-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '60d58ee6-d2cd-40f3-985d-fe0a1ed8ec4e'  -- geo-winkel-summe-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- groessen_laengen — Längen umrechnen
update tasks set sondierrang = 1
 where id = '62bbb1fe-9401-4ac2-8b24-e5a603f77e22'  -- groessen-laengen-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'b9e84b84-77df-42d9-b34e-f6ccc283e930'  -- groessen-laengen-03
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- groessen_massen — Massen umrechnen
update tasks set sondierrang = 1
 where id = '4e34f73b-5593-4807-91a4-b9c5d3fada5d'  -- groessen-massen-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '5d6a704a-cc38-4144-adee-ad396d532457'  -- groessen-massen-03
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- bruch_dezimal — Bruch in Dezimalzahl
update tasks set sondierrang = 1
 where id = 'de2aabbf-8988-47d4-9f51-c4e80232b374'  -- dezimal-umwandeln-03
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '6ef85b4a-1f14-49b4-acf6-05aa01567e4f'  -- dezimal-umwandeln-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- geo_flaeche_dreieck — Fläche von Dreieck und Parallelogramm
update tasks set sondierrang = 1
 where id = 'd602bc49-3ee0-48fb-8cd3-467b2ae0abc2'  -- geo-flaeche-dreieck-05
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'ecb3d12b-a21e-4031-b562-a1596deeb815'  -- geo-flaeche-dreieck-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- geo_volumen_quader — Volumen und Oberfläche des Quaders
update tasks set sondierrang = 1
 where id = '6a448f69-d164-4cf6-82ca-461a8bae980f'  -- geo-volumen-quader-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '7d305269-159f-40cc-9965-c343c2bb4c15'  -- geo-volumen-quader-05
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- groessen_zeit — Zeitspannen umrechnen
update tasks set sondierrang = 1
 where id = 'b1ede380-80c7-44df-9263-dad843ee33d5'  -- groessen-zeit-02
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '9f7f0cd7-128b-4a4d-9281-16c78804a1b4'  -- groessen-zeit-05
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- potenzen — Potenzen und Quadratzahlen
update tasks set sondierrang = 1
 where id = 'a3343b39-bedb-491f-a214-6b6817ce2768'  -- potenzen-14
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'aef364ee-8c7f-49af-9e55-c2c65b7e36db'  -- potenzen-15
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- proportionalitaet — Dreisatz, proportionale Zuordnung
update tasks set sondierrang = 1
 where id = '82215b1c-332b-4ca4-b167-090460b594bd'  -- proportionalitaet-02
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '9372380c-8cf0-47a1-9fb5-330d44b6a975'  -- proportionalitaet-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- term_zusammenfassen — Terme zusammenfassen
update tasks set sondierrang = 1
 where id = 'df219b8c-887d-43c2-b544-ca2df4f32e66'  -- term-zusammenfassen-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'c83b34e8-e6e7-4142-83ff-fae510201c5c'  -- term-zusammenfassen-02
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- vorzeichen_vorrang — Vorrangregeln mit Vorzeichen
update tasks set sondierrang = 1
 where id = '573dd0b7-5fd2-4b4e-9263-3630affba5da'  -- vorzeichen-vorrang-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'a394b2eb-df58-4b57-9c79-ae8ff0c62b24'  -- vorzeichen-vorrang-03
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- geo_massstab — Maßstab
update tasks set sondierrang = 1
 where id = 'ceb26573-de3f-488a-9956-6a8cf7eb81cf'  -- geo-massstab-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'fe3a88b0-7d72-4896-929c-b7f0c379cfa3'  -- geo-massstab-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- gleichung_einschrittig — Einschrittige Gleichungen
update tasks set sondierrang = 1
 where id = '4f6f7cdd-3415-4185-8eae-95083d061b71'  -- gleichung-einschrittig-02
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '152bcdcd-897b-452b-9a8f-402375540a3f'  -- gleichung-einschrittig-03
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- groessen_flaechen — Flächeneinheiten
update tasks set sondierrang = 1
 where id = 'b7b814a6-d2c9-4988-855c-3d51b5148da0'  -- groessen-flaechen-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'f531dcee-04cf-4e14-ad5e-9032f72f0668'  -- groessen-flaechen-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- groessen_gemischt — Gemischte Schreibweise
update tasks set sondierrang = 1
 where id = '20cdce1e-0e9d-478d-820e-b77ff90c94bc'  -- groessen-gemischt-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '2a55970e-6a27-496b-8229-35813122e30b'  -- groessen-gemischt-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- term_ausmultiplizieren — Ausmultiplizieren
update tasks set sondierrang = 1
 where id = '1527a939-6199-4d8c-9163-6f34b0cd0e13'  -- term-ausmultiplizieren-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '10a764bc-9657-4a5a-b11d-64b2a0014b05'  -- term-ausmultiplizieren-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- gleichung_zweischrittig — Zweischrittige Gleichungen
update tasks set sondierrang = 1
 where id = 'e8348c89-67cb-4650-be91-235e69321776'  -- gleichung-zweischrittig-02
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992'  -- gleichung-zweischrittig-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- groessen_volumen — Volumeneinheiten
update tasks set sondierrang = 1
 where id = '34d5e69b-f8c9-4837-8dc8-84c73400141d'  -- groessen-volumen-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'd36af517-b33f-4633-8a86-57cacc015bfd'  -- groessen-volumen-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- prozent_prozentwert — Prozentwert berechnen
update tasks set sondierrang = 1
 where id = '4d9e1f4d-8f87-4bbe-a6b4-cdbd459bfc1f'  -- prozent-wert-03
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '8337d39e-ff22-4393-94e5-35f0c835cd45'  -- prozent-wert-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- term_minusklammer — Minusklammer auflösen
update tasks set sondierrang = 1
 where id = '04cc98ff-2c04-4bd4-9db9-3947a1e8fbd3'  -- term-minusklammer-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'ba6f456d-2525-4989-8da7-937501699018'  -- term-minusklammer-03
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- gleichung_beidseitig — Beidseitige Gleichungen
update tasks set sondierrang = 1
 where id = 'e647e2ec-7e4c-404d-96cd-b6f402b6a981'  -- gleichung-beidseitig-02
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '19ba5f42-6cd4-4191-afe0-fd8a09c4ac35'  -- gleichung-beidseitig-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- gleichung_neg_koeffizient — Gleichungen mit negativem Koeffizienten
update tasks set sondierrang = 1
 where id = '4a0fe6b6-7b4f-436f-9788-8579b3a218f8'  -- gleichung-negativ-03
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'b11655f3-ac29-4030-9e82-49d5371d2f04'  -- gleichung-negativ-02
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- prozent_grundwert — Grundwert berechnen
update tasks set sondierrang = 1
 where id = '7875948d-3789-43cb-8e1a-861de7167ece'  -- prozent-grundwert-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '7eba6b75-1852-4713-8f6b-bf0e626fa52b'  -- prozent-grundwert-05
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- prozent_prozentsatz — Prozentsatz berechnen
update tasks set sondierrang = 1
 where id = '846c8ff7-9816-4ac7-b75a-3e51954270db'  -- prozent-satz-03
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'fee8aa29-db31-46e0-a21b-fe17279e7813'  -- prozent-satz-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- term_ausklammern — Ausklammern
update tasks set sondierrang = 1
 where id = '4baeeda9-3985-4a80-8fd0-ecf8bbcfd6af'  -- term-ausklammern-01
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = '65841bd8-ee27-454f-b2a4-ea6f1bb0db33'  -- term-ausklammern-02
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;

-- prozent_veraenderung — Prozentuale Veränderung
update tasks set sondierrang = 1
 where id = '2155cd07-b21f-46d1-a1d9-bb78345641d8'  -- prozent-veraenderung-04
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 1;
update tasks set sondierrang = 2
 where id = 'be903a02-c572-4378-96cf-b264ee161494'  -- prozent-veraenderung-02
   and source = 'edvance_fundament' and status = 'ready'
   and sondierrang is distinct from 2;
