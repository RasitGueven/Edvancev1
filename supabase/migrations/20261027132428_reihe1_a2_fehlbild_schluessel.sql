-- Reihe 1 · A2.2a Fehlbild-Schluessel der Reihe "Quadratische Funktionen und Gleichungen" (Konzept §4 und §8).
-- Neu im Katalog fehlbild_labels: die acht Schluessel der Videos (§8) und je Denkfehler aus §4 einer
-- (docs/reihe1/A/ist-analyse.md §14). klartext beschreibt den Denkfehler kurz fuer Coach und Lena; die Rueckmeldung
-- ans Kind steht je Bauform im Steckbrief. freigegeben_am bleibt leer: die Freigabe macht ein Admin wie bei jedem
-- Katalogeintrag. Nur einfuegen, nie ueberschreiben (on conflict do nothing). Auftrag B nutzt die Schluessel.
--
-- Pruefabfrage: select count(*) from fehlbild_labels where slug like 'qf\_%';   → 39
insert into public.fehlbild_labels (slug, klartext, familie) values
  -- §8 (Videos V1–V8)
  ('qf_quadrat_negativ',            'Hält das Quadrat einer negativen Zahl für negativ: (−2)² = −4.',                         'potenzen_wurzeln'),
  ('qf_streckfaktor_umgekehrt',     'Verwechselt die Wirkung von a: größeres a als weiter statt enger gelesen.',              'geraden_schaubilder'),
  ('qf_verschiebung_vorzeichen',    'Liest das Vorzeichen in der Klammer falsch: (x − 3)² als Verschiebung nach links.',      'vorzeichen'),
  ('qf_ergaenzung_nicht_abgezogen', 'Gibt bei der quadratischen Ergänzung (b/2)² dazu, zieht es aber nicht wieder ab.',      'schritt_vergessen'),
  ('qf_nur_positive_loesung',       'Gibt bei x² = c nur die positive Lösung an.',                                           'gleichungen_umformen'),
  ('qf_null_vergessen',             'Übersieht beim Nullprodukt die Lösung x = 0.',                                          'gleichungen_umformen'),
  ('qf_halbes_p_nicht_quadriert',   'Nimmt in der p-q-Formel p/2 statt (p/2)² unter der Wurzel.',                            'schritt_vergessen'),
  ('qf_scheitel_statt_nullstelle',  'Gibt den Scheitelpunkt statt der Nullstellen an.',                                      'geraden_schaubilder'),
  -- §4 (Bauformen)
  ('qf_ax_statt_ax2',               'Rechnet a·x statt a·x²: das Quadrieren fehlt.',                                          'schritt_vergessen'),
  ('qf_ax_quadriert',               'Rechnet (a·x)² statt a·x²: auch a wird quadriert.',                                     'klammern'),
  ('qf_oeffnung_vertauscht',        'Verwechselt nach oben und nach unten geöffnet.',                                        'geraden_schaubilder'),
  ('qf_d_e_vertauscht',             'Vertauscht die Verschiebung nach rechts (d) und nach oben (e).',                        'geraden_schaubilder'),
  ('qf_scheitel_koordinaten_vertauscht', 'Vertauscht x- und y-Koordinate eines Punktes.',                                   'geraden_schaubilder'),
  ('qf_a_als_koordinate',           'Nimmt den Streckfaktor a als Koordinate des Scheitels.',                                'geraden_schaubilder'),
  ('qf_streckfaktor_vergessen',     'Lässt den Streckfaktor a weg.',                                                         'schritt_vergessen'),
  ('qf_oeffnung_aus_e',             'Liest die Öffnung der Parabel aus e statt aus a.',                                       'geraden_schaubilder'),
  ('qf_binom_quadrat_differenz',    'Rechnet (x − d)² = x² − d².',                                                           'klammern'),
  ('qf_binom_mittelglied_fehlt',    'Vergisst beim Quadrat einer Summe das Glied 2·d·x.',                                    'klammern'),
  ('qf_binom_vorzeichen',           'Setzt das Vorzeichen des Mittelglieds falsch.',                                         'klammern'),
  ('qf_ergaenzung_b_statt_halb',    'Setzt b statt b/2 in die Klammer der Scheitelpunktform.',                               'schritt_vergessen'),
  ('qf_ausklammern_a_verloren',     'Verliert a beim Ausklammern.',                                                          'klammern'),
  ('qf_ergaenzung_ohne_a',          'Multipliziert die Ergänzung nicht mit dem ausgeklammerten a.',                          'schritt_vergessen'),
  ('qf_wurzel_als_haelfte',         'Rechnet die Wurzel als Hälfte: √36 = 18.',                                              'potenzen_wurzeln'),
  ('qf_wurzel_aus_negativ',         'Gibt bei x² = c mit c < 0 trotzdem Lösungen an.',                                       'potenzen_wurzeln'),
  ('qf_umstellen_reihenfolge',      'Teilt oder zieht die Wurzel, bevor der Summand auf die andere Seite gebracht ist.',     'gleichungen_umformen'),
  ('qf_durch_a_vergessen',          'Teilt nicht durch den Faktor vor x bzw. x².',                                           'gleichungen_umformen'),
  ('qf_nullprodukt_vorzeichen',     'Liest die Lösungen aus den Faktoren mit falschem Vorzeichen: (x − 3) = 0 gibt −3.',      'vorzeichen'),
  ('qf_a_uebersehen',               'Übersieht beim Nullprodukt den Faktor a in der zweiten Lösung.',                         'gleichungen_umformen'),
  ('qf_durch_x_geteilt',            'Teilt die Gleichung durch x und verliert so die Lösung x = 0.',                          'gleichungen_umformen'),
  ('qf_p_vorzeichen',               'Setzt −p/2 mit falschem Vorzeichen ein.',                                               'vorzeichen'),
  ('qf_q_vorzeichen',               'Setzt q mit falschem Vorzeichen ein.',                                                  'vorzeichen'),
  ('qf_nur_eine_loesung',           'Gibt nur eine von zwei Lösungen an.',                                                   'gleichungen_umformen'),
  ('qf_e_vorzeichen',               'Bringt e mit falschem Vorzeichen auf die andere Seite.',                                'vorzeichen'),
  ('qf_stelle_statt_wert',          'Gibt die Stelle (x bzw. t) statt des gesuchten Werts an.',                               'sachaufgaben'),
  ('qf_hoch_tief_verwechselt',      'Verwechselt Hochpunkt und Tiefpunkt.',                                                   'geraden_schaubilder'),
  ('qf_umfang_statt_flaeche',       'Maximiert den Umfang statt der Fläche.',                                                 'rechenart_formel'),
  ('qf_ausklammern_unvollstaendig', 'Klammert nicht den ganzen gemeinsamen Faktor aus.',                                      'klammern'),
  ('qf_einsetzen_vorzeichen',       'Setzt eine negative Zahl ohne Klammer ein: −3² statt (−3)².',                           'vorzeichen'),
  ('qf_gegenoperation_vorzeichen',  'Wechselt beim Umstellen das Vorzeichen nicht.',                                         'vorzeichen')
on conflict (slug) do nothing;

do $$
begin
  if (select count(*) from public.fehlbild_labels where slug like 'qf\_%') < 39 then
    raise exception 'reihe1_a2: nicht alle 39 qf_-Schluessel im Katalog';
  end if;
end $$;
