# Offene Punkte K1b (Eltern ohne Konto)

Stand 14.10.2026 · Branch `feat/rasit-konto-k1b` · keine Migration

**Eltern-Portal pausiert; vor Reaktivierung prüfen, was Eltern sehen dürfen.**

## Entscheidung Rasit (14.10.2026)

Eltern bekommen kein Konto. Alle Mails an Eltern laufen über `vertraege.eltern_email`.

## Umgesetzt

1. **`vertrag_abschluss`:** Die Suche nach einem bestehenden Eltern-Konto, sein Anlegen und das Aufräumen bei einem
   Fehler fallen weg. `p_parent_uid` und `p_parent_email` gehen immer als `null` an `vertrag_abschliessen`.
   - Die Konto-Anlage und die RPC-Parameter stehen jetzt in `vertrag_abschluss/konten.ts`, damit sie sich testen
     lassen.
   - Der Ablauf in `index.ts` ist sonst unverändert, einschließlich V5, des PDFs und der Idempotenz.
   - Keine Migration: Die Funktion hat den Zweig `if p_parent_uid is not null`. Nur dort wird `p_parent_email`
     benutzt (`supabase/schema-erwartet.sql`, `vertrag_abschliessen`).
2. **`tools/eltern-konten-entfernen.mjs`:**
   - `--dry-run` gibt nur Anzahlen aus.
   - `--ausfuehren` löscht die `parent_student`-Zeilen und die Auth-Konten mit Rolle `parent`; das Profil fällt
     per Cascade.
   - Das Werkzeug bricht ab, wenn ein verknüpftes Kind nicht `ist_test` ist (auch: Profil ohne `students`-Zeile)
     oder wenn ein Fremdschlüssel ohne Cascade auf ein Eltern-Konto zeigt.
   - Vor dem Schreiben liest es den Bestand noch einmal.

## Nicht geändert (Auftrag)

- die `*_parent_read`-Policies, `is_parent_of_student`, die Seiten unter `/parent`.

## Bericht: Hängt ein Versand an `parent_student` oder einem Eltern-Konto?

**Nein.** `git grep` über `supabase/functions` und `src/lib`:

| Versand | Empfänger | Beleg |
|---|---|---|
| Bestätigung, Unterlagen, Zugangscode | `body.empfaenger ?? vertraege.eltern_email` | `mail_senden/index.ts:141` |
| Termin (Erstgespräch) | `leads.contact_email` | `mail_senden/termin.ts:56` |
| Eltern-Report | kein Versand; `generate_parent_report` erzeugt den Report, die Function hat keinen Mail-Aufruf | `git grep mailSenden` nur in `mail_senden`, `auth_mail` |
| SQL-Versand (`pg_net`) | keiner | `git grep pg_net` in `supabase/migrations`: keine Treffer |

`parent_student` liest nur `/parent` (über RLS und `is_parent_of_student`). Diese Seiten sind pausiert.

## Offen

1. **Eltern-Portal pausiert; vor Reaktivierung prüfen, was Eltern sehen dürfen.** Die `/parent`-Seiten und die
   Lese-Policies bleiben bestehen. Ohne Eltern-Konto kommt dort niemand mehr an, außer über ein Konto, das das
   Werkzeug noch nicht entfernt hat.
2. **Auth-Konten ohne Profil:** Das Werkzeug erfasst nur Konten mit Profil-Rolle `parent`. Hat `vertrag_abschluss`
   früher ein Eltern-Konto angelegt und ist danach gescheitert, kann ein Auth-Konto ohne Profil übrig sein.
   Bestandsaufnahme X0: 11 Auth-Konten ohne Profil. Nicht im Auftrag.
3. **„Passwort vergessen“** bleibt für alle Konten (K1, Entscheidung 4). Nach dem Entfernen der Eltern-Konten gibt
   es dort für Eltern nichts mehr zurückzusetzen.
