// Eltern-Report — Abschnitt 02 im HTML-Entwurf (W2-7).
//
// Dieselbe Gliederung wie ReportSuche in der App: aktuelles Thema, Grundlagen
// darunter, außerdem angesehen — nach Stufe und Inhaltsbereich. Rechnung und
// Sätze kommen aus src/lib/report/suche.ts, die Texte aus derselben
// report.json wie in der App. Eigene Datei, damit reportHtml.ts unter der
// 400-Zeilen-Grenze bleibt.

import i18next from 'i18next'

import deReport from '@/i18n/locales/de/report.json'
import { sucheSaetze } from '@/lib/report/suche'
import type { SucheStufe, SucheZeile, Suchweg } from '@/types'

const i18n = i18next.createInstance()
void i18n.init({
  lng: 'de',
  ns: ['report'],
  defaultNS: 'report',
  resources: { de: { report: deReport } },
  interpolation: { escapeValue: false },
  initAsync: false,
})
const t = (key: string, werte?: Record<string, unknown>): string => i18n.t(key, werte)

const esc = (v: unknown): string =>
  String(v).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

function zeile(z: SucheZeile, name: string): string {
  const skills = z.eintraege
    .map((e) => {
      const zustand = t(e.sicher ? 'suche.zustand.sicher' : 'suche.zustand.offen')
      const duenn = e.nurEineAufgabe ? ` <i>(${esc(t('suche.nurEineAufgabe'))})</i>` : ''
      return `<li${e.sicher ? ' class="ok"' : ''}>${esc(e.label)} · ${esc(zustand)}${duenn}</li>`
    })
    .join('')
  return `        <div class="layer">
          <div class="row"><b>${esc(name)}</b><span class="cnt">${esc(
            t('suche.zaehlung', { sicher: z.sicher, geprueft: z.geprueft }),
          )}</span></div>
          <ul class="was">${skills}</ul>
        </div>`
}

function stufen(liste: readonly SucheStufe[]): string {
  return liste
    .map(
      (s) => `      <p class="lv">${esc(t(`suche.stufe.${s.stufe}`))}</p>
${s.zeilen.map((z) => zeile(z, t(`suche.bereich.${z.bereich}`))).join('\n')}`,
    )
    .join('\n')
}

function block(kopf: string, hinweis: string | null, inhalt: string): string {
  return `      <div class="layers">
      <p class="block">${esc(kopf)}</p>
${hinweis ? `      <p class="hint">${esc(hinweis)}</p>` : ''}
${inhalt}
      </div>`
}

/** Der Inhalt von Abschnitt 02 — Erzähltext und die drei Blöcke. */
export function sucheAbschnitt(s: Suchweg): string {
  const mitThema = s.fall === 'thema'
  const teile = [`      <p class="lead-copy">${esc(sucheSaetze(s, t, 'de').join(' '))}</p>`]
  if (s.aktuell) {
    teile.push(
      block(t('suche.block.aktuell'), null, zeile(s.aktuell, s.themaLabel ?? t('suche.block.aktuell'))),
    )
  }
  if (s.grundlagen.length > 0) {
    teile.push(
      block(t('suche.block.grundlagen'), t('suche.block.grundlagenHinweis'), stufen(s.grundlagen)),
    )
  }
  if (s.angesehen.length > 0) {
    teile.push(
      block(
        t(mitThema ? 'suche.block.ausserdem' : 'suche.block.angesehen'),
        mitThema ? t('suche.block.ausserdemHinweis') : null,
        stufen(s.angesehen),
      ),
    )
  }
  return teile.join('\n')
}
