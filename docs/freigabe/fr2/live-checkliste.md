# FR-2 · Live-Checkliste (nach dem Merge)

Alles ist eingespielt und auf `dev` gemergt. Diese Schritte macht ein Admin bzw. Lena in der App.

1. **Seite öffnen:** Admin → Inhalte → **LSA-Abdeckung** (`/admin/lsa-abdeckung`). Beim ersten Laden rechnet die
   Seite den Zwischenspeicher neu (er ist seit F4.1 als veraltet markiert). Danach lädt jede Ansicht in rund 0,2 s.
   - **Ampel vorher notieren:** Klasse 9 und 10, Q3, Kennzahlen grün / gelb / rot und „Schulen mit LSA im Fenster“.
   - Stand 09.11.: 0 grün, 0 gelb.
2. **Fokus-Schulen setzen:** Stern vor der Schule.
   - Vorschlag: **Friedrich-Wilhelm-Gymnasium** (FWG, Eichpunkt Batu).
   - Danach „nur Fokus-Schulen“ einschalten und prüfen, ob die Schule oben steht.
3. **Folge der Klassenarbeiten pflegen:**
   - Eine Zelle der Fokus-Schule antippen; rechts erscheint „Klassenarbeiten · Schule, Klasse“.
   - Je Arbeit Nr., Themen und, wenn bekannt, das Datum eintragen und „Arbeit bestätigen“ drücken.
   - Prüfen: Die Matrix zeigt danach für diese Klasse nur die bestätigten Arbeiten, **ohne „geschätzt“**.
4. **Lena zeigt den Reiter „Gezielt prüfen“:**
   - `/coach/pruefen` öffnet ohne Parameter direkt diesen Reiter.
   - Kopf prüfen: „Noch 134 Aufgaben · danach ist die LSA an 31 weiteren Schulen möglich“ (Stand 09.11.).
   - „Gezielt prüfen starten“. Nach jedem „passt“ öffnet sich die nächste Aufgabe der Liste, und die Meldung nennt
     die Wirkung.
   - Die Reiter „Für die LSA“ und „Für die Session“ sind unverändert.
5. **Eine Sammelfreigabe:**
   - Sobald Lena einige Aufgaben mit „passt“ bewertet hat, zeigt die Seite LSA-Abdeckung „Alles Geprüfte freigeben (n)“.
   - Drücken. Die Rückmeldung lautet „x Aufgaben freigegeben, y Pakete jetzt grün oder gelb, an z Schulen“.
   - Aufgaben, die am Gate scheitern, bleiben stehen.
6. **Ampel nachher** mit Schritt 1 vergleichen.
   - Für den Eichpunkt FWG Kl. 9 „Reelle Zahlen“ reicht die neue `bruch_dezimal`-Aufgabe (Rang 8 der Liste), um
     von Rot auf Gelb zu kommen (`eichpunkt-batu.md`).
7. **Offen für Rasit** (siehe `bericht.md`):
   - `rationale_zahlen → potenzen`
   - Kanten-Hinweise zur Statistik
   - O1
