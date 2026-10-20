# Retro R7-8 · Seite 2: Klassenstufen, abgeleitete Bereiche, vollere Karte (20.10.2026)

## Gebaut
- `themaAbdeckung` liefert zusätzlich `abgeleiteteSchluessel` (sortiert) und `abgeleiteteBereiche`
  (Feld, Klasse aus dem Katalog oder null).
- `seite2Rechnung`: `profilZeilen` (direkt plus abgeleitet je Feld, Klassenspanne), ein Maßstab für
  alle Zeilen (`massstab`, `massstabFuer`, Lücke 4/2/1 pt, Breite höchstens 28 pt), Spur 206 pt mit
  abgeleiteten Bereichen.
- `Profil`: Umriss-Kästchen (Papier, Rand 0,7 pt, um die halbe Randstärke eingerückt), Klassenzeile,
  rechte Zeile mit „abgeleitet“, Vorlesetexte, dritter Legendeneintrag. `Seite2`: Fußnote mit Zusatz.
- Fall `abgestuftLang` und eine Druck-Prüfung „Spur ≥ 6 pt vor dem rechten Text“.

## Entscheidungen
- Kein Katalog-Nachschlagen im Bogen (INV-4.3): Die Klasse rechnet `themaAbdeckung` (Rasit).
- Spur 206 pt nur mit abgeleiteten Bereichen, dann für alle Zeilen (Rasit).

## Gelernt
- Der Druck-Test hätte die Kollision nicht gefunden: Er prüft Überlauf und Rahmen, keine
  Überschneidung in der Karte. Erst die Messung im Browser (Spurende gegen Textanfang) zeigte sie.
  Deshalb gibt es jetzt die Prüfung mit Gegenprobe.
- Ein Bauauftrag, der eine Rechnung in die Komponente legt, kann an einer Invariante scheitern, die
  über Bezeichner prüft. Vorher per grep gegen INV-4.11 prüfen.

## Offen
Siehe `docs/report/r7/offene-punkte-r7-8.md`.
