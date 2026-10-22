# Retro 22.10.2026 – LSA-V2: Ausblick, „Weiß ich nicht“ ohne Zweitbeleg, Deckel 40

## Ausgang
Max (nichts falsch) war nach gut 5 Minuten fertig, Jonas (oft „Weiß ich nicht“) verbrauchte seine Zeit mit
Zweitbelegen, die Klick-LSA hatte 135 Aufgaben. Bauauftrag `docs/lsa/Bauauftrag-LSA-V2.md`.

## Gebaut
- Migration `20261022131358_lsa_v2_ausblick` (nicht eingespielt):
  - `lsa_ausblick_knoten(session)`: die Ausblick-Knoten in Ausblick-Reihenfolge (Einstiege der nächsten drei
    Plan-Themen, Plan der Klasse + 1, ohne Plan Kernlehrplan, Klassengrenze grade + 1), die Definition.
  - `lsa_ist_ausblick(session, skill)`: die boolesche Form, benutzt von `lsa_urteil_buchen_core`.
  - `lsa_select_next_core`: Deckel 40 neben der 19-Minuten-Prüfung; Ausblick zwischen Thema vertiefen und
    Rückblick, nur für starke Kinder (≥ 6 finale direkte Urteile, ≥ 75 % traegt), Stopp nach zwei nicht
    sicheren Ausblick-Knoten hintereinander; Tiefe ignoriert Ausblick-Knoten.
  - `lsa_urteil_buchen_core`: „Weiß ich nicht“/leer als erste Probe final; im Ausblick ist eine falsche erste
    Probe final (Zweitbeleg nur nach MC-„voll“).
- Rollback, auf einer Kopie geprüft (beide Funktionen danach bytegleich mit dev, Hilfsfunktionen weg).
- `schema-erwartet.sql`: die vier Funktionsblöcke aus dem lokalen Neuaufbau (Rest zeilengleich mit dem Abzug).
- Report: `vorgriff.ts` (Vorgriff = Heimat in Kommt noch, nicht im Raum, nicht am Vorschau-Rand). `bericht.ts`
  zählt nur sichere Vorgriffe; der Lernweg setzt Vorgriffe in die Insel ihres Themas in Kommt noch, unsichere mit
  neuem Stand `vorgriff` („noch nicht behandelt“, leerer Kreis). Die Präsentation nimmt dieselben Bereiche.
- Testkinder: `kinder.sql` ausgelagert (erzeugen.sql 400 → 342 Zeilen), Max und Lina mit Ausblick-Profil,
  `neuaufbau-fixture.sql` (aus dem Test), `simulation.sh` und `auswertung.sql`.
- pgTAP `lsa_v2_ausblick` (32), `lsa_testkinder` (49, +5 Zusicherungen), angepasst: `lsa_v_vorschau`
  (Ausblick in a, d, f), `lsa_v_gleich` (Folge ohne die Zweitprobe nach „Weiß ich nicht“, aus den alten Folgen
  abgeleitet). Vitest `vorgriff.test.ts` (12), angepasst `lernwegKuerzen.test.ts`, `praesentation.test.ts`.

## Entscheidungen
- Die Definition der Ausblick-Knoten ist eine Liste (`lsa_ausblick_knoten`), `lsa_ist_ausblick` prüft dagegen.
  Die Auswahl braucht die Reihenfolge, die Buchung nur ja/nein; so gibt es die Definition einmal.
- Abweichung vom Wortlaut: Einstiege von Themen, die der Lead als behandelt führt, sind keine Ausblick-Knoten.
  Sonst verlor ein schwaches Kind im Rückblick den Zweitbeleg, nur weil das behandelte Thema laut Plan noch
  kommt (gefunden durch inv10, Fall 2 und 6).
- Der Stopp liest die letzten zwei Urteile in Ausblick-Reihenfolge, nicht nach Zeit: in einer Transaktion (Testkinder,
  pgTAP) tragen alle Urteile dasselbe `now()`, und der Ausblick beurteilt seine Knoten der Reihe nach.
- Ein falscher Ausblick-Knoten wird `traegt_nicht` (auch bei „teilweise“), wie die vorläufige erste Probe bisher.
- Profil „Klasse + 1 sicher bis zum ersten Thema danach“: umgesetzt als „das erste kommende Plan-Thema sicher, die
  Einstiege der zwei danach `uebung`“. Am FWG liegen die drei kommenden Themen für Max und Lina noch in ihrer
  Klasse.

## Was auffiel
- Die Stärke gilt bei jedem Aufruf: Hebt erst ein Urteil im Rückblick das Kind auf 75 %, kommt der Ausblick nach
  dem Rückblick (pgTAP `lsa_v2_ausblick`, Fall b). Das folgt aus Entscheidung 2, wirkt aber wie eine andere
  Reihenfolge.
- Synthetische Report-Fixtures (sehrViele, klasse10neu) enthalten Bereiche aus Themen, die noch kommen. Sie sind
  jetzt Vorgriffe; die Tests prüfen ihre Absicht weiter (Kürzen zählt Vorgriffe mit, Klassenangabe ohne Plan).
- Jonas erreicht im Neuaufbau schon vorher Klasse 5; der Effekt von B zeigt sich dort als halb so viele
  Zweitbelege, nicht als tiefere Klasse.
- Lokal kein Docker: pgTAP als SQL in einer Wegwerf-Vorlage (wie Retro 2026-10-03), `session_x0` ist lokal auch
  ohne die Migration rot (Rechte der lokalen Rolle), in CI grün.

## Offen
Siehe PR und `docs/lsa/lsa-v2-simulation.md`.
