# Slots S3 — offene Punkte

Stand: 15.10.2026 · Paket S3 · Branch `feat/rasit-slots-s3-heute` (ab `origin/dev` 8ab4fae)

## Was am Datenvertrag fehlte

Nichts. `slots_tag` liefert je Raum-Termin `zeit_id`, `raum_id`, `coach_id`, `art` und `session_id`, je Session ohne
Raum die `session_id`. Keine Änderung an `src/lib/supabase/**`, keine Migration.

## Abweichungen

1. **„Coach fällt aus“ ohne Session zählt wie „ohne Coach“.** Ein Raum-Termin mit `art = 'faellt_aus'` kann noch eine
   `coach_id` tragen (den ausgefallenen Coach). „Session öffnen“ würde dann eine Session für jemanden festschreiben, der
   nicht kommt. Er bekommt deshalb den Satz „Kein Coach eingeteilt“ mit Link zur Termin-Seite, dort wird die Vertretung
   gesetzt. Hat er schon eine Session, steht „Live-Sicht“ da wie bei jedem anderen Termin.
2. **Eigener Knopf statt `useSessionOeffnen` aus Meine Einsätze.** Der Hook liegt in `src/pages/coach/**` und meldet
   den Fehler für die ganze Liste. Admin-„Heute“ zeigt ihn an der Zeile; der Ablauf (anlegen → Live-Sicht, Fehler über
   `slotsFehlerSchluessel`) ist derselbe. Coach-Dateien sind unverändert.
3. **Bestehender Test „Offen geblieben“ eingegrenzt.** Er suchte den einzigen Link „Live-Sicht“ auf der Seite; seit S3
   gibt es mehrere. Er sucht jetzt nur in der Karte „Offen geblieben“.
4. **Raum-Termin ohne Session und ohne Kinder: kein Knopf** (Nachtrag Rasit, PR #253). Bei `belegt = 0` steht rechts
   nur „Noch keine Kinder“, ohne Link. Grund: offene-punkte-sl2b Punkt 2 — eine leere Session legt die Art des Termins
   fest und sperrt danach Testkinder bzw. echte Kinder per SL013. Das gilt mit und ohne Coach; hat der Termin schon eine
   Session, bleibt es bei „Live-Sicht“.

## Offene Punkte

5. **Doppelte Aussage bei Terminen ohne Coach.** Die Unterzeile sagt schon „ohne Coach“, rechts steht zusätzlich
   „Kein Coach eingeteilt“ (so verlangt). Wenn das zu laut ist: Unterzeile bei diesen Zeilen leer lassen.
6. **Lernstandsanalysen ohne Aktion.** Die LSA-Zeilen in derselben Liste haben weiter keinen Knopf (nicht Teil von S3).
7. **Kein Nachladen nach „Session öffnen“.** Die Seite wechselt sofort in die Live-Sicht; wer zurückgeht, lädt
   Admin-„Heute“ neu und sieht dann „Live-Sicht“. Scheitert das Anlegen, bleibt der Knopf stehen.
