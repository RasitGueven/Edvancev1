// Eltern-Report — „Wie wir gesucht haben" nach Stufen statt nach Ebenen (W2-7).
//
// Reine Rechnung, keine Datenbank. Lesepfad: src/lib/supabase/
// lsaReportErzaehlung.ts; Entwurfs-Generator: scripts/report/. Beide rufen
// diese Funktionen, damit App, Druck und Entwurf dieselbe Gliederung zeigen.
//
// ----------------------------------------------------------------------------
// Warum nicht mehr nach fundament_tiefe
// ----------------------------------------------------------------------------
// Die Ebenen-Gliederung stellte alles mit kleinerer Tiefe „unter" das Thema. In
// der Sitzung 143215f5 standen so Volumeneinheiten und Brüche unter
// „Gleichungen aufstellen", obwohl das Thema nicht auf ihnen aufbaut — und der
// Text sprach vom Abstieg bis zu sicherem Boden. Eltern lesen das als Ursache.
//
// Jetzt behauptet nur noch Block 2 einen Zusammenhang, und Block 2 enthält
// ausschließlich Skills im Voraussetzungsabschluss der Einstiegsknoten.

import { INHALTSBEREICHE, STUFEN_ABSTEIGEND, inhaltsbereich, stufeAusKlasse } from '@/lib/report/inhaltsbereiche'
import type {
  SucheEintrag,
  SucheSkill,
  SucheStufe,
  SucheZeile,
  Suchweg,
  Themenraum,
} from '@/types'

/** Nur dieser Zustand ist „sicher". Alles andere ist „noch nicht sicher". */
const SICHER = 'traegt'

export type SucheEingabe = {
  /** NUR direkt geprüfte Skills (belegt_direkt), wie bei baueFundament. */
  skills: readonly SucheSkill[]
  themaLabel: string | null
  /**
   * Der Themenraum der Sitzung (src/lib/report/themenraum.ts) — gespeichert
   * oder, bei alten Sitzungen, berechnet. null bei Sitzungen ohne Thema.
   */
  raum: Themenraum | null
}

/**
 * Beruht das Urteil auf einer einzigen Aufgabe ohne eindeutigen Treffer?
 *
 * Eindeutig ist nur Probe 1 'voll' bei einer offenen Aufgabe: dann bucht
 * lsa_urteil_buchen_core 'traegt' mit offen = false. Alles andere mit einer
 * Probe ist provisorisch — die Zweitprobe stand noch aus.
 */
export function nurEineAufgabe(s: SucheSkill): boolean {
  return s.proben <= 1 && !(s.zustand === SICHER && !s.offen)
}

const eintrag = (s: SucheSkill): SucheEintrag => ({
  label: s.label,
  sicher: s.zustand === SICHER,
  nurEineAufgabe: nurEineAufgabe(s),
})

// Sicher zuerst, dann nach Label — so steht die Gegenüberstellung in der Zeile
// in derselben Reihenfolge wie im Satz darüber.
const nachZustand = (a: SucheEintrag, b: SucheEintrag) =>
  Number(b.sicher) - Number(a.sicher) || a.label.localeCompare(b.label, 'de')

function zeile(bereich: string | null, skills: readonly SucheSkill[]): SucheZeile {
  const eintraege = skills.map(eintrag).sort(nachZustand)
  return {
    bereich,
    geprueft: eintraege.length,
    sicher: eintraege.filter((e) => e.sicher).length,
    eintraege,
  }
}

/** Nach Stufe (höchste zuerst), innerhalb der Stufe nach Inhaltsbereich. */
function nachStufe(skills: readonly SucheSkill[]): SucheStufe[] {
  return STUFEN_ABSTEIGEND.flatMap((stufe) => {
    const drauf = skills.filter((s) => stufeAusKlasse(s.klasseHerkunft) === stufe)
    if (drauf.length === 0) return []
    const zeilen = INHALTSBEREICHE.flatMap((b) => {
      const imBereich = drauf.filter((s) => inhaltsbereich(s.skillKey) === b)
      return imBereich.length > 0 ? [zeile(b, imBereich)] : []
    })
    return [{ stufe, zeilen }]
  })
}

/** Gibt null zurück, wenn nichts direkt geprüft wurde — dann entfällt der Abschnitt. */
export function baueSuche(e: SucheEingabe): Suchweg | null {
  if (e.skills.length === 0) return null

  const themaLabel = e.raum ? e.themaLabel?.trim() || null : null
  const einstieg = new Set(e.raum?.einstieg ?? [])
  const aktuell = e.skills.filter((s) => einstieg.has(s.skillKey))

  // Ohne geprüften Einstieg gibt es keinen Abstiegsweg, auf dem etwas
  // „darunter" liegen könnte: alles steht unter „Angesehen".
  if (!e.raum || aktuell.length === 0) {
    return {
      fall: e.raum ? 'thema_ungeprueft' : 'ohne_thema',
      themaLabel,
      aktuell: null,
      grundlagen: [],
      angesehen: nachStufe(e.skills),
      grundlageSicher: false,
      geprueft: e.skills.length,
    }
  }

  // Block 2 nur aus dem Themenraum — gespeichert, nicht aus den heutigen
  // Kanten, damit ein alter Report sich nicht verschiebt (W5-d).
  const unten = new Set(e.raum.darunter)
  const grundlagen = e.skills.filter((s) => !einstieg.has(s.skillKey) && unten.has(s.skillKey))
  const rest = e.skills.filter((s) => !einstieg.has(s.skillKey) && !unten.has(s.skillKey))

  return {
    fall: 'thema',
    themaLabel,
    aktuell: zeile(null, aktuell),
    grundlagen: nachStufe(grundlagen),
    angesehen: nachStufe(rest),
    grundlageSicher: grundlagen.some((s) => s.zustand === SICHER),
    geprueft: e.skills.length,
  }
}

// ----------------------------------------------------------------------------
// Der Erzähltext über den Zeilen
// ----------------------------------------------------------------------------

/** Die Übersetzungsfunktion, wie i18next sie liefert (Namespace 'report'). */
export type Uebersetzer = (key: string, werte?: Record<string, unknown>) => string

/** Höchstens so viele Labels in einem Satz, danach „und n weitere". */
export const MAX_SATZ_LABELS = 3

function liste(labels: readonly string[], t: Uebersetzer, sprache: string): string {
  const fmt = new Intl.ListFormat(sprache, { style: 'long', type: 'conjunction' })
  if (labels.length <= MAX_SATZ_LABELS) return fmt.format(labels)
  return t('suche.liste.weitere', {
    liste: labels.slice(0, MAX_SATZ_LABELS).join(', '),
    count: labels.length - MAX_SATZ_LABELS,
  })
}

const alle = (stufen: readonly SucheStufe[]) =>
  stufen.flatMap((s) => s.zeilen.flatMap((z) => z.eintraege))

/**
 * Die Sätze über den Zeilen, gebaut aus Block 1 und 2.
 *
 * Block 3 kommt im Text nicht vor: er ist kein Teil der Suche nach dem Thema.
 * „Sicherer Boden" nur, wenn das Thema offen war UND unter ihm, auf dem
 * Abstiegsweg, wirklich ein sicherer Skill liegt.
 */
export function sucheSaetze(s: Suchweg, t: Uebersetzer, sprache: string): string[] {
  const thema = s.themaLabel ?? t('suche.themaOhneName')
  if (s.fall === 'ohne_thema') {
    return [t('suche.satz.ohneThema'), t('suche.satz.uebersicht', { count: s.geprueft })]
  }
  if (s.fall === 'thema_ungeprueft' || !s.aktuell) {
    return [t('suche.satz.themaUngeprueft', { thema }), t('suche.satz.uebersicht', { count: s.geprueft })]
  }

  const saetze: string[] = []
  const a = s.aktuell.eintraege
  const aSicher = a.filter((x) => x.sicher).map((x) => x.label)
  const aOffen = a.filter((x) => !x.sicher).map((x) => x.label)
  if (aOffen.length === 0) {
    saetze.push(t('suche.satz.themaSicher', { thema, sicher: liste(aSicher, t, sprache) }))
  } else if (aSicher.length === 0) {
    saetze.push(t('suche.satz.themaOffen', { thema, offen: liste(aOffen, t, sprache) }))
  } else {
    saetze.push(
      t('suche.satz.themaGemischt', {
        thema,
        sicher: liste(aSicher, t, sprache),
        offen: liste(aOffen, t, sprache),
      }),
    )
  }

  const g = alle(s.grundlagen)
  const gSicher = g.filter((x) => x.sicher).map((x) => x.label)
  const gOffen = g.filter((x) => !x.sicher).map((x) => x.label)
  if (g.length === 0) {
    saetze.push(t('suche.satz.grundlagenNichtGeprueft'))
  } else if (gSicher.length === 0) {
    saetze.push(t('suche.satz.grundlagenOffen', { offen: liste(gOffen, t, sprache) }))
  } else {
    const boden = aOffen.length > 0 && s.grundlageSicher
    saetze.push(
      t(boden ? 'suche.satz.grundlagenBoden' : 'suche.satz.grundlagenAuch', {
        sicher: liste(gSicher, t, sprache),
      }),
    )
    if (gOffen.length > 0) {
      saetze.push(t('suche.satz.grundlagenRest', { offen: liste(gOffen, t, sprache) }))
    }
  }
  return saetze
}
