# W1-4 Befunde – Schulen, Schulpläne, Zuordnung

Stand 01.10.2026. Die datengetriebenen Listen (Schulen ohne Plan, fehlende Jahrgänge,
nicht zuordenbare Vorhaben, harmonisierte Zuordnungen, Befunde je Schule) erzeugt
`scripts/schulplaene/bauen.py` in [befunde-daten.md](befunde-daten.md). Hier stehen die
Entscheidungen und die Zweitprüfung.

## Schulliste

- 43 Gymnasien laut Liste der Stadt Köln, deckungsgleich mit der Recherche vom 01.10.2026.
  Websites von den Adressseiten der Stadt, für die 6 privaten Schulen von der Listenseite.
- Namen ohne Straßenzusatz. Claudia Agrippina heißt bei der Stadt „Aufbaugymnasium“, auf der
  eigenen Website „Privatgymnasium“ – übernommen ist „Privatgymnasium“.
- Die Stadt führt Gymnasium Brügelmannstraße unter der Adresse
  `gesamtschule-bruegelmannstrasse`; der Plan (Fassung 23.10.2025) enthält nur Kl. 5 (5.1–5.7).
  Vermutlich eine Neugründung im Aufbau.
- In `schulen` steht seit dem Vertragsformular die Zeile „Gymnasium / Köln“ (Testeintrag,
  angelegt 25.09.2026). Nicht angefasst, weil eventuell referenziert (`students.schule_id`,
  `vertraege.schule_id`, beide `on delete restrict`).

## Fehlende Jahrgänge

Bei Schulen, für die nur Kl. 8/9 bekannt waren, wurde auf der Website nach den übrigen
Jahrgängen gesucht (gleiches Dateimuster, dann Mathe-Seite der Schule):

| Schule | gefunden | weiterhin fehlend |
|---|---|---|
| Apostelgymnasium | 5, 6, 7, 10 | – |
| Elisabeth-von-Thüringen | 5, 6, 7, 10 | – |
| Friedrich-Wilhelm | 5, 6, 10 | – |
| Köln-Pesch | 5, 6, 7, 10 | – |
| Rodenkirchen | 5, 6, 7, 10 (anderes Dateimuster) | – |
| Humboldt | 5/6, 7, 10 | – |
| Liebfrauenschule | 5, 6, 7, 10 | – |
| Hildegard-von-Bingen | 7 | 5, 6, 10 |
| Leonardo-da-Vinci | 7 | 5, 6, 10 |
| Irmgardis | – | 5, 6 |

Kaiserin-Augusta-Schule und Königin-Luise-Schule verlinken auf HTML-Seiten; die PDFs
sind direkt verlinkt (KLS: drei Dateien 5–8, 9, 10).

## Text der PDFs

Gelesen mit pypdf im Layout-Modus. Bei keinem der 72 PDFs war pdfplumber nötig. Hinweise
„Rotated text discovered“ betreffen gedrehte Spaltenköpfe, nicht die Vorhabentitel.

## Zuordnungsregeln

- **Doppelt geführte Vorhaben.** Der Muster-Lehrplan führt Brüche (5/6), Wahrscheinlichkeit
  (7/8) und „Daten und Wahrscheinlichkeit“ (9/10) wahlweise in einer von zwei Klassen.
  Übernommen wie im Plan: in beiden Klassen. Ausnahme, wenn der Plan selbst festlegt, wo es
  läuft: Erich Kästner (Fußnote), Elisabeth-von-Thüringen (Kl. 8 UV I), Humboldt (siehe unten).
- **Statistik in Kl. 7–9** (Entscheidung Rasit): Stochastik-Thema der Stufe, kein neues
  Thema. Kl. 7/8 → `zufallsexperimente`, reine Statistik-Vorhaben Kl. 9/10 →
  `statistik_beurteilen`. Je Fall eine Zeile „Statistik in Kl. X“ in befunde-daten.md.
- **Harmonisierte Mischtitel des Muster-Lehrplans** (Regel in `bauen.py`, jede Änderung in
  befunde-daten.md):
  - „Kreise, Prismen und Zylinder“ → `kreis` (vorher 9× kreis, 9× prismen_zylinder)
  - „Daten und Wahrscheinlichkeit“ Kl. 9/10 → `bedingte_wahrscheinlichkeit` (vorher 27 zu 5)
  - „Muster und Figuren“ Kl. 6 → `winkel` (vorher 9 zu 7; nach der Zweitprüfung ergänzt,
    siehe unten)
- **Nicht zuordenbar** bleiben „Modellieren von Messreihen mit unterschiedlichen
  Funktionstypen“ (Kl. 10, mehrere Funktionsklassen) und wenige weitere – Liste in
  befunde-daten.md. Kein Thema erfunden.

## Zweitprüfung der Zuordnung (Phase D)

8 Schulen, gezogen mit `random.seed(20261001)` aus den 32 Schulen mit Plan:
Köln-Pesch, Müngersdorf, Heinrich-Heine, Heinrich-Mann, Humboldt, Kaiserin-Theophanu,
Leonardo-da-Vinci, Schiller. Zwei frische Agenten haben sie aus den Texten selbst
ausgelesen und zugeordnet, ohne Zugriff auf `plaene/`, `bauen.py`, `docs/themen/` oder
Migration 3. Verglichen mit `scripts/schulplaene/vergleichen.py` (Paarung über Titel,
Bonus für gleiche Position).

**Erster Vergleich** (vor der Regel „Muster und Figuren“): 5 abweichende Paare von 249.
- Heinrich-Heine Kl. 5 (3 Paare): Fehlpaarung des Skripts („Rechnen“ ↔ „Flächen“). Beide
  Fassungen sind identisch (gleiche 5 Vorhaben, gleiche Keys). Skript korrigiert.
- Müngersdorf Kl. 6 „Muster und Figuren“: erste `symmetrie`, zweite `winkel`. Echte
  Abweichung. Sie zeigte, dass dieser Titel in der ersten Zuordnung schulübergreifend
  uneinheitlich war (9× winkel, 7× symmetrie). Regel ergänzt → `winkel`.
- Humboldt Kl. 10 „Daten und Wahrscheinlichkeit“: erste nicht erfasst (nur Kl. 9), zweite
  `bedingte_wahrscheinlichkeit` in Kl. 10 zusätzlich. **Offen, nicht angeglichen** – der
  Plan nennt es wahlweise in 9 oder 10.

**Zweiter Vergleich** (eingespielte Fassung): 247 von 248 Paaren gleich; einzige Abweichung
Humboldt Kl. 10 wie oben.

Weitere Hinweise der Zweitprüfung, ohne Auswirkung auf thema_key:
- Humboldt: der Plan für Kl. 5/6 trägt Stand 12/2019; `stand` der Schule ist „08/2023 · 12/2022“.
- Schiller Kl. 7 UV IV: Übersicht nennt 22 Std., Detailseite 15 Std.; beide Durchgänge haben 22.
- Heinrich-Heine: Halbjahr aus dem Quartalscode abgeleitet (beide Durchgänge gleich).
