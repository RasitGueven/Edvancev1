# Bestand Lineare Funktionen (E2b.1, nur gelesen)

Stand 07.10.2026, Prod per `~/bin/dbread` (`show transaction_read_only` → `on`). Abfragen: unten.

## Thema und Reihenfolge der Skills

`themen`: `lineare_funktionen` · „Lineare Funktionen“ · KLP `{Fkt-3,Fkt-4,Fkt-5,Fkt-6,Fkt-7}`.

Reihenfolge aus `ziel_fertigkeiten(<Kind ohne Lernpfad im Thema>, 'lineare_funktionen')` (Systemaufruf, nur Thema-Zeilen):

| Nr | skill_key | Label | Klasse (`skills.klasse_herkunft`) | Rolle |
|---|---|---|---|---|
| 1 | `fkt_linear_steigung` | Steigung einer linearen Funktion | 8 | einstieg |
| 2 | `fkt_linear_yabschnitt` | y-Achsenabschnitt einer linearen Funktion | 8 | einstieg |
| 3 | `fkt_linear_gleichung` | Funktionsgleichung y = mx + b aufstellen | 8 | einstieg |
| 4 | `fkt_linear_graph` | Graph einer linearen Funktion | 8 | thema |
| 5 | `fkt_linear_nullstelle` | Nullstelle einer linearen Funktion | 8 | thema |

`thema_einstieg` enthält Steigung, y-Abschnitt und Gleichung; `skill_thema` alle fünf.

## Aufgaben je Skill

| skill_key | Status | Einsatz | Quelle | Anzahl | mit Figur |
|---|---|---|---|---|---|
| `fkt_linear_steigung` | draft | `{lsa,session}` | `edvance_k8_linfkt` | 6 | 0 |
| `fkt_linear_yabschnitt` | draft | `{lsa,session}` | `edvance_k8_linfkt` | 6 | 0 |
| `fkt_linear_gleichung` | draft | `{lsa,session}` | `edvance_k8_linfkt` | 6 | 0 |
| `fkt_linear_graph` | draft | `{lsa,session}` | `edvance_k8_linfkt` | 6 | 6 |
| `fkt_linear_nullstelle` | draft | `{lsa,session}` | `edvance_k8_linfkt` | 6 | 0 |

Alle 30 Aufgaben stammen aus der Charge k8-linfkt (`tools/k8-linfkt-aufgaben.mjs`). Keine ist freigegeben, keine hat den
Einsatz `check`.

## Fehlbilder je Skill (`acceptance.known_errors`)

„Aufgaben“ = Zahl der Aufgaben des Skills mit diesem Slug; „Werte“ = Zahl der falschen Schreibweisen, die auf ihn zeigen.
„frei“ = `fehlbild_labels.freigegeben_am` gesetzt.

| skill_key | Slug | Aufgaben | Werte | frei | Klartext |
|---|---|---|---|---|---|
| `fkt_linear_steigung` | `steigung_kehrwert` | 6 | 19 | nein | Teilt die waagerechte durch die senkrechte Änderung – die Steigung steht auf dem Kopf. |
| | `seiten_verwechselt` | 3 | 9 | ja | Subtrahiert in umgekehrter Reihenfolge, Ergebnis mit falschem Vorzeichen. |
| | `b_ignoriert` | 2 | 14 | ja | Teilt sofort, ohne die Konstante vorher wegzurechnen. |
| | `betrag_fehler` | 1 | 2 | ja | Betrag richtig, Vorzeichen des Ergebnisses gekippt. |
| | `nur_einmal_addiert` | 1 | 2 | nein | Ein Betrag wurde nur einmal dazugezählt, obwohl er mehrfach vorkommt. |
| `fkt_linear_yabschnitt` | `achsenabschnitt_verwechselt` | 4 | 23 | nein | Gibt die Nullstelle als y-Achsenabschnitt an oder umgekehrt. |
| | `m_b_vertauscht` | 3 | 7 | nein | Liest Steigung und y-Achsenabschnitt vertauscht aus der Gleichung ab. |
| | `betrag_fehler` | 2 | 4 | ja | Betrag richtig, Vorzeichen des Ergebnisses gekippt. |
| | `groessen_vertauscht` | 2 | 33 | ja | Vertauscht Grundbetrag und Rate beim Aufstellen. |
| | `addiert_statt_subtrahiert` | 1 | 2 | ja | Addiert die Konstante auf beiden Seiten statt sie abzuziehen. |
| `fkt_linear_gleichung` | `m_b_vertauscht` | 3 | 7 | nein | Liest Steigung und y-Achsenabschnitt vertauscht aus der Gleichung ab. |
| | `vorzeichen_ignoriert` | 2 | 8 | ja | Lässt die Minuszeichen weg und addiert die Beträge. |
| | `addiert_statt_subtrahiert` | 1 | 2 | ja | Addiert die Konstante auf beiden Seiten statt sie abzuziehen. |
| | `b_ignoriert` | 1 | 6 | ja | Teilt sofort, ohne die Konstante vorher wegzurechnen. |
| | `betrag_fehler` | 1 | 2 | ja | Betrag richtig, Vorzeichen des Ergebnisses gekippt. |
| | `falsche_groesse_beantwortet` | 1 | 6 | ja | Rechnet richtig, gibt aber die andere gesuchte Größe an. |
| | `groessen_vertauscht` | 1 | 24 | ja | Vertauscht Grundbetrag und Rate beim Aufstellen. |
| | `seiten_verwechselt` | 1 | 3 | ja | Subtrahiert in umgekehrter Reihenfolge, Ergebnis mit falschem Vorzeichen. |
| | `steigung_kehrwert` | 1 | 2 | nein | Teilt die waagerechte durch die senkrechte Änderung – die Steigung steht auf dem Kopf. |
| `fkt_linear_graph` | `m_b_vertauscht` | 3 | 7 | nein | Liest Steigung und y-Achsenabschnitt vertauscht aus der Gleichung ab. |
| | `koordinaten_vertauscht` | 2 | 10 | nein | Liest x- und y-Koordinate in vertauschter Reihenfolge ab. |
| | `steigung_kehrwert` | 2 | 8 | nein | Teilt die waagerechte durch die senkrechte Änderung – die Steigung steht auf dem Kopf. |
| | `achsenabschnitt_verwechselt` | 1 | 6 | nein | Gibt die Nullstelle als y-Achsenabschnitt an oder umgekehrt. |
| | `betrag_fehler` | 1 | 2 | ja | Betrag richtig, Vorzeichen des Ergebnisses gekippt. |
| | `falsche_groesse_beantwortet` | 1 | 2 | ja | Rechnet richtig, gibt aber die andere gesuchte Größe an. |
| | `groessen_vertauscht` | 1 | 6 | ja | Vertauscht Grundbetrag und Rate beim Aufstellen. |
| | `koordinate_vorzeichen_verloren` | 1 | 2 | nein | Koordinate richtig abgelesen, aber das Minus fehlt. |
| `fkt_linear_nullstelle` | `achsenabschnitt_verwechselt` | 4 | 12 | nein | Gibt die Nullstelle als y-Achsenabschnitt an oder umgekehrt. |
| | `betrag_fehler` | 4 | 9 | ja | Betrag richtig, Vorzeichen des Ergebnisses gekippt. |
| | `division_vergessen` | 2 | 5 | ja | Umformung richtig, der letzte Schritt (Division durch den Koeffizienten) fehlt. |
| | `vorzeichen_beim_umstellen` | 2 | 15 | ja | Betrag richtig, das Minus des Koeffizienten bleibt am Ergebnis hängen. |
| | `falsche_gegenoperation` | 1 | 6 | ja | Wiederholt die im Term sichtbare Rechenart statt sie umzukehren. |

Häufigkeit im Betrieb: `lsa_responses` hat zu diesen Skills **keine** Antwort mit `fehlbild_slug` (0 Zeilen). „Häufig“
heißt deshalb hier: in vielen Aufgaben des Skills hinterlegt (Spalte „Aufgaben“).

## Erklärsequenzen und Prüffragen

- `erklaer_kernidee`: 0 Zeilen, `erklaer_schritt`: 0 Zeilen (gesamt, nicht nur dieses Thema).
- `skill_pruefung` zu `fkt_linear_*`: 0 Zeilen.

## Abfragen

```sql
select thema_key, label, klp from themen where label ilike '%linear%' or thema_key ilike '%linear%';
select * from thema_einstieg where thema_key ilike '%linear%';
select st.* from skill_thema st where st.thema_key ilike '%linear%';
select z.reihenfolge, z.skill_key, z.label, z.klasse_herkunft, z.rolle
  from (select id from students limit 1) s, ziel_fertigkeiten(s.id, 'lineare_funktionen') z;
select skill_key, status, einsatz, source, count(*), count(f.task_id)
  from tasks t left join task_figures f on f.task_id = t.id
 where skill_key like 'fkt_linear_%' group by 1, 2, 3, 4;
with ke as (
  select t.skill_key, t.id, e.key wert, e.value #>> '{}' slug
    from tasks t join task_solutions s on s.task_id = t.id
   cross join lateral jsonb_each(coalesce(s.acceptance -> 'known_errors', '{}')) e
   where t.skill_key like 'fkt_linear_%' and jsonb_typeof(s.acceptance -> 'known_errors') = 'object')
select ke.skill_key, ke.slug, count(distinct ke.id), count(*), fl.klartext, fl.freigegeben_am is not null
  from ke left join fehlbild_labels fl on fl.slug = ke.slug group by 1, 2, 5, 6;
select t.skill_key, r.fehlbild_slug, count(*) from lsa_responses r join tasks t on t.id = r.task_id
 where t.skill_key like 'fkt_linear_%' group by 1, 2;
select count(*) from erklaer_kernidee; select count(*) from erklaer_schritt;
select skill_key, frage, status from skill_pruefung where skill_key like 'fkt_linear_%';
```
