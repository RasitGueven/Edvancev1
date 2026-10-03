# 2026-10-03 – Erstgespräch: Schule, aktuelles Thema, „schon behandelt“ (W2-5)

## Gebaut
- Schulauswahl über `public.schulen` (gefiltert auf Schulform, Suche Name + Stadtteil); setzt `leads.schule_id`, Name weiter in `school_name`; Freitext bleibt möglich.
- `TopicSelect` (Cluster) ersetzt durch `ThemenAuswahl`: Stichwortsuche (`src/lib/themen/suche.ts`), Stufen-Chips 5/6 · 7/8 · 9/10 mit Schulplan-Gruppierung, „schon behandelt“ mit Vorbelegung aus `schul_themenplan` (`src/lib/themen/vorbelegung.ts`).
- Schreibwege in `src/lib/supabase/themen.ts` (lead_themen sofort, nicht über den Lead-Payload).
- Mitbring-Hinweis (Mathe-Heft, letzte Klassenarbeit) im Termin-Dialog.

## Entscheidungen
- Vorbelegung wird beim Setzen/Wechseln des aktuellen Themas geschrieben, nicht beim bloßen Öffnen. Bei Themenwechsel werden veraltete `quelle='schulplan'`-Zeilen entfernt, im Gespräch genannte bleiben.
- Kommt das aktuelle Thema in der Klasse mehrfach im Plan vor, zählt das erste Vorhaben.
- „Behandelt“-Chips neutral statt grün (grün = Mastered).
- Freigabe der LSA verlangt ein aktuelles Thema – oder einen alten Cluster-Wert, oder ein Fach ohne Katalog.
- `current_topic_cluster_id` wird nicht mehr geschrieben, nur angezeigt.

## Offen
- Keine Mail-Vorlage für die Terminbestätigung im Repo; Hinweis steht nur im Termin-Dialog.
- `SectionErstgespraech`, `LeadIntakeForm`, `intakeConstants` haben noch hardcodierte Strings (nicht Teil dieses Auftrags).
- `setAktuellesThema` ist zweistufig (delete + upsert), nicht atomar; ein RPC wäre sauberer (Foundation).
