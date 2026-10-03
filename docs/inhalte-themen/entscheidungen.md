# Entscheidungen – Kachel „Inhalte“ nach Themen (W4)

Stand: 2026-10-03.

## 1. Eigene Tabelle `skill_thema`, Skill als Primärschlüssel

`thema_einstieg` (Einstiegsknoten der LSA, n:m) und `skill_voraussetzung`
(Tragkraft) haben eine andere Bedeutung und werden nicht umgewidmet. Der
Primärschlüssel auf `skill_key` erzwingt „genau ein Heimat-Thema“ in der DB.

- `skill_key → skills on delete cascade`: ein gelöschter Skill braucht keine
  Zuordnung mehr.
- `thema_key → themen` ohne cascade: ein Thema mit zugeordneten Skills lässt sich
  nicht löschen. Sonst würden dessen Aufgaben still unter „Ohne Thema“ landen.
- RLS: Lesen nur `admin`/`coach` (wie `thema_einstieg`). Es gibt keine
  Schreib-Policy, deshalb schreiben nur `service_role` und Migrationen.
  `anon` hat keine Rechte, `authenticated` darf nur lesen.

## 2. Neue RPC `freigabe_thema(p_thema_key, p_klasse)` statt `freigabe_cluster`

„Alle geprüften freigeben“ hing an `freigabe_cluster`. Mit Themenzeilen würde
das einen ganzen Cluster quer über alle Themen freigeben, also mehr, als die
Zeile zeigt. `freigabe_thema` gibt genau das frei, was die Themenzeile in dieser
Klasse zeigt:

- Heimat-Thema des Skills,
- `class_level <= p_klasse` oder leer,
- ohne VERA8,
- jede Aufgabe durch das `task_status_set`-Gate.

Rechte und Rückgabe sind wie bei `freigabe_cluster`. `freigabe_cluster` bleibt
in der DB stehen, der TS-Wrapper `freigabeCluster` ist entfernt, weil ihn nichts
mehr aufruft. `vera8.test.ts` prüft jetzt beide SQL-Bedingungen gegen
`vera8.json`. Die Funktion steht in der Schema-Migration, nicht in einer dritten
Datei: Sie hängt an der neuen Tabelle.

## 3. Fach bleibt am Cluster

Das Fach kommt weiter über `skill_clusters.subject_id` bzw. `FACH_OHNE_CLUSTER`,
nicht über `themen.fach`. Gründe:

- Aufgaben ohne Heimat-Thema (heute `potenzen`, künftig neue Knoten vor ihrem
  Nachtrag) hätten über `themen.fach` kein Fach und fielen aus jeder Fachkachel.
  Über den Cluster bleiben sie sichtbar, unter „Ohne Thema“.
- `themen.fach` ist ein Schlüssel (`mathematik`), Board und Expertenliste
  arbeiten mit dem Fachnamen aus `subjects` („Mathematik“). Ein zweites Mapping
  wäre eine neue Fehlerquelle.
- `cluster_id` bleibt laut Auftrag ohnehin an jeder Aufgabe.

## 4. Aktive Klassen aus den Daten

Aktiv ist jedes `class_level`, das im Board-Bestand (ohne VERA8) vorkommt. Die
Kacheln zeigen immer 8, 9 und 10 und dazu jede weitere aktive Klasse. Die Regel
„`class_level <= klasse` oder leer“ bleibt. Damit ist Klasse 9 heute schon aktiv:
In Prod stehen 24 Kreis-Aufgaben mit `class_level 9`.

## 5. Stufenfolge

Die Stufe der Klasse steht zuerst, dann die Stufen darunter absteigend, eine
höhere Stufe zuletzt (die gibt es nur theoretisch). Klasse 9 zeigt also
„Klasse 9/10“, „7/8“, „5/6“, Klasse 8 zeigt „7/8“, „5/6“. Innerhalb einer Stufe
wird nach `themen.sort` sortiert, bei Gleichstand nach Label. „Ohne Thema“
steht immer zuletzt, in einem eigenen Abschnitt „Nicht zugeordnet“. Die
Bezeichnungen sind dieselben wie im Report („Klasse 5/6“ …), stehen aber als
eigene Keys in `authoring.json`, weil die Namespaces getrennt bleiben.

## 6. Ein Abruf für die Zuordnung

`listSkillThemen()` liest `skill_thema` mit eingebettetem `themen(label, stufe,
sort)` in einem Request. Die Gruppierung macht `board.ts` im Client, wie bisher
beim Cluster. Fällt der Abruf aus, etwa vor dem Einspielen, bleibt das Board
bedienbar und zeigt alles unter „Ohne Thema“.

## 7. Zuordnung: Grenzfälle

Einzelbegründungen stehen in `zuordnung.md`. Die Linie dahinter:

- Einheiten (Flächen, Volumen) gehören zum Thema, in dem sie eingeführt werden
  (Fläche bzw. Quader), nicht zum allgemeinen Größen-Kapitel.
- Bei `geo_massstab` entscheidet der KLP-Bezug (E-Fkt (4) →
  `ganze_zahlen_groessen`) gegen das bloße Schlagwort in `flaeche_umfang`.
- Für `potenzen` gibt es kein passendes Thema der unteren Stufen. Der Skill
  bleibt ohne Zuordnung, statt still in das Thema `potenzen` der Zweiten Stufe
  zu rutschen. Es wird kein neues Thema angelegt: Ob Potenzen/Quadratzahlen ein
  eigenes Erprobungsthema sind oder zu `rechnen_natuerliche_zahlen` gehören, ist
  nicht eindeutig. Dazu sind Label und Aufgaben des Knotens seit W2-7 ungeklärt.

## 8. Expertenliste

Die Expertenliste hat einen neuen Filter „Thema“ neben „Skill“. Die Optionen
sind die Heimat-Themen der geladenen Aufgaben, nach Stufe und `sort`, mit
„Ohne Thema“ als letzter Option. Es gibt keinen zusätzlichen Abruf je Aufgabe.
