# Retro 07.10.2026 · Paket L6 (Erklärsequenzen prüfen und freigeben)

## Gebaut
- Migrationen `20261010121014`–`121017`: Prüfprotokoll `erklaer_pruefungen` (nur anhängen), die fünf
  Pflegefunktionen aus E1 protokollieren vorher/nachher, `erklaer_pruefen` (passt, unsicher, passt_nicht,
  zurückgenommen), `erklaer_freigeben`, `erklaer_freigabe_zuruecknehmen`, `erklaer_rueckfrage_beantworten`,
  `erklaer_pruef_liste`, `erklaer_pruef_detail`, Baustein `erklaer_freigabe_fehlt`.
- Oberfläche unter `/coach/pruefen/erklaerungen` (Lena) und `/admin/pruefen/erklaerungen` (Admin, Filter
  „Bereit zur Freigabe“ und „Rückfragen“); Einstiege in „Aufgaben prüfen“ und in der Item-Pflege.
- pgTAP `session_l6` (61), Vitest für Leiste, Formel-Rückfall, Admin-Filter, Admin-Bereich und Anzeige-Logik (22).

## Entscheidungen
- Lena prüft die Kernidee als Ganzes; „Passt“ setzt die Entwurfsschritte mit auf geprüft.
- „Was fehlt“ ist eine Funktion für Liste, Detail und Freigabe; der Fehler trägt die Liste im DETAIL.
- Eigener i18n-Namespace `erklaerPruefen`; die Aufgaben-Seiten bekommen nur einen Einstieg.

## Gelernt
- Consensus-Check fand eine echte Race (Schritt-Update ohne Status-Neuprüfung) und eine uneinheitliche
  Sperrreihenfolge; behoben (erst Kernidee, dann Schritt).
- MathJax-SVGs tragen ihre Größe in `ex`; eine feste Höhe bläht einfache Formeln auf.
- Parallele Pakete (A2c, E2b) vor dem PR per `git log --all` auf Überschneidungen prüfen.

## Offen
Siehe `docs/session/offene-punkte-l6.md`.

## Nachtrag (07.10.)
- Entscheidung Rasit: freigegebene Inhalte ändert nur ein Admin (Trigger `20261010121018`); Entscheidungen 37 und 38
  im Bauauftrag. Hook-Sperren künftig melden statt umgehen.
- origin/dev (A2c, C2) eingemischt, alle Tests erneut grün; eingespielt am 07.10. (`20261010121014`–`121018`),
  Schema-Abzug aus Prod = Neuaufbau aus allen Migrationen.
