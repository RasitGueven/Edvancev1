# VERA8 entfernen · Verweise (Haltepunkt aus Entscheidung 2b)

Stand 27.10.2026, per `~/bin/dbread`.

**Erkennung:** `tasks.source = 'VERA8_IQB'` → **299 Aufgaben** (`select source, count(*) from tasks group by 1`).
Die zehn weiteren Treffer auf `ilike '%vera%'` sind „Veränderung" aus `edvance_fundament*`, kein VERA8.

**Verweise auf tasks (pg_constraint, `confrelid = tasks`) und Zeilen auf VERA8:**

| Tabelle | FK beim Löschen | Zeilen auf VERA8 |
|---|---|---|
| task_solutions | cascade | 243 |
| **lsa_responses** | cascade | **66** |
| alle übrigen 17 (task_figures, task_pruefungen, task_reviews, task_admin_protokoll, task_pruef_ausschluss, task_pruefung_ausgang, task_coach_metadata, behavior_snapshots, student_task_progress, xp_events, lsa_ausgegeben, session_ausgegeben, session_antworten, session_schritte, erklaer_check, erklaer_fortschritt, quest_aufgaben) | – | 0 |

Keine Session-Antwort und kein Skill-Urteil (`lsa_skill_urteil` hängt an der LSA-Sitzung, nicht an der
Aufgabe; die neun Sitzungen haben 0 Urteile) verweist auf VERA8. Aber **66 LSA-Antworten** tun es.
Nach Entscheidung 2b: **STOPP für das Löschen von VERA8.** Nichts wird gelöscht, keine Sicherung,
keine Migration, bis Rasit entscheidet, was mit diesen Antworten geschieht.

Die neun LSA-Sitzungen (alle aus dem Juli, zwei Kinder (IDs nicht im Repo), keine Testlauf-Markierung):

```
              session_id              |     am     | skill_urteile | antworten_gesamt 
--------------------------------------+--------------------------------------+------------+---------------+------------------
 e78bd3a0-3edf-4318-9fae-711459296f18 | 2026-07-12 |             0 |                7
 bdc38e6b-3966-49a2-b5d9-5e1e1a6392d2 | 2026-07-15 |             0 |                7
 74a1d807-22dd-4ba3-92c5-d193b105ed2f | 2026-07-18 |             0 |                8
 a8ff43dc-6d2d-4306-901e-f03dc81d59f3 | 2026-07-21 |             0 |                7
 142bcebb-76d9-427b-8c71-e4df2089d8fe | 2026-07-21 |             0 |                7
 f0a0ac0f-c5ba-4505-80e0-5c2c94e1556d | 2026-07-22 |             0 |                8
 da10ca1b-15dd-4484-95b5-a815dffd9a8f | 2026-07-22 |             0 |                7
 73217031-0fa2-44cd-b2d4-d0c33a21dd52 | 2026-07-22 |             0 |                7
 2b796028-b35c-4fe1-8bb3-14606e992050 | 2026-07-22 |             0 |                8
(9 rows)

```
