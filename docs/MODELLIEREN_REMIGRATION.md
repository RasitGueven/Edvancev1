# Re-Migration: Auflösung „Sachrechnen & Modellieren" (Achsen-Verwechslung)

> Erzeugt mit Migration `041_resolve_modellieren_cluster.sql`. **Daten-sensibel,
> non-destruktiv.** Kein automatisches Re-Homing von Inhalten.

## Problem

`skill_clusters` ist **Achse A (Inhaltsfeld)**. Der Cluster
**„Sachrechnen & Modellieren"** vermischte ein Inhaltsfeld mit der
**Prozesskompetenz „Modellieren" (Achse B)**. Achse B existiert seit
Migration 038 als eigene Referenztabelle `process_competencies`
(`Ope|Mod|Pro|Arg|Kom|Wkz`). Diese Re-Migration trennt die Achsen — **ohne zu
raten und ohne zu löschen**.

## Was Migration 041 tut

1. **Zählen (a):** Vor jeder Änderung werden die betroffenen Zeilen gezählt und
   per `RAISE NOTICE` ausgegeben (siehe Ergebnis-Tabelle unten).
2. **Deprecaten (b):** `skill_clusters.is_deprecated = true` für den Cluster
   (neue Spalte `is_deprecated boolean default false`). **Kein Delete.**
3. **Kompetenz-Backfill (c):** Für alle `tasks` (direkt via `cluster_id` **oder**
   via `microskill_id → microskills.cluster_id`) und `screening_items`
   (via `cluster_id`), die an diesem Cluster hängen **und** `competency_id IS NULL`
   haben: `competency_id = (Prozesskompetenz code='Mod')`.
4. **Quarantäne (d):** `tasks.is_active = false` für genau diese betroffenen
   Tasks — mis-kategorisierter Inhalt wird **nicht ausgeliefert**, bis das
   korrekte Inhaltsfeld zugewiesen ist.

## Anwendung

Dieses Repo wendet Migrationen **nicht automatisch** an (manuelle Ausführung im
Supabase SQL Editor, vgl. Header jeder Migration). Die unten geforderten
**Zahlen entstehen zur Laufzeit** beim Ausführen von 041 (`RAISE NOTICE`) und
sind hier als Vorlage einzutragen, sobald 041 im SQL Editor gelaufen ist.

### Zähl-Queries (entsprechen Schritt 5a; `:cluster_ids` = ids des Clusters)

```sql
-- Cluster-id(s) ermitteln:
select id from skill_clusters where name = 'Sachrechnen & Modellieren';

-- tasks via cluster_id:
select count(*) from tasks where cluster_id = any(:cluster_ids);
-- tasks via microskill_id -> microskills.cluster_id:
select count(*) from tasks t join microskills m on m.id = t.microskill_id
 where m.cluster_id = any(:cluster_ids);
-- microskills:
select count(*) from microskills where cluster_id = any(:cluster_ids);
-- screening_items (nur direkt via cluster_id; kein microskill-Link):
select count(*) from screening_items where cluster_id = any(:cluster_ids);
-- student_focus_areas:
select count(*) from student_focus_areas where cluster_id = any(:cluster_ids);
```

### Ergebnis (aus `RAISE NOTICE` eintragen)

| Bezug | Anzahl |
|---|---|
| tasks via `cluster_id` | _(beim Lauf eintragen)_ |
| tasks via `microskill_id → cluster` | _(beim Lauf eintragen)_ |
| microskills | _(beim Lauf eintragen)_ |
| screening_items | _(beim Lauf eintragen)_ |
| student_focus_areas | _(beim Lauf eintragen)_ |

### Betroffene IDs auflisten (für die Nachverfolgung)

```sql
-- Quarantänierte / betroffene Task-IDs:
select t.id, t.title, t.is_active, t.competency_id
  from tasks t
 where t.cluster_id = any(:cluster_ids)
    or t.microskill_id in (select id from microskills where cluster_id = any(:cluster_ids));

-- Betroffene Screening-Item-IDs:
select id, skill_label, competency_id
  from screening_items
 where cluster_id = any(:cluster_ids);
```

| Objekt | ID | Aktion |
|---|---|---|
| _task_ | _(eintragen)_ | `is_deprecated`-Cluster · `competency_id=Mod` (falls war NULL) · `is_active=false` |
| _screening_item_ | _(eintragen)_ | `competency_id=Mod` (falls war NULL) |

## OFFEN — Aufgabe für Lena (Content)

> **Korrektes Inhaltsfeld (Achse A) zuweisen, dann `is_active` reaktivieren.**

Für jeden quarantänierten Task:
1. Das **inhaltlich passende** Cluster (Achse A, **nicht** das deprecatete
   „Sachrechnen & Modellieren") setzen — `tasks.cluster_id` und/oder
   `tasks.microskill_id`.
2. Achse B (`competency_id`) prüfen: 041 hat `Mod` nur dort gesetzt, wo vorher
   `NULL` war. Falls die Aufgabe eine **andere** Prozesskompetenz prüft,
   korrigieren.
3. `tasks.is_active = true` setzen, sobald die Zuordnung stimmt.

**Kein automatisches Re-Homing** — die inhaltliche Zuordnung ist bewusst eine
manuelle Entscheidung und wird nicht geraten. Der Cluster bleibt als
`is_deprecated` erhalten (Historie), wird aber nicht mehr für neue Inhalte
verwendet.
