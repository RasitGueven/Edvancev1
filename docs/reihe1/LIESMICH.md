# Sessionreihe 1 · Vier Bauaufträge

Stand 27.10.2026 · für Rasit

| Auftrag | Was am Ende steht | Repos | Wartet auf |
|---|---|---|---|
| **A** Sessionaufgaben | Pool-Trennung, Bauform-Motor mit Prüfmaschine, sechs neue Formate, Bauform-Prüfung im Lena-Board, Melde-Knopf, Bewährung, alle 47 Bauformen der Reihe zur Prüfung bei Lena | Edvancev1, edvance-app | Migrationen, Einbaupunkt von C |
| **B** Studio | Studio S0–S6, zwei neue Bausteine (Parabel, Flächenmodell), Video in Session und Mediathek, acht Skripte V1–V8 zum Einfügen für Ashkan | Edvancev1, edvance-app | Migrationen, E1 in Prod, Fehlbild-Schlüssel von A, Offen-Regeln von D |
| **C** Session-Workflow | Reihenplanung rückwärts von der Klassenarbeit, Warm-up mit Abruf, Kernarbeit mit Lösungsbeispiel und Transfer, Recap, Generalprobe, Check-out ohne Quest-Tage, Reihenplan in der Coach-Sicht | Edvancev1, edvance-app | Migrationen, Funktionen und Komponenten von A, B und D |
| **D** Home light | Anmeldung mit Code, Quests jederzeit, Themenbaum mit Übungsspuren, Profil, Eddie ohne Sprachmodell, Kachel „Zuhause geübt“ mit „Zeig's mir“, iOS- und Android-Build | edvance-app, Edvancev1 | Migrationen, Funktionen und Komponenten von A, B und C, `eas login` |

## So startest du

1. `reihe1-pakete.zip` in den Windows-Downloads-Ordner legen.
2. Für B: `ELEVENLABS_API_KEY` in Vercel (Edvancev1) und in `~/Edvancev1/.env.local`.
3. Für D: Apple Developer, Google Play Console, einmal `eas login` (für jeden nativen Build nötig, nicht erst für den Upload). Das Testkind mit Testcode für die Store-Prüfer legst du selbst an (Phantasiedaten).
4. In jedem Auftrag die Zeile `EINSPIELEN = rasit` lassen (du spielst ein) oder auf `orchestrator` setzen (der Agent spielt nach der Zweitprüfung selbst ein).
5. Vier Zellij-Tabs, je einen Block hineinkopieren. Alle vier dürfen gleichzeitig laufen. Jeder arbeitet in eigenen Worktrees (`../Edvancev1-A`, `../edvance-app-A` usw.) und hat höchstens einen Subagenten gleichzeitig.

## Woran du siehst, wo sie stehen

- `docs/reihe1/<A|B|C|D>/fortschritt.md` im jeweiligen Worktree: eine Zeile je Schritt.
- `~/einspielen/`: fertige Einspiel-Befehle, wenn `EINSPIELEN = rasit`. Der Agent wartet, bis das Objekt in Prod existiert, und macht dann weiter.
- PRs gegen dev, je Phase eine, mit Merge-Reihenfolge in der Beschreibung. Gemergt wird nur von dir.
- Am Ende je Auftrag `bericht.md` und eine `live-checkliste.md` für den Test nach dem Merge.

## Reihenfolge beim Mergen

1. **Zuerst die vier kleinen Schnittstellen-PRs** A0b, B0b, C0b und D0b (nur Typen, Props, Platzhalter, Einbaupunkte). Die anderen Aufträge warten darauf, sobald sie fremde Komponenten brauchen.
2. Dann A1 und A2, weil B, C und D deren Funktionen und Fehlbild-Schlüssel brauchen, und D2 (Offen-Regeln, Übung zuhause).
3. Danach innerhalb jedes Auftrags in der Reihenfolge der Phasen.

Migrationen kommen vor dem Merge nach Prod. Jedes Einspiel-Skript prüft selbst, ob die Objekte, die es voraussetzt, schon da sind, und bricht sonst ab. Spiel in diesem Fall zuerst das Skript des anderen Auftrags ein.

## Grundlage

`Konzept-Sessionreihe-1-und-Bauformen.md` ist für alle vier verbindlich. Abschnitt 9 legt fest, wem welche Tabelle und Funktion gehört.
