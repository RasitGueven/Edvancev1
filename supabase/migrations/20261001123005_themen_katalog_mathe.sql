-- ============================================================================
-- Themenkatalog Mathematik Klasse 5–10 (W1-4, Migration 2 von 3 — Daten)
-- ============================================================================
--
-- Themen auf der Ebene der Unterrichtsvorhaben, wie sie die Koelner
-- Schulplaene benutzen, geordnet nach den Stufen des Kernlehrplans Mathematik
-- G9 NRW (2019):
-- https://lehrplannavigator.nrw.de/system/files/media/document/file/g9_m_klp_3401_2019_06_23_0.pdf
--
-- klp: Kompetenzerwartungen als '<Inhaltsfeld>-<Nr>' mit der Nummer aus dem
-- KLP; die Nummern beginnen je Stufe neu (siehe docs/themen/phase0.md).
-- schlagworte: Fachbegriffe, Woerter von Kindern, Titel aus Schulplaenen.
-- klasse ist veraltet und traegt die erste Klasse der Stufe (5, 7, 9).
--
-- Die 8 bestehenden Keys bleiben und werden ueberschrieben, nicht verdoppelt.
-- daten_streumasse wandert in die Erprobungsstufe: Haeufigkeiten, Mittelwert,
-- Median, Spannweite und Boxplot stehen dort im KLP (Sto-1 bis Sto-6), die
-- Erste Stufe hat keine Statistik.

insert into public.themen (thema_key, fach, klasse, stufe, sort, label, klp, schlagworte) values
-- Erprobungsstufe (5/6) -------------------------------------------------------
('natuerliche_zahlen', 'mathematik', 5, 'erprobung', 10, 'Natürliche Zahlen und Größen',
  '{Ari-8,Ari-9,Ari-10}',
  '{natürliche zahlen,große zahlen,stellenwerttafel,zahlenstrahl,runden,überschlag,größen,einheiten umrechnen,geld,längen,gewichte,zeit,millionen,zahlen darstellen}'),
('rechnen_natuerliche_zahlen', 'mathematik', 5, 'erprobung', 20, 'Rechnen mit natürlichen Zahlen',
  '{Ari-3,Ari-4,Ari-5,Ari-6,Ari-7,Ari-14,Fkt-3}',
  '{grundrechenarten,schriftlich rechnen,schriftliche division,plus minus mal geteilt,rechengesetze,kommutativgesetz,distributivgesetz,klammern zuerst,punkt vor strich,rechenterm,variablen,zahlenmuster,kopfrechnen}'),
('daten_streumasse', 'mathematik', 5, 'erprobung', 30, 'Daten, Diagramme und Kenngrößen',
  '{Sto-1,Sto-2,Sto-3,Sto-4,Sto-5,Sto-6}',
  '{daten,strichliste,säulendiagramm,kreisdiagramm,diagramme,häufigkeit,relative häufigkeit,mittelwert,durchschnitt,median,spannweite,quartile,boxplot,umfrage,statistik}'),
('geometrische_grundbegriffe', 'mathematik', 5, 'erprobung', 40, 'Geometrische Grundbegriffe und Figuren',
  '{Geo-1,Geo-2,Geo-4,Geo-6}',
  '{strecke,gerade,strahl,parallel,senkrecht,orthogonal,abstand,koordinatensystem,vierecke,rechteck,quadrat,parallelogramm,trapez,raute,geodreieck}'),
('symmetrie', 'mathematik', 5, 'erprobung', 50, 'Symmetrie und Abbildungen',
  '{Geo-5,Geo-7,Geo-8,Geo-14}',
  '{symmetrie,achsensymmetrie,punktsymmetrie,spiegelachse,spiegeln,verschieben,drehen,drehung,spiegelbild,muster,geometriesoftware,geogebra}'),
('teilbarkeit', 'mathematik', 5, 'erprobung', 60, 'Teilbarkeit und Primzahlen',
  '{Ari-1,Ari-2}',
  '{teiler,vielfache,teilbarkeitsregeln,primzahlen,primfaktorzerlegung,ggt,kgv,quersumme,teilbar durch 3,teilermenge}'),
('flaeche_umfang', 'mathematik', 5, 'erprobung', 70, 'Flächen und Umfang',
  '{Geo-10,Geo-11,Geo-12,Geo-13}',
  '{flächeninhalt,umfang,rechteck,quadrat,flächeneinheiten,quadratzentimeter,zerlegen,ergänzen,rechtwinkliges dreieck,kästchen zählen,maßstab}'),
('koerper_quader', 'mathematik', 5, 'erprobung', 80, 'Körper, Netze und Quadervolumen',
  '{Geo-3,Geo-11,Geo-15}',
  '{körper,würfel,quader,netz,würfelnetz,schrägbild,oberfläche,volumen,rauminhalt,kubikzentimeter,liter,pyramide,zylinder,kegel,kugel}'),
('brueche', 'mathematik', 5, 'erprobung', 90, 'Brüche und Anteile',
  '{Ari-11,Ari-12,Ari-13}',
  '{brüche,bruch,anteile,bruchteil,zähler,nenner,kürzen,erweitern,gemischte zahlen,brüche vergleichen,prozent einstieg,pizza,hälfte drittel viertel}'),
('rechnen_brueche_dezimalzahlen', 'mathematik', 5, 'erprobung', 100, 'Rechnen mit Brüchen und Dezimalzahlen',
  '{Ari-8,Ari-14}',
  '{brüche addieren,brüche multiplizieren,brüche dividieren,kehrwert,hauptnenner,dezimalzahlen,kommazahlen,periodische dezimalzahlen,brüche in dezimalzahlen,komma verschieben,rechnen mit brüchen}'),
('winkel', 'mathematik', 5, 'erprobung', 110, 'Winkel und Kreise',
  '{Geo-1,Geo-4,Geo-9}',
  '{winkel,winkel messen,winkel zeichnen,spitzer winkel,stumpfer winkel,rechter winkel,überstumpfer winkel,geodreieck,grad,kreis,zirkel,radius,durchmesser}'),
('ganze_zahlen_groessen', 'mathematik', 5, 'erprobung', 120, 'Negative Zahlen, Zuordnungen und Dreisatz',
  '{Ari-15,Fkt-1,Fkt-2,Fkt-4}',
  '{negative zahlen,minuszahlen,ganze zahlen,temperatur,kontostand,zahlengerade,dreisatz,zuordnung,tabelle,diagramm,maßstab,zusammenhang zwischen größen}'),
-- Erste Stufe (7/8) -----------------------------------------------------------
('rationale_zahlen', 'mathematik', 7, 'erste', 210, 'Rationale Zahlen',
  '{Ari-1,Ari-2,Ari-3}',
  '{rationale zahlen,negative zahlen,minus mal minus,vorzeichenregeln,zahlengerade,betrag,gegenzahl,rechnen mit negativen zahlen,ordnen,ganze zahlen}'),
('zuordnungen', 'mathematik', 7, 'erste', 220, 'Proportionale und antiproportionale Zuordnungen',
  '{Fkt-1,Fkt-2,Fkt-7}',
  '{zuordnungen,proportional,antiproportional,dreisatz,quotientengleich,produktgleich,proportionalitätsfaktor,je mehr desto mehr,je mehr desto weniger,wertetabelle,graph,ursprungsgerade}'),
('zinsrechnung', 'mathematik', 7, 'erste', 230, 'Prozent- und Zinsrechnung',
  '{Fkt-8,Fkt-9,Ari-8}',
  '{prozent,prozentrechnung,grundwert,prozentwert,prozentsatz,zinsen,zinsrechnung,zinseszins,sparbuch,kredit,rabatt,mehrwertsteuer,wachstumsfaktor,tabellenkalkulation}'),
('terme_gleichungen', 'mathematik', 7, 'erste', 240, 'Terme und Gleichungen',
  '{Ari-4,Ari-5,Ari-6,Ari-7,Ari-9}',
  '{terme,variablen,gleichungen,gleichungen lösen,äquivalenzumformung,termumformung,ausmultiplizieren,zusammenfassen,gleichungen aus sachsituationen,textaufgaben,ungleichungen,probe}'),
('winkel_dreiecke', 'mathematik', 7, 'erste', 250, 'Winkelsätze, Dreiecke und Konstruktionen',
  '{Geo-1,Geo-2,Geo-3,Geo-4,Geo-5}',
  '{winkelsätze,nebenwinkel,scheitelwinkel,stufenwinkel,wechselwinkel,innenwinkelsumme,180 grad,basiswinkel,gleichschenklig,kongruenz,kongruenzsätze,dreieck konstruieren,konstruieren und argumentieren,kongruenzsatz sws}'),
('lineare_funktionen', 'mathematik', 7, 'erste', 260, 'Lineare Funktionen',
  '{Fkt-3,Fkt-4,Fkt-5,Fkt-6,Fkt-7}',
  '{lineare funktionen,funktion,gerade,steigung,steigungsdreieck,y-achsenabschnitt,y gleich mx plus b,funktionsgleichung,wertetabelle,graph zeichnen,nullstelle,schnittpunkt,parallele geraden}'),
('terme_binomische_formeln', 'mathematik', 7, 'erste', 270, 'Terme mit mehreren Variablen und binomische Formeln',
  '{Ari-5,Ari-7}',
  '{binomische formeln,binomisch,a plus b zum quadrat,ausmultiplizieren,klammern auflösen,faktorisieren,ausklammern,summen multiplizieren,terme mit mehreren variablen,produkte von summen,bruchterme}'),
('zufallsexperimente', 'mathematik', 7, 'erste', 280, 'Zufall und Wahrscheinlichkeit',
  '{Sto-1,Sto-2,Sto-3,Sto-4,Sto-5}',
  '{wahrscheinlichkeit,zufall,zufallsexperiment,würfeln,münzwurf,baumdiagramm,pfadregeln,laplace,ereignis,ergebnis,relative häufigkeit,gesetz der großen zahlen,zweistufig,simulation}'),
('flaechen_vielecke', 'mathematik', 7, 'erste', 290, 'Flächen von Dreiecken und Vierecken',
  '{Geo-8}',
  '{flächeninhalt,dreieck,parallelogramm,trapez,drachen,raute,vielecke,zusammengesetzte figuren,grundseite,höhe,grundseite mal höhe durch zwei,flächen}'),
('lineare_gleichungen_lgs', 'mathematik', 7, 'erste', 300, 'Lineare Gleichungssysteme',
  '{Ari-6,Ari-9,Ari-10}',
  '{lineare gleichungssysteme,lgs,zwei gleichungen,zwei unbekannte,einsetzungsverfahren,gleichsetzungsverfahren,additionsverfahren,schnittpunkt zweier geraden,grafisch lösen,lineare gleichungen,lösungsmenge}'),
('thales_konstruktionen', 'mathematik', 7, 'erste', 310, 'Kreise und Dreiecke: Thales und besondere Linien',
  '{Geo-3,Geo-6,Geo-7}',
  '{thales,satz des thales,thaleskreis,umkreis,inkreis,mittelsenkrechte,winkelhalbierende,seitenhalbierende,schwerpunkt,konstruktion,zirkel und lineal,kreis,ortslinie}'),
-- Zweite Stufe (9/10) ---------------------------------------------------------
('reelle_zahlen', 'mathematik', 9, 'zweite', 410, 'Reelle Zahlen und Wurzeln',
  '{Ari-2,Ari-5,Ari-6,Ari-7,Ari-9}',
  '{reelle zahlen,irrationale zahlen,wurzel,quadratwurzel,wurzelgesetze,wurzel ziehen,radizieren,zahlen die nie aufhören,heron-verfahren,intervallschachtelung,pi,wurzel aus 2}'),
('potenzen', 'mathematik', 9, 'zweite', 420, 'Potenzen',
  '{Ari-1,Ari-3,Ari-4,Ari-5}',
  '{potenzen,potenzgesetze,hochzahl,exponent,basis,zehnerpotenzen,wissenschaftliche schreibweise,negative exponenten,hoch minus,n-te wurzel,große und kleine zahlen}'),
('quadratische_funktionen', 'mathematik', 9, 'zweite', 430, 'Quadratische Funktionen',
  '{Fkt-1,Fkt-2,Fkt-3,Fkt-4,Fkt-5,Fkt-6,Fkt-8,Fkt-9,Fkt-12}',
  '{quadratische funktionen,parabel,normalparabel,scheitelpunkt,scheitelpunktform,normalform,strecken stauchen verschieben,nullstellen,x quadrat,öffnung,extremwertprobleme,faktorisierte form}'),
('quadratische_gleichungen', 'mathematik', 9, 'zweite', 440, 'Quadratische Gleichungen',
  '{Ari-8,Ari-11}',
  '{quadratische gleichungen,pq-formel,p-q-formel,mitternachtsformel,abc-formel,quadratische ergänzung,satz von vieta,diskriminante,x quadrat gleichung,lösungsformel,nullprodukt}'),
('pythagoras', 'mathematik', 9, 'zweite', 450, 'Satz des Pythagoras',
  '{Geo-1,Geo-10}',
  '{pythagoras,satz des pythagoras,a quadrat plus b quadrat,hypotenuse,kathete,rechtwinkliges dreieck,raumdiagonale,höhensatz,kathetensatz,satzgruppe des pythagoras,längen berechnen}'),
('aehnlichkeit', 'mathematik', 9, 'zweite', 460, 'Ähnlichkeit und zentrische Streckung',
  '{Geo-2,Geo-9}',
  '{ähnlichkeit,ähnliche figuren,zentrische streckung,streckfaktor,streckzentrum,strahlensatz,strahlensätze,vergrößern,verkleinern,maßstab,ähnliche dreiecke}'),
('kreis', 'mathematik', 9, 'zweite', 470, 'Kreis: Umfang und Fläche',
  '{Geo-3,Geo-4}',
  '{kreis,kreisumfang,kreisfläche,pi,radius,durchmesser,kreisbogen,kreissektor,kreisausschnitt,kreisring,tangente,kreiszahl}'),
('prismen_zylinder', 'mathematik', 9, 'zweite', 480, 'Prismen und Zylinder',
  '{Geo-5,Geo-6}',
  '{prisma,prismen,zylinder,oberfläche,oberflächeninhalt,volumen,mantelfläche,grundfläche mal höhe,netz,schrägbild,cavalieri,körper}'),
('koerper_pyramide_kegel_kugel', 'mathematik', 9, 'zweite', 490, 'Pyramide, Kegel und Kugel',
  '{Geo-5,Geo-6,Geo-10}',
  '{pyramide,kegel,kugel,volumen,oberfläche,mantelfläche,ein drittel grundfläche mal höhe,körper,körperberechnung,zusammengesetzte körper,cavalieri}'),
('trigonometrie', 'mathematik', 9, 'zweite', 500, 'Trigonometrie',
  '{Geo-7,Geo-8,Geo-9,Geo-10}',
  '{trigonometrie,sinus,kosinus,tangens,sin cos tan,gegenkathete,ankathete,kosinussatz,sinussatz,winkel berechnen,rechtwinkliges dreieck,steigungswinkel}'),
('exponentialfunktionen', 'mathematik', 9, 'zweite', 510, 'Exponentielles Wachstum',
  '{Fkt-10,Fkt-11,Fkt-12,Ari-10}',
  '{exponentialfunktion,exponentielles wachstum,wachstum,zerfall,wachstumsfaktor,wachstumsrate,verdopplungszeit,halbwertszeit,zinseszins,lineares wachstum,exponentialgleichung,logarithmus}'),
('sinusfunktion', 'mathematik', 9, 'zweite', 520, 'Sinusfunktion und periodische Vorgänge',
  '{Fkt-13,Fkt-14}',
  '{sinusfunktion,kosinusfunktion,periodisch,periode,amplitude,einheitskreis,bogenmaß,schwingung,riesenrad,ebbe und flut,welle}'),
('bedingte_wahrscheinlichkeit', 'mathematik', 9, 'zweite', 530, 'Bedingte Wahrscheinlichkeit',
  '{Sto-3,Sto-4,Sto-5}',
  '{bedingte wahrscheinlichkeit,vierfeldertafel,baumdiagramm,umgekehrtes baumdiagramm,unabhängigkeit,stochastisch unabhängig,pfadregeln,kombinatorik,mehrstufige zufallsexperimente,medizinischer test}'),
('statistik_beurteilen', 'mathematik', 9, 'zweite', 540, 'Statistische Erhebungen beurteilen',
  '{Sto-1,Sto-2,Sto-6}',
  '{statistik,datenerhebung,umfrage,diagramme manipulieren,irreführende diagramme,boxplot,mittelwert,median,stichprobe,tabellenkalkulation,daten auswerten}')
on conflict (thema_key) do update
   set fach        = excluded.fach,
       klasse      = excluded.klasse,
       stufe       = excluded.stufe,
       sort        = excluded.sort,
       label       = excluded.label,
       klp         = excluded.klp,
       schlagworte = excluded.schlagworte;

-- ============================================================================
-- Einstiegsknoten fuer die LSA — nur fuer vorhandene Knoten
-- ============================================================================
--
-- Die Knoten der laufenden Themen-Laeufe (Lineare Funktionen, Zins, Kreis)
-- werden spaeter zugeordnet.

insert into public.thema_einstieg (thema_key, skill_key)
select 'terme_binomische_formeln', skill_key
  from public.skills
 where skill_key like 'term\_binom\_%'
union all
select 'terme_gleichungen', skill_key
  from public.skills
 where skill_key = 'gleichung_modellieren'
on conflict do nothing;
