---
id: sachkontext-fundament
type: content
repo: edvancev1
branch: spec/sachkontext-fundament
depends_on: []
gates:
  - node tools/verify-tasks.mjs --source edvance_fundament_kontext --min-pass 0.98
  - bash -c 'psql "$DBURL" -tAc "select count(*) from tasks where source=''edvance_fundament_kontext'' and (skill_key is null or status<>''draft'')" | grep -qx 0'
  - bash -c 'psql "$DBURL" -tAc "select count(*) from tasks t left join task_solutions s on s.task_id=t.id where t.source=''edvance_fundament_kontext'' and s.task_id is null" | grep -qx 0'
---

## Ziel

Zu ausgewählten Fundament-Skills je drei Aufgaben mit Sachkontext erzeugen. Der
bestehende Bestand besteht ausschliesslich aus nackten Rechnungen; damit lässt sich
nicht unterscheiden, ob ein Kind nicht rechnen kann oder eine Situation nicht in
eine Rechnung übersetzen kann.

## Kontext

- Die 245 vorhandenen `edvance_fundament`-Aufgaben stehen auf `ready` und werden
  **nicht angefasst**. Neue Aufgaben entstehen zusätzlich, mit
  `source = 'edvance_fundament_kontext'` und `status = 'draft'`.
  Diese Trennung macht den ganzen Jahrgang mit einem `delete` rückgängig.
- Sachkontext misst etwas anderes als eine nackte Rechnung: er bringt Lesekompetenz
  und Modellierung ins Spiel. Das ist erwünscht, aber es ist eine **zusätzliche**
  Messung, kein Ersatz. Deshalb Ergänzung, nicht Umschreiben.
- Die LSA dauert 20 Minuten. Ein Sachkontext, der drei Sätze zum Lesen gibt, kostet
  Zeit, die für Diagnostik fehlt. Kontext so knapp wie möglich — ein bis zwei Sätze.
- `input_type`, `acceptance` und `unit` folgen dem Muster der vorhandenen Aufgaben
  desselben Skills. Erst eine bestehende Aufgabe je Skill ansehen, dann bauen.
- `sondierrang` bleibt `null` — die Reihenfolge ist eine eigene Aufgabe.

## Auswahl der Skills

Nur Skills, bei denen Modellierung fachlich sinnvoll ist:

    groessen_laengen, groessen_massen, groessen_zeit, groessen_flaechen,
    groessen_volumen, groessen_gemischt, proportionalitaet,
    prozent_prozentwert, prozent_grundwert, prozent_prozentsatz,
    prozent_veraenderung, dezimal_add_sub, dezimal_mult, dezimal_div,
    runden_ueberschlag, geo_massstab

**Nicht** für `bruch_*`, `vorzeichen_*`, `term_*`, `gleichung_*`. Dort ist der
Kontext aufgesetzt — negative Zahlen als Kontostand oder Temperatur sind das übliche
Beispiel und messen dann die Kontextkenntnis, nicht das Rechnen.

Bei 16 Skills à 3 Aufgaben also 48 neue Aufgaben.

## Akzeptanz

- Je Skill genau 3 neue Aufgaben, `source = 'edvance_fundament_kontext'`,
  `status = 'draft'`, `skill_key` gesetzt, `class_level` wie beim Vorbild
- Zu jeder Aufgabe eine Zeile in `task_solutions` mit korrekter Lösung
- Kontext maximal zwei Sätze; die Frage selbst ist eine Zeile
- Zahlen sind realistisch: Mengen, Preise, Massen und Zeiten, die in Deutschland
  2026 plausibel sind. Keine 47,3 Brötchen, kein Auto mit 3 kg.
- Namen und Situationen unaufdringlich und ohne Klischee. Kein Konsumdruck, keine
  Markennamen, keine Aufgaben, in denen jemand etwas nicht bezahlen kann.
- Der Prüfer (`tools/verify-tasks.mjs`) löst jede Aufgabe unabhängig und kommt auf
  die hinterlegte Lösung — bei mindestens 98 %.
- Ein Bericht `out/sachkontext-bericht.md`: je Skill die drei Aufgaben mit Lösung,
  zum Durchsehen durch Lena.

## Nicht-Ziele

- Keine Änderung an bestehenden Aufgaben, an ihrem Text, Status oder ihren Lösungen
- Keine neuen Skills, keine Änderung an `skills` oder `skill_kante`
- Keine Freigabe — alles bleibt `draft`
- Kein `sondierrang`
- Keine Aufgaben zu Skills ausserhalb der Liste oben
