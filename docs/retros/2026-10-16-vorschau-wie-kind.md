# Retro 16.10.2026 – Kinderansicht in der Prüfansicht wie auf dem Tablet

## Gebaut
- `PreviewStage` (Prüfansicht, Erklär-Checks, Authoring-Editor) zeigt Stamm, Teilaufgaben und MC-Optionen als
  reinen Text mit erhaltenen Umbrüchen statt über `MathContent` (Markdown + KaTeX). So setzt auch das Tablet
  (`edvance-app`, `Buehne.tsx`) den Text.
- Test in `AuthoringPreview.test.tsx`: Umbrüche bleiben, kein Markdown, kein LaTeX.

## Befund
- Annahme im Auftrag war „Kind sieht -2^2 hochgestellt“. Stimmt nicht: Das Tablet zeigt `-2^2` genauso roh.
- Echte Abweichung: Markdown klappte einfache Umbrüche und Mehrfach-Leerzeichen ein. 16 von 257 Pilot-Aufgaben
  betroffen (9 LGS, 3 Binome, 1 LGS grafisch, 3 Wurzeln).
- Lösungsweg, Hinweise, typische Fehler: schon vorher reiner Text, keine Abweichung.

## Offen
- `^` im Aufgabentext (16 Pilot-Aufgaben) ist ein Inhaltsthema → eigener Auftrag `fix/rasit-hochzahlen-inhalt`.
- Das Tablet rendert `payload.table` nicht, die Vorschau schon (keine Pilot-Aufgabe betroffen).
- Platzhalter „Deine Antwort“ in der Vorschau kaum lesbar (vorbestehend).
