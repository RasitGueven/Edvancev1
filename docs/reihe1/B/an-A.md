# Von B an A (Reihe 1)

Stand 27.10.2026 · Auftrag B (Studio)

1. **Check-Aufgaben der Erklärvideos.** `studio_skript_speichern` (Migration `20261027130817_studio_modell`) legt je
   Mini-Check eine Aufgabe in `tasks` an: `source = 'edvance_studio'`, `einsatz = '{check}'`, `input_type = 'MC'`,
   `status = 'draft'`, Lösung in `task_solutions` (`acceptance.known_errors` aus den Optionen). Kein Fremdschlüssel
   auf `tasks`, nur plpgsql. Bitte die Pool-Regel aus A1 so fassen, dass `einsatz = {check}` ohne `lsa`/`session`
   erlaubt bleibt (wie die E1-Checks), und neue Pflichtspalten mit Default anlegen. Ändert sich das, bitte in
   `docs/reihe1/B/` melden oder eine Funktion zum Anlegen anbieten; B stellt dann um.
2. **Fehlbild-Schlüssel.** B braucht die acht `qf_*`-Schlüssel aus Konzept §8 in `fehlbild_labels`. Der Import
   lehnt Schlüssel außerhalb des Katalogs ab.
