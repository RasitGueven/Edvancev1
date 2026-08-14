-- sachkontext_aufgaben.sql
--
-- Legt zu 16 Fundament-Skills je drei Aufgaben mit Sachkontext an.
-- Quelle: 'edvance_fundament_kontext', Status: 'draft', sondierrang: null.
--
-- Der Bestand 'edvance_fundament' wird nicht angefasst. Diese Datei fuegt nur
-- neue Zeilen hinzu; sie aendert und loescht nichts Vorhandenes.
--
-- input_type, acceptance und unit folgen dem Muster der vorhandenen Aufgaben
-- desselben Skills: NUMERIC, acceptance = {canonical, known_errors}, unit =
-- Einheit der erwarteten Antwort. class_level bleibt null wie im Bestand.
--
-- Idempotent: 'on conflict (source, source_ref)' laesst den zweiten Lauf leer.
--
-- Anwenden:
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/sql/sachkontext_aufgaben.sql
-- Pruefen:
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/sql/sachkontext_pruefung.sql
-- Rueckweg (solange nichts freigegeben ist):
--     delete from tasks where source = 'edvance_fundament_kontext';

begin;

create temp table sk_neu (
  ref       text primary key,
  skill     text not null,
  afb       text not null,
  einheit   text,
  titel     text not null,
  frage     text not null,
  loesung   text not null,
  akzeptanz jsonb not null
) on commit drop;

insert into sk_neu (ref, skill, afb, einheit, titel, frage, loesung, akzeptanz) values

-- ── Groessen · Laengen ──────────────────────────────────────────────────────
('sk-groessen-laengen-01', 'groessen_laengen', 'I', 'm',
 E'Sachkontext · Längen · Laufstrecke',
 E'Auf dem Schulhof wird eine Laufstrecke von 3,5 km markiert. Für die Urkunde soll die Länge in Metern stehen.\n\nWie viele Meter sind das?',
 '3500',
 '{"canonical":"3500","known_errors":{"350":"einheit_uebersprungen","35000":"faktor_zehn_daneben","0,0035":"richtung_vertauscht"}}'),

('sk-groessen-laengen-02', 'groessen_laengen', 'I', 'm',
 E'Sachkontext · Längen · Fensterbreite',
 E'Jonas misst die Breite eines Fensters und liest 145 cm ab. Im Bauplan wird die Breite in Metern eingetragen.\n\nWie viele Meter sind das?',
 '1,45',
 '{"canonical":"1,45","known_errors":{"14,5":"faktor_zehn_daneben","145":"einheit_uebersprungen","14500":"richtung_vertauscht"}}'),

('sk-groessen-laengen-04', 'groessen_laengen', 'I', 'km',
 E'Sachkontext · Längen · Wegweiser',
 E'Ein Wanderweg ist 1250 m lang. Auf dem Wegweiser steht die Länge in Kilometern.\n\nWie viele Kilometer sind das?',
 '1,25',
 '{"canonical":"1,25","known_errors":{"12,5":"einheit_uebersprungen","0,125":"faktor_zehn_daneben","1250000":"richtung_vertauscht"}}'),

-- ── Groessen · Massen ───────────────────────────────────────────────────────
('sk-groessen-massen-01', 'groessen_massen', 'I', 'g',
 E'Sachkontext · Massen · Mehl abwiegen',
 E'Für ein Rezept werden 1,5 kg Mehl abgewogen. Die Küchenwaage zeigt Gramm an.\n\nWie viele Gramm sind das?',
 '1500',
 '{"canonical":"1500","known_errors":{"150":"faktor_hundert_statt_tausend","15000":"faktor_zehn_daneben","0,0015":"richtung_vertauscht"}}'),

('sk-groessen-massen-02', 'groessen_massen', 'I', 'kg',
 E'Sachkontext · Massen · Versandschein',
 E'Ein Paket wiegt 3200 g. Auf dem Versandschein wird die Masse in Kilogramm eingetragen.\n\nWie viele Kilogramm sind das?',
 '3,2',
 '{"canonical":"3,2","known_errors":{"32":"faktor_hundert_statt_tausend","0,32":"faktor_zehn_daneben","3200000":"richtung_vertauscht"}}'),

('sk-groessen-massen-03', 'groessen_massen', 'I', 'kg',
 E'Sachkontext · Massen · Ladeliste',
 E'Ein kleiner Transporter darf 2,5 t laden. Die Ladeliste ist in Kilogramm geführt.\n\nWie viele Kilogramm sind das?',
 '2500',
 '{"canonical":"2500","known_errors":{"250":"faktor_hundert_statt_tausend","25000":"faktor_zehn_daneben","0,0025":"richtung_vertauscht"}}'),

-- ── Groessen · Zeit ─────────────────────────────────────────────────────────
('sk-groessen-zeit-01', 'groessen_zeit', 'I', 'h',
 E'Sachkontext · Zeit · Turnierplan',
 E'Ein Fußballturnier dauert 210 min. Im Ablaufplan steht die Dauer in Stunden.\n\nWie viele Stunden sind das?',
 '3,5',
 '{"canonical":"3,5","known_errors":{"2,1":"faktor_hundert_statt_sechzig","3,3":"dezimal_statt_sexagesimal","12600":"richtung_vertauscht"}}'),

('sk-groessen-zeit-02', 'groessen_zeit', 'I', 'h',
 E'Sachkontext · Zeit · Fahrzeit',
 E'Eine Zugfahrt dauert 135 min. Auf dem Ticket ist die Fahrzeit in Stunden angegeben.\n\nWie viele Stunden sind das?',
 '2,25',
 '{"canonical":"2,25","known_errors":{"1,35":"faktor_hundert_statt_sechzig","2,15":"dezimal_statt_sexagesimal","8100":"richtung_vertauscht"}}'),

('sk-groessen-zeit-04', 'groessen_zeit', 'I', 'h',
 E'Sachkontext · Zeit · Programmheft',
 E'Ein Film läuft 144 min. Im Programmheft steht die Länge in Stunden.\n\nWie viele Stunden sind das?',
 '2,4',
 '{"canonical":"2,4","known_errors":{"1,44":"faktor_hundert_statt_sechzig","2,24":"dezimal_statt_sexagesimal","8640":"richtung_vertauscht"}}'),

-- ── Groessen · Flaechen ─────────────────────────────────────────────────────
('sk-groessen-flaechen-01', 'groessen_flaechen', 'II', 'dm²',
 E'Sachkontext · Flächen · Pflanzplan',
 E'Ein Beet im Schulgarten ist 5 m² groß. Im Pflanzplan wird die Fläche in Quadratdezimetern angegeben.\n\nWie viele Quadratdezimeter sind das?',
 '500',
 '{"canonical":"500","known_errors":{"50":"linearer_faktor","5":"einheit_uebersprungen","0,05":"richtung_vertauscht"}}'),

('sk-groessen-flaechen-02', 'groessen_flaechen', 'II', 'dm²',
 E'Sachkontext · Flächen · Lieferschein',
 E'Ein Fliesenrest bedeckt 350 cm². Auf dem Lieferschein steht die Fläche in Quadratdezimetern.\n\nWie viele Quadratdezimeter sind das?',
 '3,5',
 '{"canonical":"3,5","known_errors":{"35":"linearer_faktor","350":"einheit_uebersprungen","35000":"richtung_vertauscht"}}'),

('sk-groessen-flaechen-03', 'groessen_flaechen', 'II', 'ha',
 E'Sachkontext · Flächen · Stadtkarte',
 E'Ein Sportgelände ist 20000 m² groß. In der Stadtkarte steht die Fläche in Hektar.\n\nWie viele Hektar sind das?',
 '2',
 '{"canonical":"2","known_errors":{"200":"linearer_faktor","20":"einheit_uebersprungen"}}'),

-- ── Groessen · Volumen ──────────────────────────────────────────────────────
('sk-groessen-volumen-02', 'groessen_volumen', 'II', 'l',
 E'Sachkontext · Volumen · Datenblatt',
 E'Ein Aquarium fasst 45 dm³. Im Datenblatt steht das Volumen in Litern.\n\nWie viele Liter sind das?',
 '45',
 '{"canonical":"45","known_errors":{"45000":"liter_kubik_falsch","4,5":"linearer_faktor","0,045":"richtung_vertauscht"}}'),

('sk-groessen-volumen-03', 'groessen_volumen', 'II', 'cm³',
 E'Sachkontext · Volumen · Gießkanne',
 E'In eine Gießkanne passen 2,5 l. Für eine Berechnung wird das Volumen in Kubikzentimetern gebraucht.\n\nWie viele Kubikzentimeter sind das?',
 '2500',
 '{"canonical":"2500","known_errors":{"250":"linearer_faktor","2,5":"liter_kubik_falsch","0,0025":"richtung_vertauscht"}}'),

('sk-groessen-volumen-04', 'groessen_volumen', 'II', 'l',
 E'Sachkontext · Volumen · Messbecher',
 E'Ein Messbecher fasst 750 ml. Im Rezept steht die Menge in Litern.\n\nWie viele Liter sind das?',
 '0,75',
 '{"canonical":"0,75","known_errors":{"7,5":"linearer_faktor","750000":"richtung_vertauscht"}}'),

-- ── Groessen · gemischt ─────────────────────────────────────────────────────
('sk-groessen-gemischt-01', 'groessen_gemischt', 'II', 'cm',
 E'Sachkontext · Gemischt · Bauanleitung',
 E'Ein Regal ist 2,06 m hoch. In der Bauanleitung steht die Höhe in Zentimetern.\n\nWie viele Zentimeter sind das?',
 '206',
 '{"canonical":"206","known_errors":{"260":"fuehrende_null_ignoriert","26":"komma_als_trenner"}}'),

('sk-groessen-gemischt-02', 'groessen_gemischt', 'II', 'min',
 E'Sachkontext · Gemischt · Tagesplan',
 E'Eine Wanderung dauert 3,25 h. Im Tagesplan steht die Dauer in Minuten.\n\nWie viele Minuten sind das?',
 '195',
 '{"canonical":"195","known_errors":{"325":"komma_als_trenner","205":"dezimal_statt_sexagesimal"}}'),

('sk-groessen-gemischt-03', 'groessen_gemischt', 'II', 'g',
 E'Sachkontext · Gemischt · Etikett',
 E'Ein Beutel Vogelfutter wiegt 1,04 kg. Auf dem Etikett steht die Masse in Gramm.\n\nWie viele Gramm sind das?',
 '1040',
 '{"canonical":"1040","known_errors":{"1400":"fuehrende_null_ignoriert","104":"komma_als_trenner"}}'),

-- ── Proportionalitaet ───────────────────────────────────────────────────────
('sk-proportionalitaet-02', 'proportionalitaet', 'I', 'g',
 E'Sachkontext · Proportionalität · Suppe',
 E'Für 4 Portionen Suppe braucht Elif 600 g Kartoffeln.\n\nWie viele Gramm braucht sie für 10 Portionen?',
 '1500',
 '{"unit":"g","canonical":"1500","known_errors":{"6000":"einheit_verrutscht","1200":"falscher_bezug","240":"antiproportional_verwechselt"}}'),

('sk-proportionalitaet-03', 'proportionalitaet', 'I', 'Sekunden',
 E'Sachkontext · Proportionalität · Drucker',
 E'Ein Drucker druckt 5 Seiten in 20 Sekunden.\n\nWie viele Sekunden braucht er für 12 Seiten?',
 '48',
 '{"unit":"Sekunden","canonical":"48","known_errors":{"240":"einheit_verrutscht","3":"antiproportional_verwechselt","27":"falscher_bezug"}}'),

('sk-proportionalitaet-04', 'proportionalitaet', 'II', 'Stunden',
 E'Sachkontext · Proportionalität · Bühnenaufbau',
 E'Sechs gleich schnelle Helferinnen und Helfer bauen eine Bühne in 4 Stunden auf.\n\nWie lange brauchen 8 von ihnen?',
 '3',
 '{"unit":"Stunden","canonical":"3","known_errors":{"5,33":"antiproportional_verwechselt","24":"einheit_verrutscht","6":"falscher_bezug"}}'),

-- ── Prozent · Prozentwert ───────────────────────────────────────────────────
('sk-prozent-wert-01', 'prozent_prozentwert', 'I', 'Kinder',
 E'Sachkontext · Prozentwert · Schulweg',
 E'An einer Schule lernen 250 Kinder. 12 % von ihnen fahren mit dem Rad zur Schule.\n\nWie viele Kinder sind das?',
 '30',
 '{"unit":"Kinder","canonical":"30","known_errors":{"3000":"dezimalverschiebung","220":"grundwert_verwechselt"}}'),

('sk-prozent-wert-02', 'prozent_prozentwert', 'I', 'Mitglieder',
 E'Sachkontext · Prozentwert · Chorstimmen',
 E'Ein Chor hat 80 Mitglieder. 35 % von ihnen singen im Bass.\n\nWie viele Mitglieder sind das?',
 '28',
 '{"unit":"Mitglieder","canonical":"28","known_errors":{"2800":"dezimalverschiebung","52":"grundwert_verwechselt"}}'),

('sk-prozent-wert-03', 'prozent_prozentwert', 'I', '€',
 E'Sachkontext · Prozentwert · Konzertkarte',
 E'Eine Karte für das Schulkonzert kostet 24 €. Der Preis wird um 25 % gesenkt.\n\nUm wie viel Euro wird der Preis gesenkt?',
 '6',
 '{"unit":"€","canonical":"6","known_errors":{"600":"dezimalverschiebung","18":"grundwert_verwechselt"}}'),

-- ── Prozent · Grundwert ─────────────────────────────────────────────────────
('sk-prozent-grundwert-01', 'prozent_grundwert', 'II', null,
 E'Sachkontext · Grundwert · Bücherei',
 E'In einer Bücherei sind 36 Bücher ausgeliehen. Das sind 15 % des Bestands.\n\nWie viele Bücher hat die Bücherei insgesamt?',
 '240',
 '{"canonical":"240","known_errors":{"5,4":"multipliziert_statt_dividiert","540":"dezimalverschiebung"}}'),

('sk-prozent-grundwert-03', 'prozent_grundwert', 'II', null,
 E'Sachkontext · Grundwert · Chor',
 E'In einem Chor singen 21 Personen im Sopran. Das sind 35 % des Chores.\n\nWie viele Personen singen im Chor?',
 '60',
 '{"canonical":"60","known_errors":{"7,35":"multipliziert_statt_dividiert","735":"dezimalverschiebung"}}'),

('sk-prozent-grundwert-04', 'prozent_grundwert', 'II', null,
 E'Sachkontext · Grundwert · Bestellung',
 E'Von einer Bestellung sind bisher 45 Stühle geliefert. Das sind 25 % der Bestellung.\n\nWie viele Stühle wurden bestellt?',
 '180',
 '{"canonical":"180","known_errors":{"11,25":"multipliziert_statt_dividiert","1125":"dezimalverschiebung"}}'),

-- ── Prozent · Prozentsatz ───────────────────────────────────────────────────
('sk-prozent-satz-01', 'prozent_prozentsatz', 'I', '%',
 E'Sachkontext · Prozentsatz · Instrument',
 E'In einer Klasse mit 25 Kindern spielen 15 ein Instrument.\n\nWie viel Prozent sind das?',
 '60',
 '{"unit":"%","canonical":"60","known_errors":{"0,6":"faktor_100_vergessen","166,67":"bezug_vertauscht"}}'),

('sk-prozent-satz-02', 'prozent_prozentsatz', 'I', '%',
 E'Sachkontext · Prozentsatz · Fragebögen',
 E'Von 200 abgegebenen Fragebögen sind 24 unvollständig.\n\nWie viel Prozent sind das?',
 '12',
 '{"unit":"%","canonical":"12","known_errors":{"0,12":"faktor_100_vergessen","833,33":"bezug_vertauscht"}}'),

('sk-prozent-satz-03', 'prozent_prozentsatz', 'I', '%',
 E'Sachkontext · Prozentsatz · Regenmesser',
 E'Ein Regenmesser fasst 50 ml. Nach einem Schauer stehen 8 ml darin.\n\nWie viel Prozent des Fassungsvermögens sind das?',
 '16',
 '{"unit":"%","canonical":"16","known_errors":{"0,16":"faktor_100_vergessen","625":"bezug_vertauscht"}}'),

-- ── Prozent · Veraenderung ──────────────────────────────────────────────────
('sk-prozent-veraenderung-01', 'prozent_veraenderung', 'II', 'Mitglieder',
 E'Sachkontext · Veränderung · Verein',
 E'Ein Verein hatte im vergangenen Jahr 240 Mitglieder. In diesem Jahr sind es 15 % mehr.\n\nWie viele Mitglieder sind es jetzt?',
 '276',
 '{"unit":"Mitglieder","canonical":"276","known_errors":{"36":"nur_prozentwert","204":"falsche_richtung"}}'),

('sk-prozent-veraenderung-03', 'prozent_veraenderung', 'II', '€',
 E'Sachkontext · Veränderung · Fahrrad',
 E'Ein Fahrrad kostet 320 €. Der Preis sinkt um 25 %.\n\nWie viel Euro kostet es danach?',
 '240',
 '{"unit":"€","canonical":"240","known_errors":{"80":"nur_prozentwert","400":"falsche_richtung"}}'),

('sk-prozent-veraenderung-04', 'prozent_veraenderung', 'II', 'Fische',
 E'Sachkontext · Veränderung · Teich',
 E'In einem Teich lebten 80 Fische. Ihre Zahl nimmt um 10 % ab.\n\nWie viele Fische sind es dann?',
 '72',
 '{"unit":"Fische","canonical":"72","known_errors":{"8":"nur_prozentwert","88":"falsche_richtung"}}'),

-- ── Dezimal · addieren und subtrahieren ─────────────────────────────────────
('sk-dezimal-add-sub-01', 'dezimal_add_sub', 'I', 'km',
 E'Sachkontext · Dezimal · Laufstrecke zusammen',
 E'Nele läuft am Montag 2,4 km und am Dienstag 1,85 km.\n\nWie viele Kilometer läuft sie an beiden Tagen zusammen?',
 '4,25',
 '{"canonical":"4,25","known_errors":{"3,89":"stellenwert_ignoriert","0,55":"falsche_operation"}}'),

('sk-dezimal-add-sub-02', 'dezimal_add_sub', 'I', 'kg',
 E'Sachkontext · Dezimal · Rucksackinhalt',
 E'Ein Rucksack wiegt leer 0,85 kg. Vollgepackt wiegt er 3,2 kg.\n\nWie viele Kilogramm wiegt der Inhalt?',
 '2,35',
 '{"canonical":"2,35","known_errors":{"2,45":"stellenwert_ignoriert","4,05":"falsche_operation"}}'),

('sk-dezimal-add-sub-04', 'dezimal_add_sub', 'I', 'l',
 E'Sachkontext · Dezimal · Kanne',
 E'In einer Kanne sind 1,25 l Wasser und 0,4 l Saft.\n\nWie viele Liter Flüssigkeit sind in der Kanne?',
 '1,65',
 '{"canonical":"1,65","known_errors":{"1,29":"stellenwert_ignoriert","0,85":"falsche_operation"}}'),

-- ── Dezimal · multiplizieren ────────────────────────────────────────────────
('sk-dezimal-mult-01', 'dezimal_mult', 'I', '€',
 E'Sachkontext · Dezimal · Äpfel',
 E'Ein Kilogramm Äpfel kostet 2,40 €. Yusuf kauft 1,5 kg.\n\nWie viel Euro zahlt er?',
 '3,6',
 '{"canonical":"3,6","known_errors":{"36":"komma_ignoriert","0,36":"kommastellen_zu_viel"}}'),

('sk-dezimal-mult-02', 'dezimal_mult', 'I', 'm²',
 E'Sachkontext · Dezimal · Fliese',
 E'Eine rechteckige Fliese ist 0,3 m breit und 0,4 m hoch.\n\nWie viele Quadratmeter beträgt ihre Fläche?',
 '0,12',
 '{"canonical":"0,12","known_errors":{"1,2":"kommastellen_zu_wenig","12":"komma_ignoriert","0,012":"kommastellen_zu_viel"}}'),

('sk-dezimal-mult-03', 'dezimal_mult', 'I', 'l',
 E'Sachkontext · Dezimal · Wasserhahn',
 E'Aus einem Hahn fließen 0,25 l Wasser pro Sekunde. Er läuft 12 Sekunden lang.\n\nWie viele Liter fließen in dieser Zeit?',
 '3',
 '{"canonical":"3","known_errors":{"30":"komma_ignoriert","0,3":"kommastellen_zu_viel"}}'),

-- ── Dezimal · dividieren ────────────────────────────────────────────────────
('sk-dezimal-div-01', 'dezimal_div', 'I', 'Stücke',
 E'Sachkontext · Dezimal · Schnur teilen',
 E'Eine Schnur ist 4,8 m lang. Sie wird in Stücke von je 0,6 m geschnitten.\n\nWie viele Stücke sind das?',
 '8',
 '{"canonical":"8","known_errors":{"0,8":"komma_nicht_verschoben","0,125":"falsche_richtung"}}'),

('sk-dezimal-div-02', 'dezimal_div', 'I', 'Gläser',
 E'Sachkontext · Dezimal · Saft verteilen',
 E'In einer Flasche sind 1,5 l Saft. Er wird gleichmäßig in Gläser zu je 0,25 l gefüllt.\n\nWie viele Gläser sind das?',
 '6',
 '{"canonical":"6","known_errors":{"0,6":"komma_nicht_verschoben","0,167":"falsche_richtung"}}'),

('sk-dezimal-div-04', 'dezimal_div', 'I', 'Eimer',
 E'Sachkontext · Dezimal · Erde abfüllen',
 E'Für ein Hochbeet stehen 7,5 kg Blumenerde bereit. Sie wird in Eimer zu je 2,5 kg gefüllt.\n\nWie viele Eimer sind das?',
 '3',
 '{"canonical":"3","known_errors":{"0,3":"komma_nicht_verschoben","0,333":"falsche_richtung"}}'),

-- ── Runden und Ueberschlag ──────────────────────────────────────────────────
('sk-runden-01', 'runden_ueberschlag', 'I', '€',
 E'Sachkontext · Runden · Haushaltsbuch',
 E'Auf einem Kassenbon steht ein Betrag von 47,38 €. Im Haushaltsbuch wird auf ganze Euro gerundet.\n\nWelche Zahl wird eingetragen?',
 '47',
 '{"canonical":"47","known_errors":{"48":"immer_aufgerundet","47,4":"falsche_stelle"}}'),

('sk-runden-02', 'runden_ueberschlag', 'I', 's',
 E'Sachkontext · Runden · Urkunde',
 E'Ein Sprint wird mit 12,47 s gestoppt. Für die Urkunde wird auf eine Nachkommastelle gerundet.\n\nWelche Zahl steht auf der Urkunde?',
 '12,5',
 '{"canonical":"12,5","known_errors":{"12,4":"abgeschnitten","12":"falsche_stelle"}}'),

('sk-runden-03', 'runden_ueberschlag', 'I', 'kg',
 E'Sachkontext · Runden · Protokoll',
 E'Eine Waage zeigt 3,456 kg an. Im Protokoll wird auf zwei Nachkommastellen gerundet.\n\nWelche Zahl wird notiert?',
 '3,46',
 '{"canonical":"3,46","known_errors":{"3,45":"abgeschnitten","3,5":"falsche_stelle"}}'),

-- ── Geometrie · Massstab ────────────────────────────────────────────────────
('sk-geo-massstab-01', 'geo_massstab', 'II', 'km',
 E'Sachkontext · Maßstab · Radtour',
 E'Lea plant eine Radtour mit einer Karte im Maßstab 1:50000. Die Strecke ist auf der Karte 9 cm lang.\n\nWie viele Kilometer ist die Strecke in Wirklichkeit?',
 '4,5',
 '{"canonical":"4,5","known_errors":{"45":"faktor_zehn_daneben","450000":"einheit_ignoriert"}}'),

('sk-geo-massstab-02', 'geo_massstab', 'II', 'm',
 E'Sachkontext · Maßstab · Grundriss',
 E'In einem Grundriss im Maßstab 1:100 ist eine Wand 4 cm lang gezeichnet.\n\nWie viele Meter ist die Wand in Wirklichkeit lang?',
 '4',
 '{"canonical":"4","known_errors":{"40":"faktor_zehn_daneben","400":"einheit_ignoriert","0,04":"richtung_vertauscht"}}'),

('sk-geo-massstab-03', 'geo_massstab', 'II', 'm',
 E'Sachkontext · Maßstab · Lageplan',
 E'Auf einem Lageplan im Maßstab 1:200 ist ein Weg 18 cm lang.\n\nWie viele Meter ist der Weg in Wirklichkeit lang?',
 '36',
 '{"canonical":"36","known_errors":{"360":"faktor_zehn_daneben","3600":"einheit_ignoriert","0,09":"richtung_vertauscht"}}');

-- ── Schreiben ───────────────────────────────────────────────────────────────

insert into tasks (content_type, title, question, question_payload, input_type, unit, afb,
                   estimated_minutes, is_active, status, source, source_ref, skill_key, sondierrang)
select 'exercise', n.titel, n.frage,
       jsonb_build_object('kind', 'short_input', 'prompt', n.frage),
       'NUMERIC', n.einheit, n.afb,
       3, true, 'draft', 'edvance_fundament_kontext', n.ref, n.skill, null
  from sk_neu n
 on conflict (source, source_ref) do nothing;

insert into task_solutions (task_id, correct_answers, acceptance)
select t.id, jsonb_build_array(n.loesung), n.akzeptanz
  from sk_neu n
  join tasks t on t.source = 'edvance_fundament_kontext' and t.source_ref = n.ref
 on conflict (task_id) do update
   set correct_answers = excluded.correct_answers,
       acceptance      = excluded.acceptance;

commit;
