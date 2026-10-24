# Retro 24.10.2026 · Eltern-Bericht v3

Auftrag: Nachbesserungen aus der Gründerrunde vom 24.10.2026, Testlauf mit der LSA von Rasit Batu. Branch
`feat/lsa-report-v3`, gezweigt von `feat/lsa-report-v2`. Der v2-PR war nie offen, weil der Push gesperrt war.

## Gebaut
- **Paket A (eigener Commit):** Migration `20261024143626_graph_wurzel_faktorisieren` (nicht eingespielt).
  Sie legt zwei Kanten an:
  - `geo_pythagoras_anwendung ← zahl_wurzel_teilweise`
  - `fkt_quadr_nullstellen ← term_binom_faktorisieren`

  Die Kanten sind nicht redundant und bilden keinen Kreis. pgTAP lokal mit und ohne sie identisch.
- **Name:** Im Text steht der Vorname (erstes Wort). Der volle Name steht nur im Titel von Seite 1 und in der
  Fußzeile (`SeitenProps.vollerName`).
- **Seite 1:** Note und Tendenz in einer Zeile.
- **Seite 2:**
  - Felder nach Klassenband sortiert.
  - Feste Spur 195 pt, keine Überlagerung bis 12 Kästchen.
  - Fußnote gekürzt.
- **Seite 3:**
  - `lueckenweg.ts` neu: Jeder Bereich steht in genau einem Themenblock (erstes kommendes Thema), dazu
    „betrifft auch …“.
  - Neu „Weitere Stärken“ als Liste.
  - Zwei Layouts A/B (`EINORDNUNG_LAYOUT`, Prop `einordnung`).
  - Halbjahr nur, wenn geliefert.
- **Seite 4:**
  - Nur noch Titel und Grund.
  - Regel bei gleichem kommenden Thema: früheres Klassenband zuerst (`nachPlanrang`), der Grund nennt das Band.
  - Nach geschriebener Klassenarbeit heißt der Thema-Schwerpunkt „Vorhandene Lücke“, mit Bezug aus dem Graphen
    (`spaeterGebraucht`).
- **Seite 5:**
  - Fazit aus Seite 1–4 (`fazitSaetze`), der Vorschlag knüpft daran an.
  - Ziele nur nach Bestätigung (`zieleBestaetigt`, Migration `20261024145154_bericht_v3_ziele`); sonst kein
    Abschnitt.
  - Systemvorschlag `zieleSaetze`: Paket = Umfang.
  - Kontakttext ohne „ohne Termin und ohne Frist“.
  - Platz für einen Tablet-Link.
- Plantitel stehen in Sätzen in Anführungszeichen.

## Entscheidungen
- „Weil Geometrie darauf aufbaut“ trägt der Graph nicht. Die Reihenfolge-Regel stützt sich deshalb auf das
  Klassenband.
- Die PDFs sind mit den zwei neuen Kanten gerendert (Harness-Override), damit sie den Stand nach dem
  Einspielen zeigen.

## Offen
`docs/report/v3/offene-punkte.md`
