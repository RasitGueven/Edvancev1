# Von A an C · Folgen der Pool-Trennung für die Session (Stand 27.10.2026)

**Kurz:** Ab Migration `20261027130250_reihe1_a1_pool_trennung` ist jede heutige Aufgabe nur noch LSA.
Bis zur ersten Freigabe von Bauform-Instanzen zieht die Session **nichts** (Entscheidung Rasit, 27.10.2026,
Punkt 5). C zeigt dann einen ruhigen Leerzustand statt eines Fehlers.

## Was A geändert hat

- `tasks.einsatz`: alle 1184 Aufgaben mit `{lsa,session}` sind jetzt `{lsa}`. Der Default entfällt, die Regel
  `tasks_einsatz_ein_pool` verbietet beide zugleich.
- `session_naechster_schritt` fasst A nicht an. Die heutige Auswahl filtert schon über `session_im_pool`
  (`'session' = any(einsatz)`), über `session_aufgabe_waehlen` und `aufgabe_ausgeben`. Die Datenänderung reicht,
  damit die Session keine LSA-Aufgabe mehr zieht (pgTAP `reihe1_a1_pool`, Fälle 3).

## Was C beachten muss

1. **Leerer Pool ist der Normalfall, bis Bauform-Instanzen freigegeben sind.** `session_aufgabe_waehlen` liefert
   `task_id = null` für jeden Skill. Was `session_naechster_schritt` dann heute zurückgibt, hängt am Planer
   (`session_schritt_planen`): im Testlauf ist das in pgTAP `session_f1` Fall 6 `art = 'warten'`. C soll dafür auf
   dem Tablet einen ruhigen Leerzustand zeigen (kein Fehlertext, kein Spinner ohne Ende) und in der Coach-Sicht
   einen sachlichen Hinweis „Für diesen Skill gibt es noch keine freigegebenen Session-Aufgaben“.
2. **Neue Auswahl über A-Funktionen.** Sobald `aufgabe_ziehen(p_kind, p_skill, p_rolle, p_stufe, p_ausschluss)`
   den Kommentar `reihe1 fertig` trägt, zieht C darüber (Pool session, Bauform freigegeben, Instanz ready und
   nicht pausiert, genau die Rolle). Für die Rollen `uebung` und `warmup` fällt `aufgabe_ziehen` auf vorhandene,
   freigegebene Session-Aufgaben ohne Bauform zurück; nach A1 gibt es davon keine.
3. **Mini-Checks (`{check}`) und Quests (`{quest}`) sind nicht betroffen.**
4. **Testdaten:** Zwölf Aufgaben waren vor A1 schon in LSA und Session gezogen; es sind Testdaten (Entscheidung
   Rasit, Punkt 4). Ihre `session_ausgegeben`-Zeilen bleiben, sie werden nur nicht mehr gezogen.
