# Befunde – Kachel „Inhalte“ nach Themen (W4)

Stand: 2026-10-03.

## Skills ohne Heimat-Thema

| skill_key | label | klasse_herkunft | Aufgaben | Grund |
|---|---|---|---|---|
| potenzen | Potenzen und Quadratzahlen | 7 | 24 (3 ready) | Der Katalog hat kein Potenz-Thema unterhalb der Zweiten Stufe. `potenzen` (9/10) behandelt Potenzgesetze und wissenschaftliche Schreibweise, dort wird der Stoff nicht eingeführt. Die Aufgaben sind außerdem gemischt: 2⁵ (E), (−3)² (S1), √36 (S2), siehe `docs/report/stufen-pruefung.md`. |

Folge im Board: Die 24 Aufgaben stehen unter „Ohne Thema“, und zwar in jeder
Klasse.

Lösungswege, die du entscheiden musst:

- **A:** Den Knoten erst klären (Label, Wurzel-Aufgaben zurückweisen, offener
  Punkt aus W2-7). Danach entweder `rechnen_natuerliche_zahlen` (Quadratzahlen
  und Potenzen als Rechenart, Kl. 5) oder `rationale_zahlen` (negative Basen,
  Kl. 7) per Nachtrag.
- **B:** Ein Erprobungsthema „Potenzen und Quadratzahlen“ anlegen. Das geht nur,
  wenn die Schulpläne es als eigenes Vorhaben führen. Laut
  `docs/themen/befunde-daten.md` hängen Quadratzahlen dort an „Zahlen“, also
  eher nein.

## Fehlende Themen

Keine eindeutig fehlenden. 58 von 59 Skills haben ein passendes Thema, das sind
98 %, weit über der Blocker-Grenze von 75 %.

## Stellen außerhalb der Kachel, die noch nach Inhaltsfeldern (Cluster) gliedern

Nur notiert, nicht angefasst:

- **Schülersicht:** `src/pages/student/ClusterGrid.tsx`, `ClusterView.tsx`,
  `StudentDashboard.tsx`, `masteryMatrix.ts`. Kacheln und Mastery je Cluster.
- **LSA-Report, Thema des Leads:** `src/lib/supabase/lsaReport.ts` (ab Z. 210)
  löst bei Altleads noch `leads.current_topic_cluster_id` → `skill_clusters.name`
  auf. Das ist der Fallback vor der Themenauswahl.
- **Screening-Berichte:** `src/pages/parent/ScreeningReportPage.tsx`,
  `src/pages/coach/ScreeningResultsPage.tsx`, `src/lib/screening/**`. Ergebnisse
  je Cluster.
- **Item-Pflege:** Editor, QS-Bildschirm und Pflege-Strecke zeigen den Cluster
  weiter als Feld. Das ist so gewollt (`cluster_id` bleibt).
- **Expertenliste:** Der Filter „Fach“ läuft über den Cluster, siehe
  Entscheidung 3.
- **Schülerakte:** nicht geprüft (laut Auftrag ausgenommen).

## Sonstiges

- Klasse 9 ist mit den Daten schon aktiv: 24 Kreis-Aufgaben mit `class_level 9`.
  Ihr Board zeigt „Klasse 9/10“ mit „Kreis: Umfang und Fläche“ an erster Stelle.
- `geo_kreis_zusammen` hat noch keine Aufgaben, ist aber schon `kreis`
  zugeordnet.
