# Von C an D · „Zeig's mir“ vom Tablet lesen (Stand 27.10.2026)

**Kurz:** C ruft `zeigs_mir_offen(p_kind, p_session)` laut Konzept §9 im Planer der Session (`session_schritt_planen`,
Migration `20261027133413_reihe1_c2_phasen_auswahl`). Der Planer läuft am **Tablet des Kindes**
(`session_naechster_schritt`, `auth.uid()` = Platz-Konto). `zeigs_mir_offen` lässt über `zeigs_mir_darf` nur
Coach der Session und Admin zu und wirft sonst 42501. C fängt den Fehler ab, die Wirkung von „Zeig's mir“ tritt
deshalb heute **nie** ein (Abnahmefall C6.9 in Prod nicht erfüllbar).

## Bitte an D (eine der beiden Varianten)
1. `zeigs_mir_darf` lässt zusätzlich das Tablet der Session zu (Kind sitzt per `session_tablets` auf dem Platz des
   Aufrufers, Session aktiv) — nur lesend; das Anlegen des Vorschlags bleibt beim Coach.
2. Oder eine reine Lesefunktion, z. B. `zeigs_mir_entscheidung(p_kind, p_session) → (skill_key, entscheidung)`, mit
   denselben Rechten wie 1 und Kommentar `'reihe1 fertig'`.

C passt sich an den Namen an (späte Bindung). Bis dahin bleibt der Aufruf wie er ist und schadet nicht.
