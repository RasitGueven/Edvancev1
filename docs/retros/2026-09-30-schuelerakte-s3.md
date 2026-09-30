# Retro 2026-09-30 — Schülerakte S3 (Kachel Fortschritt)

## Was gebaut wurde
- **`fortschritt(p_student)`** (SECURITY DEFINER; Admin immer, Coach nur bei aktiver Akte, sonst 42501). Liefert je Fach:
  - das aktuelle Thema und die Station x von y im Lernpfad (`skill_clusters` über aktive `student_focus_areas`),
  - die vom Coach bestätigten Kompetenzen (`student_competency_mastery.mastered_by` gesetzt, neueste zuerst, mit Coach-Name und Datum).
- **Kachel Fortschritt** statt Platzhalter: Thema, Station mit schmalem Balken, höchstens 4 Kompetenzen, „und n weitere“, „Noch kein Lernpfad.“
- **Seed und Teardown** `tools/seed/zz_fortschritt_*`: ergänzen die ZZ_S2B-Akten und nutzen vorhandene Lerninhalte.

## Belege und Entscheidungen
- **`student_progress`** hält nur XP, Level und Streaks, keinen Lernpfad. Es wird nicht gelesen.
- **Lernpfad-Stand:** Ihn tragen `student_focus_areas`. Clusterbasiert aktiv setzt `lsa_confirm_focus` (Coach/Admin), Skill-Vorschläge kommen aus `lsa_uebernahme`.
- **Lernpfad eines Fachs:** die `skill_clusters` des Fachs (nicht veraltet, Klasse passt), sortiert nach `sort_order`.
- **Aktuelles Thema:** der aktive Schwerpunkt, der im Pfad am weitesten vorne steht.
- **edvance-app** hat keinen Lernpfad-Code, zeigt „gemeistert“ nirgends und liest `student_badges` nicht. Die Sorge „gemeistert aus Badges“ trifft die App nicht.
- **In Prod** hat nur Mathematik Cluster (5). Deutsch und Englisch haben keine, deshalb zeigt das zweite Fach „Noch kein Lernpfad.“

## Versionskollision
- **`20260930140000`** war in Prod schon durch `tasks_vorbefuellt` (#176) belegt. Die S3-Migration läuft deshalb als `20260930113231_akte_fortschritt`. Die alte Datei `20260930140000_akte_fortschritt.sql` wurde nie eingespielt; `guard-paths` sperrt das Löschen, sie muss vor dem Merge raus.
- **#176** enthält außerdem `20260930120000_prefill_mathe8_pilot`, dieselbe Version wie S2b. In Prod ist S2b eingetragen, die Prefill-Daten fehlen. Die Reparatur entscheidet Rasit.

## Prod (einmalige Freigabe)
| Schritt | Zeit (UTC) | Ergebnis |
|---|---|---|
| 0 Reste | 11:3x | keine ZZ_S2B-Reste, `fortschritt` frei |
| 1 Migration `20260930113231_akte_fortschritt` | 11:33:08 | rc=0, eingetragen |
| 2 `fortschritt_test.sql` | direkt danach | 7/7 OK |
| 3 Akten-Seed | 11:33:32 | rc=0; fünf Zustände wie erwartet |
| 4 Fortschritt-Seed | 11:33:44 | rc=0; Werte wie erwartet |

Teardowns NICHT ausgeführt.
