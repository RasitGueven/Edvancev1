// Bericht v4: Kontrollwerte Batu (Bauauftrag V4, Anhang B), auf Bericht-Ebene.
//
// Bekannte, gewollte Abweichungen von Anhang B (die Daten gelten, nicht das Muster):
//  - Station 1 heißt „Reelle Zahlen“ (FWG-Plan, schul_themenplan.uv_titel), nicht
//    „Reelle Zahlen und Wurzeln“.
//  - „Potenzen und Potenzgesetze“ (Signal ohne) ist im FWG-Plan Station 4, deshalb
//    ist Pythagoras Station 5 (Anhang B: Klassenarbeit 4) und weitere = 1.
//  - Der erste Lernpfad-Punkt bereitet die Stationen 2 und 3 vor (Anhang B nennt nur 2):
//    „Werte in Terme einsetzen“ betrifft beide.
import { describe, expect, it } from 'vitest'

import { fehlermusterAus } from '@/lib/report/elternbericht/fehlermuster'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { bericht } from '@/lib/report/elternbericht/fixtures/berichtV4Hilfe'
import { zieleV4 } from '@/lib/report/elternbericht/zielbild'

const b = bericht('batuV4')
const data = FAELLE.batuV4.data

describe('Anhang B · batuV4', () => {
  it('Station 1 geschrieben; danach Quadratische Funktionen (nächste), Kreise, Pythagoras mit fehlt', () => {
    const [s1, ...rest] = b.fahrplan!.stationen
    expect(s1).toMatchObject({ titel: 'Reelle Zahlen', stand: 'geschrieben' })
    const mitFehlt = rest.filter((s) => s.signal === 'fehlt')
    expect(mitFehlt.map((s) => s.titel)).toEqual([
      'Quadratische Funktionen',
      'Kreise, Prismen und Zylinder',
      'Der Satz des Pythagoras und Berechnungen in Körpern',
    ])
    expect(rest[0]).toMatchObject({ titel: 'Quadratische Funktionen', stand: 'naechste' })
    expect(rest.filter((s) => s.signal === 'ohne').map((s) => s.titel)).toEqual(['Potenzen und Potenzgesetze'])
  })

  it('Lernpfad: Terme (Ziele 2/3) → Gruppe „Kreise, Prismen und Zylinder“ → Teilweise die Wurzel ziehen → später: Zufall', () => {
    expect(b.lernpfad.map((p) => [p.art, p.titelFeld ?? p.titelThema, p.ziele])).toEqual([
      ['feld', 'terme', [2, 3]],
      ['gruppe', 'Kreise, Prismen und Zylinder', [3]],
      ['luecke', 'Reelle Zahlen und Wurzeln', [5]],
      ['spaeter', null, []],
    ])
    expect(b.lernpfad[2].teile).toEqual(['Teilweise die Wurzel ziehen'])
    expect(b.lernpfad[3].felder).toEqual(['zufall'])
    expect(b.lernpfad[1].teile).toEqual(
      expect.arrayContaining(['Flächeneinheiten', 'Fläche von Dreieck und Parallelogramm']),
    )
  })

  it('vier Ziele; Sorgfalt: 6 von 11 eingeordneten Fehlern', () => {
    const muster = fehlermusterAus(data.fehlbilder)
    expect(muster).toMatchObject({ sorgfalt: true, aufgaben: 11, sorgfaltAufgaben: 6 })
    const uebrig = b.lueckenwegV4!.weitere.flatMap((g) => g.labels)
    const z = zieleV4({ fahrplan: b.fahrplan, muster, name: data.firstName, spaeterLuecken: uebrig.length })
    expect(z.map((x) => x.schluessel)).toEqual([
      'v4.s5.ziele.vorbereitet',
      'v4.s5.ziele.spaeterZwei',
      'v4.s5.ziele.sorgfalt',
      'v4.s5.ziele.weitere',
    ])
    // „Wird später wichtig“
    expect(uebrig).toEqual(
      expect.arrayContaining([
        'Additionsverfahren',
        'Gleichungssysteme grafisch lösen (Schnittpunkt)',
        'Flächeninhalt des Trapezes',
        'Flächeninhalt von Drachen und Raute',
        'Mehrstufige Zufallsexperimente: Summenregel',
      ]),
    )
  })

  it('Seite 3: Station 1 ist die geschriebene Arbeit, Einstieg beginnt mit Klassenarbeit 2', () => {
    expect(b.fahrplan!.stationen[0].stand).toBe('geschrieben')
    expect(b.fahrplan!.stationen[1].nummer).toBe(2)
  })
})
