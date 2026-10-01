# Retro 2026-10-01 – Themenkatalog nach Stufen und Kölner Schulpläne (W1-4)

## Gebaut
- Migration 1 `20261001114732_themen_schulplaene_schema.sql` (Schema): themen.stufe/schlagworte/klp/sort,
  thema_einstieg, schulen erweitert, schul_themenplan, leads.schule_id, lead_themen, lsa_sessions.thema_key.
- Migration 2 `20261001123005_themen_katalog_mathe.sql`: 37 Mathe-Themen (12/11/14 je Stufe), 5 Einstiegsknoten.
- Migration 3 `20261001125708_schulen_schulplaene_koeln.sql` (erzeugt): 43 Gymnasien, 1086 Vorhaben aus 32 Plänen, 59 Schlagwort-Nachträge.
- `scripts/schulplaene/`: `laden.py` (PDF → cache/, pypdf), `bauen.py` (Migration 3, CSV, befunde-daten.md), `vergleichen.py` (Zweitprüfung).
- Alle drei eingespielt (Freigabe im Chat), Historie md5-gleich mit den Dateien.

## Entscheidungen
- `schulen` existierte (Verträge P1): erweitert statt neu, Unique-Index und Admin-RLS unverändert, keine Coach-Leserechte (Rasit).
- `thema_einstieg` nur admin/coach lesbar; LSA-Funktionen sind Security Definer (Rasit).
- `daten_streumasse` → Erprobungsstufe wie im KLP; Statistik in Kl. 7–9 beim Stochastik-Thema der Stufe (Rasit).
- `themen.klasse` = erste Klasse der Stufe (veraltet).
- Drei Mischtitel des Muster-Lehrplans per Regel einheitlich zugeordnet (befunde.md).
- pypdf statt pdftotext (kein sudo); pdfplumber war nicht nötig.

## Gelernt
- Eine Migration > 128 KB passt nicht als psql-Variable in argv (E2BIG); per `\set x \`cat f; echo\`` einlesen, das `echo` hält das abschließende Newline byte-genau.
- Parallele Auslese-Agenten entscheiden wiederkehrende Mischtitel unterschiedlich; Regel zentral im Bauskript statt im Prompt.

## Offen
- Humboldt Kl. 10 „Daten und Wahrscheinlichkeit“ (Zweitprüfung: zusätzlich in Kl. 10).
- Fehlende Jahrgänge HvB 5/6/10, Leonardo 5/6/10, Irmgardis 5/6; 11 Schulen ohne Plan.
- Einstiegsknoten der Themen-Läufe Lineare Funktionen, Zins, Kreis.
