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

## Nachtrag (Review)
- i18n: `SectionErstgespraech`, `LeadIntakeForm` und die Label-Listen in `intakeConstants` laufen jetzt über `admin:intake.*`. Gespeicherte Werte (u. a. `PARENT_WEAK_TOPICS`) bleiben unverändert, nur die Anzeige wird über einen semantischen Key gemappt. `SUBJECTS`/`SCHOOL_TYPES` sind DB-Werte und werden auch in Verträgen/Filter genutzt – unverändert.
- „Kein aktuelles Thema bekannt“: Am Lead gibt es kein passendes Feld (`next_exam_topic` lesen `lsa_lead_kontext` und der Report als Thementext, `goal` hat einen festen CHECK, `known_weak_topics`/`notes` passen nicht).
  - **Verworfen:** `leads.thema_unbekannt`. Ein Lead-Feld gilt nicht je Fach, und die LSA-Auswahl braucht es nicht, weil sie ohne `lead_themen`-Eintrag ohnehin in der Breite startet.
  - **Umgesetzt ohne Schema:** Ohne aktuelles Thema ist die Freigabe nicht mehr gesperrt, sondern verlangt im Fußbereich eine Bestätigung (inline, kein Modal). Primär ist „Thema wählen“ (springt ins Suchfeld), nachrangig „Ohne Thema freigeben“. Nichts davon wird gespeichert. Ohne Bestätigung freigeben dürfen weiterhin Bestandsleads mit altem Cluster und Fächer ohne Katalog. Die Logik liegt in `freigabeZustand` (`formState.ts`).

## Offen
- Thema setzen als eine DB-Funktion statt delete + upsert (Foundation-Fenster).
- Bestätigungsmail ans Elternhaus mit Mathe-Heft-Hinweis über hello@ (eigener Auftrag).
