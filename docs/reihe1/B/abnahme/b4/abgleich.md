# B4 Abnahme · MP4 und Kapitel gegen die Vorschau

Lokal gerendert (`npm run studio:render -- --skript docs/reihe1/referenz/quadratwurzel-skript.json --welt fussball --ohne-hochladen …`), ohne Hochladen nach Prod, ohne Stimme (geschätzte Dauer).

- ffprobe: `h264`, 1920 × 1080, 30 fps, 1675 Frames, 55,833 s = Zeitplan der Vorschau (1675 Frames).
- Kapitel (`kapitel-fussball.json`) und Sequence-Starts kommen aus derselben Rechnung (`zeitplan.ts`); Abweichung 0 Frames.
- Bildvergleich je Kapitel: MP4-Frame bei Kapitelstart + 12 Frames gegen das Vorschaubild desselben Frames (Remotion renderStill, gleiche Daten). RMSE normiert; „gegen“ = Vergleich mit dem vorigen Beat als Gegenprobe:

```
b1 t=0.417 gleich (0.0149416) | gegen  
b2 t=6.383 gleich (0.00605537) | gegen b1 (0.0763293)
b3 t=12.550 gleich (0.00512885) | gegen b2 (0.0696288)
b4 t=16.317 gleich (0.0048936) | gegen b3 (0.0109251)
b5 t=21.317 gleich (0.0047813) | gegen b4 (0.0456721)
b6 t=26.050 gleich (0.019253) | gegen b5 (0.0835432)
b7 t=32.417 gleich (0.0353049) | gegen b6 (0.095117)
b8 t=37.683 gleich (0.0160491) | gegen b7 (0.085891)
b9 t=45.550 gleich (0.0212836) | gegen b8 (0.0492508)
b10 t=54.250 gleich (0.0051608) | gegen b9 (0.0749341)
```

Jeder MP4-Frame liegt deutlich näher an seinem eigenen Beat als am vorigen → Sprung und Kapitel stimmen auf einen Frame (0,033 s), also auf 0,1 s. Bildbeispiel: `vorschau-gegen-mp4.jpg` (b5, b7).

Server-Render (Vercel Sandbox) und Hochladen: Live-Checkliste.
