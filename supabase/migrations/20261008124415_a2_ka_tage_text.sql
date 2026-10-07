-- A2: Beschreibung der Stellschraube ka_tage an Entscheidung A2 I angepasst (Rasit 06.10.):
-- Im Fall Klassenarbeit pausiert das Mischen nicht, es mischt nur im Thema der Klassenarbeit.
-- Nur der Text; Wert, Startwert und Spanne bleiben.

update public.session_einstellungen
   set beschreibung = 'Klassenarbeit zählt, wenn sie höchstens so viele Tage entfernt ist (einschließlich); gemischt wird dann nur im Thema der Klassenarbeit'
 where schluessel = 'ka_tage';
