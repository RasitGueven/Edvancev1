# Offene Punkte W2 · Wochenplan, Slot-Panel, Tagespanel

Stand 20.10.2026 · Branch `feat/rasit-slots-w2-wochenplan` · Bauauftrag `Bauauftrag-Slots-Wochenplan-v2.md`, Abschnitt W2 ·
Vorlage `slots-dummy-v2.html`. Reine Oberfläche, keine Migration, nichts unter `src/lib/supabase/**` oder `src/types/**`.

## Abweichungen vom Dummy (mit Grund)

1. **Einzel-Panel-Adresse `?einzel=YYYY-MM-DD_<session_id>`.** Der Auftrag nennt nur `?slot=` und `?tag=`. Damit auch
   das Session-Panel über Zurück schließt und sich teilen lässt, steht es ebenfalls in der URL; das Datum lädt die
   Woche aus `stundenplan_woche`.
2. **Ohne `?woche` zeigt der Plan die Woche des Panels.** `/admin/slots/termin/:datum/:zeitId` leitet wie verlangt auf
   `/admin/slots?slot=…` (ohne Woche); damit dahinter die passende Woche steht, nimmt die Seite das Datum des Panels.
   Schließt man ein direkt geöffnetes Panel, bleibt die Woche als `?woche=` stehen.
3. **Panel-Wechsel ersetzt den Schritt.** Tag → „Öffnen“ → Slot ersetzt den Eintrag in der Geschichte; Zurück schließt
   dann das Panel ganz (wie das X im Dummy), statt zum Tag zurückzuspringen.
4. **„Sofort-Session“ und „Einzel-Session“ heißen beide „Einzel-Session“.** `stundenplan_woche` und
   `slots_tag.sessions_ohne_raum` unterscheiden die beiden nicht.
5. **Kopf-Satz und Hinweise.** Die gelben „Hinweis“-Kästen des Dummys sind Erklärungen für das Gespräch und nicht
   gebaut. Unter den Räumen steht weiter der bisherige Satz zur Zuteilung („Die Räume teilt das System zu …“ bzw.
   „… beim Öffnen der Session festgeschrieben“), dazu die 10-Uhr-Regel wie im Dummy.
6. **Raster seitlich scrollbar statt Tagesansicht.** Die bisherige Tagesansicht für schmale Breiten (ein Tag, Umschalter
   Mo–Fr) und der Schalter „leere Zeiten zeigen“ sind entfallen; das Raster hat eine Mindestbreite und scrollt auf dem
   Telefon seitlich (Leitplanke des Auftrags), die Seite nicht. Für das Telefon ist das Tagespanel der schnelle Weg.
7. **Fächer-Chips in der Zelle entfallen** zugunsten der Raumzeilen (Dummy). Das Fach steht im Slot-Panel je Kind.
8. **„+ Kind“ nur in Räumen mit Coach.** Ein Raum ohne Coach bekommt kein „+ Kind“ (S4 nicht freigegeben, SL002);
   der Dummy blendet es dort ebenfalls aus. Ein voller Raum zeigt den Knopf gesperrt mit Grund (Titel und Satz darunter).
9. **„Kind hinzufügen“ im Kopf entfällt.** Der bisherige Dialog (Zusatztermin ohne Raum, `slots_kandidaten`) ist durch
   „+ Kind in <Raum>“ ersetzt (Entscheidung 5 des Bauauftrags: das Kind landet im gewählten Raum). Damit fehlen in der
   Liste die Zahl der offenen Einheiten und der Hinweis „verdrängt …“, die `slots_kandidaten` lieferte
   (`slots_kandidaten_alle` hat sie nicht, siehe unten).
10. **Raum öffnen und „Ganzer Termin fällt aus“** liegen im „…“-Menü im Panel-Kopf (wie bisher im Seitenkopf der
    Termin-Seite); der Dummy zeigt sie nicht.
11. **Session öffnen führt direkt in die Live-Sicht** (wie „Heute im Betrieb“); die alte Termin-Seite blieb stehen und
    zeigte danach „Zur Live-Sicht“.
12. **Kennzahl „Kinder ohne Raum“ entfällt** zugunsten „Räume mit Kindern ohne Coach“ (Entscheidung 2). Kinder ohne
    Raum stehen weiter rot in der Zelle („n ohne Raum“) und zuerst im Slot-Panel.
13. **Filter „Leitung“ des alten Stundenplans entfällt** (Dummy hat ihn nicht; die Einzel-Sessions stehen je Tag in der
    Zeile „Einzel“).

## Offene Punkte

1. **`slots_kandidaten_alle` ohne Einheiten und Verdrängung.** Für „Nur an diesem Termin“ wären die Zahl der offenen
   Einheiten und „dafür fällt der Stammplatz-Termin am … weg“ hilfreich (gab es in `slots_kandidaten`). Braucht eine
   Erweiterung der Funktion (Foundation), nicht gebaut.
2. **„Jede Woche“ graut nach den Regeln des Zusatztermins aus.** `slots_kandidaten_alle` prüft diesen einen Termin.
   Ob ein Stammplatz an den nächsten sechs Terminen passt (voll, Ferien, Budget), entscheidet erst
   `stammplatz_vergeben`; eine Ablehnung erscheint als Satz. Eine Vorschau wie im Stammplatz-Dialog (W3,
   `stammplatz_vorschau`) wäre der nächste Schritt.
3. **SL-Codes im Dialog teils mit Termin-Satz.** Für SL001–SL007, SL011–SL013, `kein_vertrag` und `vertrag_ab` gibt es
   eigene, aufs Kind bezogene Sätze (`wochenplan2.grund.*`); seltene Codes (SL008–SL010) nutzen den Satz aus `fehler.*`.
4. **`termin/TerminKarten.tsx` ist nur noch ein Re-Export** von `ZustandBadge` für `kind/KindKarten.tsx` (Paket W3).
   Nach dem Merge von W3 dort den Import auf `../panel/TerminKarten` umstellen und die Datei löschen.
5. **Alte Termin-Links bleiben als Umleitung.** „Heute im Betrieb“ (`betriebModel.ts`, „Zum Termin“) und die
   Abweichungen im Reiter Coaches verlinken weiter `/admin/slots/termin/…`; die Route leitet ins Slot-Panel. Umstellen
   auf `slotZiel(…)`, sobald W4 gemergt ist (Coaches gehört W4).
6. **Nicht mehr benutzte Texte** in `de/slots.json` (`reiter.stundenplan`, `stundenplan.filter.*`, `stundenplan.leer.*`,
   `woche.legende.*`, `woche.kpi.*` außer `label`, `dialog.hinzufuegen.*` u. a.) sind stehen geblieben, damit die
   parallelen PRs W3/W4 nicht an denselben Zeilen kollidieren. Aufräumen nach dem Merge aller drei.
7. **„läuft gerade“ im Tagespanel** kommt aus der Woche (`slots_woche.zellen[].laeuft`), weil `slots_tag` kein `laeuft`
   liefert; für einen Tag außerhalb der angezeigten Woche fehlt das Kennzeichen.
8. **Rückblick** führt in die Live-Sicht der beendeten Session (`/coach/session/:id/live`), wie im Dummy beschrieben;
   eine eigene Rückblick-Ansicht gibt es nicht.
9. **Seitenpanel ohne Fokus-Falle und Scroll-Sperre.** Escape schließt das Panel auch bei offenem „…“-Menü; der
   Hintergrund ist per Tab erreichbar. Nachziehen, wenn ein gemeinsames Panel-Bauteil entsteht (Foundation).
10. **Kein Buchen in einen Slot ohne offenen Raum.** Ohne Raum mit Coach bietet das Panel nur „Raum öffnen“; danach
    steht „+ Kind in …“ am geöffneten Raum (früher ging ein Zusatztermin ohne Raum, der dann „ohne Raum“ stand).
