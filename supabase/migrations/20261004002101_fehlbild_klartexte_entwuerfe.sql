-- W5-a — Klartext-Entwürfe für verwendete Fehlbilder ohne Klartext.
--
-- Ausgangslage (dbread, 2026-10-04): 153 Slugs stehen in known_errors der
-- Nicht-VERA-Aufgaben (oberste Ebene UND je Teilaufgabe). 53 davon haben
-- keinen klartext, 27 weitere einen abgenommenen klartext ohne erklaerung.
-- Bestand und Begründungen: docs/fehlbilder/klartexte-entscheidungen.md,
-- Abnahmeliste für Lena: docs/fehlbilder/klartexte-abnahme.md.
--
-- Diese Migration schreibt 52 Entwürfe (klartext + erklaerung). Sie
--   * überschreibt nie einen nicht leeren Text (Feld für Feld geprüft),
--   * fasst keine Zeile mit freigegeben_am an — ein Entwurf darf nicht unter
--     einer fremden Abnahme landen (deshalb fehlen die 27 Erklärungen für
--     schon abgenommene Slugs hier; sie stehen nur im Abnahme-Dokument),
--   * setzt freigegeben_am/-von NICHT (das ist Lenas Abnahme),
--   * setzt KEINE familie: lsa_fehlbild_auswertung liefert den Familien-
--     Elterntext, sobald die FAMILIE freigegeben ist — unabhängig von der
--     Abnahme des Slugs. Eine Familie zu setzen hieße, den Slug ohne Lenas
--     Blick in den Elternbericht zu schalten. Vorschläge stehen im Dokument.
--   * lässt teilgekuerzt aus: fehlbild_familien.PRUEFUNG.sql F14 hält ihn
--     bewusst unbestückt, bis er umbenannt ist.
--
-- Wiederholbar: Der zweite Lauf findet keine leeren Felder mehr und ändert
-- nichts. Sicherheitsgrenze nur nach oben (höchstens 52 Zeilen), damit der
-- Neuaufbau auf leerer DB nicht anschlägt.
--
-- KEIN begin/commit (der Runner klammert).

create temp table w5a_entwurf (
  slug       text primary key,
  klartext   text not null,
  erklaerung text not null
);

insert into w5a_entwurf (slug, klartext, erklaerung) values
  ('halbieren_vergessen',
   'Ein nötiger Schritt „geteilt durch 2“ wurde weggelassen.',
   'Viele Rechenwege enthalten ein Halbieren, etwa bei der Fläche eines Dreiecks oder einer Raute oder bei zwei gleich großen Winkeln. Fehlt dieser Schritt, stimmt die übrige Rechnung oft, nur dieser eine Teil geht doppelt so groß in das Ergebnis ein.'),

  ('mal_exponent',
   'Die Hochzahl wurde als Faktor genommen, etwa 3² als 3 · 2 = 6 statt 3 · 3 = 9.',
   'Eine Hochzahl gibt an, wie oft eine Zahl mit sich selbst malgenommen wird. Die Verwechslung mit einfachem Malnehmen liegt nahe, weil beide Zahlen direkt nebeneinanderstehen; sie zeigt sich auch dort, wo etwas über mehrere Schritte wächst oder schrumpft oder eine Formel ein Quadrat enthält.'),

  ('multipliziert_statt_dividiert',
   'Es wurde malgenommen, wo geteilt werden muss.',
   'Das passiert besonders bei Rückwärtsaufgaben, etwa vom Anteil auf das Ganze oder vom Umfang auf den Radius: Die Zahlen sind dieselben wie in der Vorwärtsrechnung, nur die Rechenart muss sich umkehren. Das Ergebnis ist dann meist deutlich zu groß oder zu klein.'),

  ('wurzel_halbiert',
   'Statt die Wurzel zu ziehen, wurde die Zahl halbiert, etwa √36 = 18 statt 6.',
   'Die Wurzel ist die Zahl, die mit sich selbst malgenommen den Wert unter dem Wurzelzeichen ergibt: √36 = 6, weil 6 · 6 = 36. Das Halbieren ist dieselbe Verwechslung wie 3² = 6, nur in umgekehrter Richtung.'),

  ('plus_statt_mal',
   'Es wurde addiert, wo malgenommen werden muss.',
   'Bei Flächen und Rauminhalten werden Längen miteinander malgenommen, beim Umfang dagegen addiert. Werden die beiden Rechenarten verwechselt, ist das Ergebnis meist zu klein; dasselbe zeigt sich beim Rechnen mit Zehnerpotenzen oder Wurzeln.'),

  ('umfang_statt_flaeche',
   'Statt der Fläche wurde der Umfang berechnet.',
   'Fläche und Umfang werden aus denselben Längen berechnet, aber mit verschiedenen Formeln. Weil beide Formeln meist direkt nebeneinander gelernt werden, wird leicht die falsche gewählt; die Rechnung selbst stimmt dann oft.'),

  ('grundwert_verwechselt',
   'Der Prozentsatz wurde auf eine andere Größe bezogen als gefragt, oder es wurde der übrige Teil statt des gefragten berechnet.',
   'Jede Prozentangabe bezieht sich auf eine bestimmte Größe, zum Beispiel auf den alten Preis, auf alle Befragten oder nur auf eine Gruppe. Hier wurde eine andere Größe als Bezug genommen oder statt des gefragten Teils der übrige Teil berechnet; jeder Rechenschritt sieht richtig aus, das Ergebnis passt aber nicht zur Frage.'),

  ('bezug_vertauscht',
   'Beim Teilen wurden die beiden Zahlen vertauscht.',
   'Für einen Anteil wird der Teil durch das Ganze geteilt, für „A im Vergleich zu B“ wird A durch B geteilt. Werden die Zahlen vertauscht, kommt das umgedrehte Verhältnis heraus, bei Prozentangaben oft ein Wert über 100 %.'),

  ('abgeschnitten',
   'Überzählige Nachkommastellen wurden einfach weggelassen.',
   'Beim Runden entscheidet die erste weggelassene Ziffer, ob aufgerundet wird; ist „mindestens“ gefragt, muss sogar immer aufgerundet werden. Wer die Stellen nur abschneidet, liegt knapp unter dem richtigen Wert, bei einer Zahl mit Periode wie 0,4545… entsteht so sogar ein anderer Bruch.'),

  ('nur_prozentwert',
   'Es wurde nur die Veränderung berechnet, nicht der neue Wert.',
   'Bei einer Preiserhöhung, einem Rabatt oder Zinsen ist hier nach dem Endbetrag gefragt. Der Prozentanteil wurde richtig berechnet, aber nicht mehr zum Ausgangswert dazugezählt oder von ihm abgezogen.'),

  ('faktor_100_vergessen',
   'Beim Wechsel zwischen Prozent und Kommazahl fehlt der Faktor 100.',
   '12 % sind dasselbe wie 0,12; beim Wechsel zwischen beiden Schreibweisen wird mit 100 malgenommen oder durch 100 geteilt. Fehlt dieser Schritt, stimmt die Rechnung, das Ergebnis ist aber 100-mal zu klein.'),

  ('falsche_hoehe',
   'Als Höhe wurde eine andere Strecke eingesetzt, zum Beispiel eine schräge Seite.',
   'Für Flächen und Körper zählt jeweils eine bestimmte Höhe, die senkrecht auf der Grundseite steht; bei Pyramide und Kegel gibt es zusätzlich die schräge Höhe der Seitenflächen. Wird eine andere gegebene Strecke eingesetzt, stimmt der Rechenweg, das Ergebnis aber nicht.'),

  ('vorzeichen_potenz',
   'Beim Hochnehmen einer negativen Zahl wurde das Minuszeichen falsch behandelt.',
   '(−3)² bedeutet (−3) · (−3) und ergibt 9, weil Minus mal Minus Plus ergibt; −3² ohne Klammer ist dagegen −9. Wird aus dem Quadrat einer negativen Zahl eine negative Zahl, ist schon dieser Zwischenschritt falsch, und alles, was damit weitergerechnet wird, ebenfalls.'),

  ('falsche_operation',
   'Es wurde eine andere Rechenart gewählt, als die Aufgabe verlangt.',
   'Gerechnet wurde meist richtig, nur passt die Rechenart nicht zur Frage: Es wurde zum Beispiel zusammengezählt, wo der Unterschied gesucht ist, oder abgezogen, wo ein Verhältnis gefragt ist. Der Fehler liegt also beim Übersetzen des Textes in eine Rechnung, nicht beim Rechnen.'),

  ('falsche_stelle',
   'Es wurde auf eine andere Stelle gerundet als verlangt oder gar nicht gerundet.',
   'Die Aufgabe gibt vor, wie viele Stellen nach dem Komma stehen bleiben. Hier wurde an einer anderen Stelle gerundet oder die Zahl unverändert abgeschrieben; das Runden selbst ist dabei oft richtig.'),

  ('summe_360_statt_180',
   'Es wurde mit 360° gerechnet, wo 180° gelten.',
   'Die Winkel im Dreieck ergeben zusammen 180°, ebenso zwei Winkel, die an einer geraden Linie nebeneinanderliegen; 360° gelten für das Viereck und eine volle Drehung. Werden diese Summen verwechselt, ist das Ergebnis deutlich zu groß.'),

  ('basis_exponent_vertauscht',
   'Grundzahl und Hochzahl wurden vertauscht, etwa 2⁵ als 5² gerechnet.',
   'Bei 2⁵ wird die 2 fünfmal malgenommen, bei 5² die 5 zweimal; die Ergebnisse 32 und 25 sind verschieden. Die Verwechslung liegt nahe, weil die kleine, hochgestellte Zahl leicht anders gelesen wird; ausgeschrieben als Malaufgabe fällt sie sofort auf.'),

  ('dezimal_statt_sexagesimal',
   'Minuten wurden wie Nachkommastellen behandelt, etwa 2 h 48 min als 2,48 h.',
   'Eine Stunde hat 60 Minuten, nicht 100: 48 Minuten sind 0,8 Stunden, und 2,5 Stunden sind 2 Stunden 30 Minuten. Wer die Minuten einfach hinter das Komma schreibt, rechnet so, als hätte eine Stunde 100 Minuten.'),

  ('falscher_bezug',
   'Beim Dreisatz wurden Zahlen miteinander verrechnet, die nicht zusammengehören.',
   'Beim Dreisatz wird zuerst ausgerechnet, was eine Einheit kostet oder wie lange sie dauert, und dann hochgerechnet. Hier wurden zwei Zahlen verrechnet, die nicht zueinander passen, etwa die Anzahl durch den Preis geteilt; das Ergebnis beantwortet dann eine andere Frage.'),

  ('kommastellen_zu_viel',
   'Das Komma steht im Ergebnis eine Stelle zu weit links, etwa 0,6 · 0,4 = 0,024 statt 0,24.',
   'Bei Kommazahlen hängt die Lage des Kommas im Ergebnis an einer Zählregel; 0,6 · 0,4 hat zwei Stellen nach dem Komma. Hier wurde eine Stelle zu viel gezählt, das Ergebnis ist zehnmal zu klein; ein kurzer Überschlag macht das sichtbar.'),

  ('kommastellen_zu_wenig',
   'Das Ergebnis hat zu wenige Stellen nach dem Komma, weil das Komma verrutscht ist oder zu grob gerundet wurde.',
   'Bei 0,6 · 0,4 = 2,4 statt 0,24 steht das Komma eine Stelle zu weit rechts, das Ergebnis ist zehnmal zu groß; ein Überschlag zeigt das, denn zwei Zahlen kleiner als 1 ergeben malgenommen wieder eine Zahl kleiner als 1. In anderen Fällen wurde auf weniger Stellen gerundet als verlangt, etwa 3,3 statt 3,32.'),

  ('umgekehrt_geteilt',
   'Beim Teilen wurde die Reihenfolge umgedreht, etwa 1/5 als 5 : 1 gerechnet.',
   'Ein Bruch wie 1/5 bedeutet 1 geteilt durch 5, also 0,2; auch eine Wahrscheinlichkeit ist „passende Fälle geteilt durch alle Fälle“. Wird umgekehrt geteilt, kommt das umgedrehte Verhältnis heraus, oft erkennbar an einem Ergebnis über 1 oder über 100 %.'),

  ('differenz_vergessen',
   'Der letzte Abzug fehlt: angegeben wurde ein Zwischenergebnis statt des gesuchten Winkels.',
   'Gesuchte Winkel ergeben sich oft als Rest, also 180° oder 360° minus die bekannten Winkel. Hier stimmt die Rechnung bis zum Zwischenergebnis, nur der letzte Schritt, das Abziehen, fehlt.'),

  ('einheit_ignoriert',
   'Das Ergebnis wurde nicht in die gefragte Einheit umgerechnet.',
   'Beim Maßstab kommt die echte Länge zunächst in derselben Einheit heraus wie auf der Karte, meist in Zentimetern. Gefragt ist aber Meter oder Kilometer; fehlt dieses Umrechnen, ist die Zahl um ein Vielfaches zu groß, obwohl der Maßstab richtig angewendet wurde.'),

  ('faktor_hundert_statt_sechzig',
   'Beim Umrechnen von Minuten in Stunden wurde durch 100 statt durch 60 geteilt.',
   'Bei Längen und Gewichten wird mit 10, 100 oder 1000 umgerechnet, bei der Zeit dagegen mit 60. Mit der gewohnten 100 ist das Ergebnis zu klein: 168 Minuten werden zu 1,68 statt 2,8 Stunden.'),

  ('flaeche_statt_umfang',
   'Statt des Umfangs wurde die Fläche berechnet.',
   'Umfang und Fläche werden aus denselben Längen berechnet, aber mit verschiedenen Formeln. Weil beide Formeln meist direkt nebeneinander gelernt werden, wird leicht die falsche gewählt; die Rechnung selbst stimmt dann oft.'),

  ('komma_ignoriert',
   'Beim Malnehmen von Kommazahlen wurde das Komma im Ergebnis weggelassen.',
   'Gerechnet wurde mit den Ziffern ohne Komma, etwa 6 · 4 = 24 für 0,6 · 0,4, und das Komma danach nicht wieder gesetzt. Die Ziffern stimmen also, nur die Größe nicht: Das Ergebnis ist um ein Vielfaches zu groß.'),

  ('komma_nicht_verschoben',
   'Beim Teilen durch eine Kommazahl wurde das Komma nicht bei beiden Zahlen verschoben.',
   'Um durch 0,6 zu teilen, verschiebt man das Komma bei beiden Zahlen um eine Stelle: Aus 4,8 : 0,6 wird 48 : 6 = 8. Geschieht das nur bei einer der beiden Zahlen, ist das Ergebnis zehnmal zu klein.'),

  ('liter_kubik_falsch',
   'Beim Umrechnen zwischen Litern und Kubikmaßen wurde der falsche Faktor genommen.',
   '1 Liter ist 1 dm³ oder 1000 cm³, und 1 m³ sind 1000 Liter. Wird dieser Zusammenhang falsch oder gar nicht angewendet, stimmt die Rechnung davor, das Ergebnis liegt aber um den Faktor 10, 1000 oder mehr daneben.'),

  ('mal_zwei_vergessen',
   'Ein nötiges Verdoppeln wurde weggelassen.',
   'Manche Formeln enthalten ein „mal 2“, etwa weil ein Quader jede Seitenfläche zweimal hat oder ein Zylinder zwei Deckel. Fehlt dieser Faktor, stimmt der Rest der Rechnung oft, ein Teil geht aber nur einfach statt doppelt ein, und das Ergebnis weicht entsprechend ab.'),

  ('oberflaeche_statt_volumen',
   'Statt des Rauminhalts wurde die Oberfläche berechnet.',
   'Der Rauminhalt sagt, wie viel in einen Körper hineinpasst, die Oberfläche, wie viel Material seine Außenhaut braucht. Beide werden aus denselben Maßen berechnet, aber mit verschiedenen Formeln, die leicht verwechselt werden.'),

  ('volumen_statt_oberflaeche',
   'Statt der Oberfläche wurde der Rauminhalt berechnet.',
   'Die Oberfläche sagt, wie viel Material die Außenhaut eines Körpers braucht, der Rauminhalt, wie viel hineinpasst. Beide werden aus denselben Maßen berechnet, aber mit verschiedenen Formeln, die leicht verwechselt werden.'),

  ('faktor_hundert_statt_tausend',
   'Beim Umrechnen wurde mit 100 statt mit 1000 gerechnet.',
   'Zwischen Gramm und Kilogramm, Milligramm und Gramm oder Kilogramm und Tonne liegt jeweils der Faktor 1000, nicht 100 wie zwischen Metern und Zentimetern. Mit dem falschen Faktor ist das Ergebnis zehnmal zu groß oder zu klein.'),

  ('nenner_addiert',
   'Beim Addieren von Brüchen wurden Zähler und Nenner jeweils addiert.',
   'Brüche werden zuerst auf einen gemeinsamen Nenner gebracht, danach werden nur die Zähler addiert: 1/2 + 1/6 = 3/6 + 1/6 = 4/6, nicht 2/8. Das Addieren „oben und unten“ liegt nahe, weil man beim Malnehmen von Brüchen tatsächlich oben mit oben und unten mit unten rechnet.'),

  ('stellenwert_ignoriert',
   'Beim Rechnen mit Kommazahlen wurden die Stellen nicht richtig miteinander verrechnet.',
   'Bei 0,25 + 0,4 gehört die 4 zu den Zehnteln, also unter die 2 und nicht unter die 5, und ein Übertrag von einer Stelle zur nächsten muss mitgenommen werden. Wird eine Ziffer der falschen Stelle zugeordnet oder ein Übertrag vergessen, ist das Ergebnis falsch, obwohl jede Einzelrechnung für sich stimmt.'),

  ('additiv_gekuerzt',
   'Beim Kürzen wurde von Zähler und Nenner jeweils 1 abgezogen, statt beide durch dieselbe Zahl zu teilen.',
   'Kürzen heißt, Zähler und Nenner durch dieselbe Zahl zu teilen; dann bleibt der Wert des Bruchs gleich. Wird stattdessen auf beiden Seiten etwas abgezogen, ändert sich der Wert, auch wenn das Ergebnis auf den ersten Blick ähnlich aussieht.'),

  ('falschen_gestuerzt',
   'Beim Teilen von Brüchen wurde der erste statt des zweiten Bruchs umgedreht.',
   'Durch einen Bruch teilt man, indem man mit dem umgedrehten zweiten Bruch malnimmt. Wird stattdessen der erste umgedreht, kommt genau das Umgekehrte der richtigen Lösung heraus.'),

  ('hauptnenner_bei_mult',
   'Beim Malnehmen von Brüchen wurde auf einen gemeinsamen Nenner gebracht und addiert.',
   'Den gemeinsamen Nenner braucht man nur beim Addieren und Subtrahieren. Beim Malnehmen rechnet man einfach Zähler mal Zähler und Nenner mal Nenner; hier wurde die Regel fürs Addieren auf das Malnehmen übertragen.'),

  ('komma_als_trenner',
   'Die Ziffern hinter dem Komma wurden als eigene Einheit gelesen, etwa 2,5 h als 2 h 5 min.',
   'Das Komma trennt Ganze von Bruchteilen: 2,5 h sind zweieinhalb Stunden, also 150 Minuten. Hier wurde das Komma wie ein Trennzeichen zwischen zwei Einheiten gelesen, so wie bei „2 h 5 min“ oder „3 kg 4 g“.'),

  ('nenner_addiert_zaehler_ok',
   'Beim Addieren von Brüchen wurden die Zähler richtig umgerechnet, die Nenner aber addiert.',
   'Die Zähler wurden schon auf einen gemeinsamen Nenner umgerechnet, als Nenner wurde dann aber die Summe der beiden alten Nenner genommen. Der Rechenweg ist also fast vollständig, nur der Nenner im Ergebnis stimmt nicht.'),

  ('nicht_gestuerzt',
   'Beim Teilen von Brüchen wurde der zweite Bruch nicht umgedreht.',
   'Durch einen Bruch teilt man, indem man mit dem umgedrehten Bruch malnimmt: 2/3 : 4/5 = 2/3 · 5/4. Hier wurde ohne das Umdrehen malgenommen, also die Regel fürs Malnehmen angewendet.'),

  ('zaehler_nicht_erweitert',
   'Beim Addieren von Brüchen wurde der gemeinsame Nenner gebildet, die Zähler aber nicht mit umgerechnet.',
   'Wird der Nenner vergrößert, muss der Zähler im selben Verhältnis mitwachsen: Aus 1/4 wird 3/12, nicht 1/12. Hier wurden die alten Zähler einfach addiert, der gemeinsame Nenner selbst ist richtig.'),

  ('ziffern_gelesen',
   'Zähler und Nenner wurden hinter das Komma geschrieben, etwa 1/5 als 0,15.',
   'Ein Bruch ist eine Teilung: 1/5 heißt 1 : 5 = 0,2. Werden die beiden Zahlen einfach hintereinander hinter das Komma geschrieben, wird der Bruch wie eine Schreibweise behandelt und nicht wie eine Rechnung.'),

  ('zwei_kanten',
   'Für den Rauminhalt des Quaders wurden nur zwei der drei Kanten malgenommen.',
   'Der Rauminhalt eines Quaders ist Länge mal Breite mal Höhe, also drei Maße. Mit nur zwei davon erhält man die Fläche einer Seite, nicht den Rauminhalt.'),

  ('fuehrende_null_ignoriert',
   'Die Null direkt hinter dem Komma wurde übersehen, etwa 1,05 m als 150 cm.',
   'Bei 1,05 m steht die 5 an der zweiten Stelle nach dem Komma; es sind also 5 cm und nicht 50 cm. Wird die Null überlesen, rutscht die Ziffer an die falsche Stelle, und das Ergebnis ist zu groß.'),

  ('halbieren_faelschlich',
   'Beim Parallelogramm wurde mit der Dreiecksformel gerechnet, also mit einem Halbieren, das dort nicht hingehört.',
   'Die Formel „Grundseite mal Höhe geteilt durch 2“ gilt für Dreiecke; ein Parallelogramm ist doppelt so groß wie das Dreieck mit gleicher Grundseite und Höhe. Mit der Dreiecksformel kommt die Fläche halb so groß und eine gesuchte Höhe doppelt so groß heraus.'),

  ('immer_aufgerundet',
   'Es wurde aufgerundet, obwohl abgerundet werden muss.',
   'Ob auf- oder abgerundet wird, entscheidet die erste Ziffer, die wegfällt: bei 0 bis 4 wird abgerundet, bei 5 bis 9 aufgerundet. Hier wurde unabhängig davon aufgerundet, das Ergebnis liegt deshalb eine Einheit der letzten Stelle zu hoch.'),

  ('nur_einmal_addiert',
   'Ein Betrag wurde nur einmal dazugezählt, obwohl er mehrfach vorkommt.',
   'Ein Rechteck hat zwei lange und zwei kurze Seiten, und eine Gerade mit der Steigung 2 steigt bei drei Schritten nach rechts um dreimal 2. Hier wurde jeweils nur einmal addiert; das Ergebnis ist deshalb zu klein.'),

  ('nur_eine_seite',
   'Für die Fläche des Rechtecks wurde nur eine Seite mit sich selbst malgenommen.',
   'Die Fläche eines Rechtecks ist Länge mal Breite. Hier wurde wie beim Quadrat gerechnet, bei dem beide Seiten gleich lang sind; die zweite Seite blieb unbeachtet.'),

  ('seite_vergessen',
   'Beim Umfang des Dreiecks wurde eine Seite vergessen.',
   'Der Umfang ist die Summe aller Seiten, beim Dreieck also aller drei. Hier wurden nur zwei Seiten addiert; das Ergebnis ist genau um eine Seitenlänge zu klein.'),

  ('summe_180_statt_360',
   'Im Viereck wurde mit 180° statt mit 360° gerechnet.',
   'Die Winkel im Dreieck ergeben zusammen 180°, die im Viereck 360°. Mit der Dreieckssumme bleibt für den letzten Winkel zu wenig übrig, hier sogar ein negativer Wert.'),

  ('uebertrag_vergessen',
   'Beim Addieren von Kommazahlen wurde der Übertrag vor das Komma vergessen.',
   '0,8 + 0,7 sind 15 Zehntel, also 1,5. Hier wurden die 15 Zehntel als 0,15 hingeschrieben, statt zehn davon als ganze Eins vor das Komma zu übertragen.');

do $w5a$
declare
  v_neu integer;
  v_erg integer;
begin
  if exists (select 1 from w5a_entwurf where slug = 'teilgekuerzt') then
    raise exception 'W5-a: teilgekuerzt bleibt laut F14 unbestückt';
  end if;

  insert into public.fehlbild_labels (slug, klartext, erklaerung)
  select slug, klartext, erklaerung from w5a_entwurf
  on conflict (slug) do nothing;
  get diagnostics v_neu = row_count;

  update public.fehlbild_labels l
     set klartext   = case when l.klartext is null or btrim(l.klartext) = ''
                           then e.klartext else l.klartext end,
         erklaerung = case when l.erklaerung is null or btrim(l.erklaerung) = ''
                           then e.erklaerung else l.erklaerung end
    from w5a_entwurf e
   where l.slug = e.slug
     and l.freigegeben_am is null
     and (   l.klartext is null or btrim(l.klartext) = ''
          or l.erklaerung is null or btrim(l.erklaerung) = '');
  get diagnostics v_erg = row_count;

  if v_neu + v_erg > 52 then
    raise exception 'W5-a: % Zeilen berührt, höchstens 52 erwartet', v_neu + v_erg;
  end if;
  raise notice 'W5-a: % Slugs neu angelegt, % ergänzt', v_neu, v_erg;
end
$w5a$;

drop table w5a_entwurf;
