# R7-8 · Texte alt → neu (Entwürfe für Lena)

Stand 20.10.2026. Alle Texte im Namespace `elternbericht`. Neu und geändert sind Entwürfe; Lena gibt sie frei.

## Geändert

| Schlüssel | alt | neu |
|---|---|---|
| `s1.geprueft.hinweisThema` | Zahlen und Farben in diesem Bericht zeigen nur die direkt geprüften Bereiche. | Die Farben in diesem Bericht zeigen nur die direkt geprüften Bereiche. |
| `s2.profil.hinweis` | Jedes Segment steht für eine Kompetenz | Jedes Kästchen steht für einen Bereich |
| `s2.fussnote` | Jedes Segment steht für einen geprüften Bereich. Das ist keine Note … | Jedes Kästchen steht für einen geprüften Bereich. Das ist keine Note … (Rest unverändert) |

## Neu

| Schlüssel | Text | wo |
|---|---|---|
| `s2.profil.abgeleitet` | {{count}} abgeleitet | rechte erste Zeile, hinter „· “ oder allein |
| `s2.profil.klasse` | Klasse {{k}} | unter dem Feldnamen, eine Stufe |
| `s2.profil.klasseSpanne` | Klasse {{von}}–{{bis}} | unter dem Feldnamen, mehrere Stufen |
| `s2.profil.ariaAbgeleitet_one` | {{count}} weiterer ergibt sich aus den Aufgaben. | Vorlesetext, hinter `s2.profil.aria` |
| `s2.profil.ariaAbgeleitet_other` | {{count}} weitere ergeben sich aus den Aufgaben. | Vorlesetext, hinter `s2.profil.aria` |
| `s2.profil.ariaNurAbgeleitet_one` | {{feld}}: nicht einzeln geprüft, {{count}} Bereich ergibt sich aus den Aufgaben. | Vorlesetext einer Zeile nur mit abgeleiteten |
| `s2.profil.ariaNurAbgeleitet_other` | {{feld}}: nicht einzeln geprüft, {{count}} Bereiche ergeben sich aus den Aufgaben. | Vorlesetext einer Zeile nur mit abgeleiteten |
| `s2.profil.legende.abgeleitet` | Aus den Aufgaben abgeleitet | Legende, dritter Eintrag |
| `s2.fussnoteAbgeleitet` | Umrandete Kästchen sind Bereiche des Themas, die sich aus den geprüften Aufgaben ergeben. Sie wurden nicht einzeln geprüft und tragen deshalb keine Farbe. | Fußnote, Zusatz |

Abweichungen vom Bauauftrag (bitte prüfen):

- `ariaAbgeleitet` hat eine Einzahl. Der Auftrag nennt nur „{{count}} weitere ergeben sich …“, das ergäbe „1 weitere ergeben sich“.
- `ariaNurAbgeleitet` ist neu. Für eine Zeile nur mit abgeleiteten Bereichen passt `s2.profil.aria` („0 geprüft, davon 0 sicher …“) nicht, und „weitere“ ohne Bezug auch nicht.
