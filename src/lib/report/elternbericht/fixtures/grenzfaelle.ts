// Grenzfälle für den Druck des Eltern-Berichts R7 (R7-5): langes Fazit, lange
// Namen, neunte Profilzeile, viele Anliegen, Lernziel ohne Schwerpunkt. Nur von
// Tests und der Vorschau importiert. Aus Ilkays Analyse abgeleitet wie
// synthetisch.ts; die Sitzungs-IDs sind so gewählt, dass die Bausteine mit
// zwei Fassungen die längere ziehen (Bausteinsatz.waehle streut über die ID).

import { KATALOG } from '@/lib/report/elternbericht/fixtures/katalog'
import { datenAus, u, type SitzungRoh } from '@/lib/report/elternbericht/fixtures/basis'
import { ILKAY_ROH, ILKAY_URTEILE } from '@/lib/report/elternbericht/fixtures/ilkay'
import type { ReportData, ReportFehlbild } from '@/types'

const fall = (id: string, aenderung: Partial<SitzungRoh>): ReportData =>
  datenAus({ ...ILKAY_ROH, sessionId: `00000000-0000-4000-8000-0000000000${id}`, ...aenderung })

const fehlbild = (
  slug: string,
  familie: string,
  familieElterntext: string,
  anzahl: number,
  skills: string[],
): ReportFehlbild => ({
  slug,
  familie,
  familieElterntext,
  anzahl,
  aufgaben: 2,
  skills,
  skillUebergreifend: false,
  einstufung: 'befund',
})

// Die drei längsten abgenommenen Elterntexte, wörtlich aus fehlbild_familien
// (dbread, freigegeben_am is not null, Stand 20.10.2026: 221, 208, 194 Zeichen).
// Die Vorkommen ordnen sie in dieser Reihenfolge (Sortierung nach anzahl).
const POTENZEN = fehlbild(
  'basis_exponent_vertauscht',
  'potenzen_wurzeln',
  'Ihr Kind rechnet bei Hochzahlen und Wurzeln nach einer Regel, die dort nicht gilt, etwa 3² als 3 · 2 oder √36 als die Hälfte von 36, oder ordnet eine Zahl falsch ein, etwa √49 als Zahl, die sich nicht genau angeben lässt.',
  4,
  ['potenzen'],
)
const GERADEN = fehlbild(
  'm_b_vertauscht',
  'geraden_schaubilder',
  'Ihr Kind arbeitet mit Geraden und Schaubildern, verwechselt dabei aber, welche Zahl wofür steht, etwa den Wert nach rechts mit dem nach oben, oder erkennt nicht richtig, ob und wo sich zwei Geraden schneiden.',
  3,
  ['fkt_linear_yabschnitt'],
)
const SACHAUFGABEN = fehlbild(
  'falsche_groesse_beantwortet',
  'sachaufgaben',
  'Ihr Kind rechnet sauber, beantwortet aber nicht genau die gestellte Frage: Es wählt einen Rechenweg, der nicht zur beschriebenen Situation passt, oder gibt eine andere Größe an als die gesuchte.',
  2,
  ['gleichung_modellieren'],
)

const nach = new Map(ILKAY_URTEILE.map((s) => [s.skillKey, s]))

/** Wie ilkay, dazu die zwei längsten Elterntexte: Fazit mit beiden und dem Coach-Satz. */
export const mitFazit = fall('13', { fehlbilder: [POTENZEN, GERADEN] })

/**
 * Drei Familien mit den drei längsten Elterntexten, vier Schwerpunkte und
 * „Danach …“ (wie sechsFelderMitUebung), dazu ein langes Lernziel
 * (NOTIZEN_LANG): Hier greifen die Stufen der Verdichtung auf Seite 4.
 */
export const fazitLang = fall('15', {
  urteile: [
    'bruch_kuerzen',
    'bruch_add',
    'prozent_grundwert',
    'term_ausklammern',
    'geo_umfang',
    'groessen_flaechen',
    'vorzeichen_vorrang',
  ].map((k) => nach.get(k)!),
  fehlbilder: [POTENZEN, GERADEN, SACHAUFGABEN],
})

/** Rufname mit genau 24 Zeichen: die längste Fassung mit Namen. */
export const LANGER_NAME = 'Anna-Katharina Henriette'
/** 25 Zeichen: der Bogen nimmt die Fassungen ohne Namen. */
export const ZU_LANGER_NAME = 'Anna-Katharina Friederike'

// Anliegen außerhalb von report_anlass_zuordnung bekommen keinen Rückbezug
// (rueckbezug.ts). Mit den Werten des Intake-Formulars gibt es das heute nicht;
// hier stehen sie für mehrere Anliegen bei nur einem Rückbezug.
const ANLIEGEN = ['Konzentration', 'Hausaufgaben', 'Motivation']

/** Langer Name, acht Profilzeilen (wie ilkay), drei Anliegen, ein Rückbezug. */
export const langerName = fall('17', { firstName: LANGER_NAME, weakTopics: ANLIEGEN })

export const zuLangerName = fall('19', { firstName: ZU_LANGER_NAME, weakTopics: ANLIEGEN })

/**
 * Ein untersuchter Skill ohne Themenfeld (Schlüssel synthetisch, in Prod ist
 * heute jeder Skill zugeordnet): neunte Profilzeile „Weitere Bereiche“.
 */
const OHNE_FELD = u('daten_diagramme', 'Diagramme lesen und auswerten', 3, 6, 'traegt_nicht', 2, false)
export const weitereBereiche = fall('20', {
  urteile: [...ILKAY_URTEILE, OHNE_FELD],
  katalog: [...KATALOG, { skillKey: OHNE_FELD.skillKey, klasse: 6 }],
})

/**
 * Vier Anliegen, das nächste Thema und drei lange Rückbezüge (die längsten
 * Bausteine: textverstaendnis_entlastend_schmal, rechenwege_offen,
 * grundlagen_entlastend_schmal, je Fassung a). Ein tragender Bereich unter dem
 * Thema macht „Grundlagen“ entlastend schmal.
 */
export const vieleAnliegen = fall('14', {
  weakTopics: ['Textverständnis', 'Rechenwege', 'Grundlagen fehlen', 'Hausaufgaben'],
  urteile: [
    ...ILKAY_URTEILE,
    u('vorzeichen_add_sub', 'Negative Zahlen addieren/subtrahieren', 1, 7, 'traegt', 1, false),
  ],
})

/** Nichts mit Übungsbedarf, Lernziel gesetzt: das Lernziel steht ohne Kurve. */
export const keinSchwerpunktMitZiel = fall('22', {
  urteile: ILKAY_URTEILE.map((s) => ({ ...s, zustand: 'traegt' })),
})
