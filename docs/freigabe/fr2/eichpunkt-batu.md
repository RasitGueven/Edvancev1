# FR-2 · Eichpunkt Batu

**Stand:** 09.11.2026, Prod per `dbread` nach dem Einspielen von F1 (`20261109114850`). Stellschrauben unverändert
(2 Texte, 1 ohne MC).

**Paket:** Friedrich-Wilhelm-Gymnasium, Klasse 9, Arbeit 1 „Reelle Zahlen und Wurzeln“ (`reelle_zahlen`), geschätzt,
Quartal 1. Die LSA dazu lief in der Praxis gut. Erwartung der Gründer: mindestens Gelb.

**Ergebnis: Rot.** 1 fehlender Pflicht-Skill, 5 fehlende Skills insgesamt, 5 fehlende Texte, Einstieg vorhanden.

| Skill | Teil | Pflicht | Texte im Pool | erfüllt |
|---|---|---|---|---|
| zahl_wurzel_irrational, zahl_wurzel_naeherung, zahl_wurzel_teilweise | Einstieg | ja | 6 / 5 / 4 | ja |
| runden_ueberschlag, zahl_wurzel_gesetze, zahl_wurzel_quadrat | Voraussetzung | ja | 3 / 5 / 4 | ja |
| potenzen, runden_ueberschlag | Rand (Fall B) | ja | 8 / 3 | ja |
| **bruch_dezimal** | Voraussetzung (A) und Rand (B) | **ja** | **1** | **nein** |
| bruch_kuerzen, dezimal_add_sub, dezimal_mult, dezimal_div | Tiefe | nein | je 1 | nein |

**Warum Rot:** Einziger Grund ist `bruch_dezimal`. Der Skill hat 4 ready-Aufgaben im Pool, alle mit **demselben
Aufgabentext** (Textschlüssel `7042935f…`, nur die Zahlen unterscheiden sich), dazu 2 Entwürfe mit demselben Text. Die
Regel verlangt 2 verschiedene Texte, weil eine LSA-Sitzung nie zwei Aufgaben mit gleichem Text ausgibt (LSA-L2). Den
Zweitbeleg braucht die Auswahl nur, wenn die erste Aufgabe MC war oder falsch beantwortet wurde. Antwortet ein Kind auf
die erste Nicht-MC-Aufgabe richtig, ist das Urteil sofort final (Bericht §2b). Deshalb lief die LSA in der Praxis gut:
Für ein Kind, das `bruch_dezimal` kann, fehlt der zweite Text nie.

**Was es Gelb macht:** eine neue `bruch_dezimal`-Aufgabe mit anderem Text (F4.2), von Lena geprüft und freigegeben.
Für Grün fehlen danach noch `bruch_kuerzen` (ebenfalls F4.2) und ein zweiter Text für die drei `dezimal_*`-Skills
(Entwürfe dafür stehen in der Prüfliste).

**Nicht geändert:** Stellschrauben (Entscheidung der Gründer). Ob für Pflicht-Skills ein Text reicht, wenn die erste
Aufgabe ohne MC ist, ist eine Gründerfrage (Bericht §9, Frage 5).

**Abfrage** (dbread, Admin-Claims gesetzt):

```sql
select set_config('request.jwt.claims', json_build_object('sub', '<admin-id>', 'role', 'authenticated')::text, false);
select ampel, fehlende_pflicht_skills, fehlende_skills, fehlende_texte, hat_einstieg
  from lsa_abdeckung(9) where schule ilike 'Friedrich-Wilhelm%' and thema_keys = '{reelle_zahlen}';
select * from lsa_paket_skills((select id from schulen where name ilike 'Friedrich-Wilhelm%'), 9, 1);
```
