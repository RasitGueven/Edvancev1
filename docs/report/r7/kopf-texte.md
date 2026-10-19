# Kopfsätze des Eltern-Berichts R7 — Abnahmeliste

Stand 19.10.2026. Betrifft `report_bausteine`, Slot `kopf` (Überschrift auf Seite 1 des Druckbogens).
Migration `supabase/migrations/20261019080220_r7_kopf_entwuerfe.sql`, Grundlage Bauauftrag R7
(Entscheidung 8, Anhang B).

## Was die Sätze tun

Die Überschrift fasst die Analyse in einem Satz zusammen. Welcher Fall gilt, rechnet `kopfFall`
(`src/lib/report/elternbericht/bereiche.ts`) aus den direkt geprüften Bereichen:

| Fall | gilt, wenn |
|---|---|
| `gemischt` | es gibt sichere Bereiche **und** Bereiche mit Übungsbedarf |
| `sicher` | kein Bereich mit Übungsbedarf |
| `uebung` | kein sicherer Bereich |

Je Fall gibt es zwei Varianten (a/b); der Bericht wählt eine fest je Sitzung, wie bei allen
Bausteinen.

**Platzhalter:** nur `{name}`. Der Bogen setzt den Rufnamen ein, ohne Namen „Ihr Kind". Jeder Satz
ist so gebaut, dass beides passt, und keiner nutzt ein „es", das man auf das Kind beziehen könnte.
Die Sätze sagen bewusst nicht „weiterführende Rechenschritte" wie das Muster E7: Ob der
Übungsbedarf über den Grundlagen liegt, hängt vom Kind ab.

**Bis zur Abnahme** liefert der Lesepfad die Zeilen nicht aus (`freigegeben_am` ist NULL). Auf
Seite 1 steht dann die Ersatzüberschrift „Was wir bei {Name} gesehen haben"
(`elternbericht:s1.kopfErsatz`).

## Die sechs Sätze

| schluessel | Fall | Satz | mit Namen | ohne Namen |
|---|---|---|---|---|
| `kopf.gemischt.a` | gemischt | {name} zeigt sichere Ansätze. Bei einigen Rechenschritten ist noch Übung nötig. | Ilkay zeigt sichere Ansätze. … | Ihr Kind zeigt sichere Ansätze. … |
| `kopf.gemischt.b` | gemischt | {name} löst vieles schon sicher. An einigen Stellen ist noch Übung nötig. | Ilkay löst vieles … | Ihr Kind löst vieles … |
| `kopf.sicher.a` | sicher | {name} war in den untersuchten Bereichen sicher. | Ilkay war … | Ihr Kind war … |
| `kopf.sicher.b` | sicher | In allen untersuchten Bereichen war {name} sicher. | … war Ilkay sicher. | … war Ihr Kind sicher. |
| `kopf.uebung.a` | uebung | In den untersuchten Bereichen braucht {name} noch Übung. | … braucht Ilkay noch Übung. | … braucht Ihr Kind noch Übung. |
| `kopf.uebung.b` | uebung | {name} braucht in den untersuchten Bereichen noch Übung. Genau dort setzen wir an. | Ilkay braucht … | Ihr Kind braucht … |

Geprüft in `src/test/invariants/inv4-elternbericht.test.ts`: Sie-Form bzw. kein Du, keine Note,
kein „gemeistert", kein „trägt", kein Prozentwert, keine Klassenangabe, kein roher Schlüssel, nur der
Platzhalter `{name}`.

## Abnahme (Lena)

Je Fall, nach dem Muster aus dem Spaltenkommentar von `report_bausteine.entwurf`. Die Zeilen sind
neu, ihr Entwurf steht in `text`; `coalesce(entwurf, text)` lässt ihn stehen.

```sql
update report_bausteine
   set text = coalesce(entwurf, text), entwurf = null,
       freigegeben_am = now(), freigegeben_von = '<profil-uuid>'
 where slot = 'kopf' and fall = '<fall>'
   and (entwurf is not null or freigegeben_am is null);
```

`<fall>` ist `gemischt`, `sicher` oder `uebung`. Soll ein Satz vorher geändert werden: `text` der
Zeile ändern (solange `freigegeben_am` NULL ist, ist das der Entwurf), dann abnehmen.

| Fall | abgenommen am | von |
|---|---|---|
| gemischt | | |
| sicher | | |
| uebung | | |
