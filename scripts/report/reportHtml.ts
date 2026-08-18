// Eltern-Report — Aufbau des HTML-Entwurfs (R4).
//
// Der Entwurf, den Eltern im Pilotgespräch in die Hand bekommen. Er nutzt
// dieselben Funktionen wie die App (src/lib/report/*), damit Entwurf und
// Produkt nicht auseinanderlaufen: Diese Datei ordnet nur an, sie rechnet
// nicht und formuliert nicht.
//
// ----------------------------------------------------------------------------
// Ein Diagramm, nicht zwei
// ----------------------------------------------------------------------------
// VARIANTE B (Balken nach Tiefe) bleibt entfallen. Sie zeigte exakt die Zahlen
// der Ebenenspur in Abschnitt 02 — dieselben Daten, zweimal auf einer Seite.
// Von beiden ist die Spur die tragfaehigere: Sie laesst sich beschriften, und
// seit R4 steht unter jeder Zeile, welche Bereiche auf dieser Ebene liegen.
//
// VARIANTE A (Profil ueber die Themenfamilien) ist mit R5 zurueck, in
// Abschnitt 03. Sie ordnet nach THEMA, die Spur nach TIEFE — zwei Achsen,
// dieselben Urteile, keine Dopplung. Und sie ist das Bild, auf das der Coach im
// Gespraech zeigt; sechs Zeilen Text sind praezise, aber man zeigt nicht darauf.
//
// Warum sie in R4 kurzzeitig entfallen war und was sich geaendert hat, steht im
// Kopf von radar.ts: feste Achsenmenge fuer alle Reports, ausgewiesene
// Grundgesamtheit, und "nicht geprueft" wird nie wie "nichts gekonnt"
// gezeichnet.

import {
  alsWort,
  Bausteinsatz,
  ebeneAlsZeile,
  ebeneImSatz,
  ebenenUntertitel,
} from '@/lib/report/bausteine'
import type { FamilienBefund } from '@/lib/report/familien'
import { sucheFall } from '@/lib/report/fundament'
import type { ReportFehlbildFamilie } from '@/lib/reportFehlbilder'
import type { Fundament, ReportAnsprechpartner, Rueckbezug } from '@/types'
import { radarNenner, radarSvg } from './radar'
import { REPORT_CSS } from './reportCss'

export type ReportEingabe = {
  sessionId: string
  vorname: string
  klasse: number
  fach: string
  datum: string
  aufgaben: number
  fundament: Fundament
  familien: ReportFehlbildFamilie[]
  /** Die sechs Achsen des Profils — immer alle sechs, auch die ungeprüften. */
  profil: FamilienBefund[]
  rueckbezuege: Rueckbezug[]
  ansprechpartner: ReportAnsprechpartner
  /** Abschnitt 01 — fertig formulierter Satz aus belegten Lead-Feldern. */
  anlass: string
  /**
   * Der Fall für Fazit und Empfehlung: wie viele Themenfamilien betroffen sind.
   *
   * Die Texte selbst kommen aus report_bausteine — bis R5 standen sie im
   * Generator und behaupteten eine Verteilung, die niemand gezählt hatte.
   */
  verteilung: string
  paket: string
  frequenz: string
}

export const esc = (v: unknown): string =>
  String(v).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

/** Die Ebenenspur: eine Zeile je geprüfter Ebene, mit dem, was dort liegt. */
function ebenenspur(f: Fundament): string {
  return f.ebenen
    .map((e) => {
      const pOk = Math.round((e.traegt / e.geprueft) * 100)
      const track =
        pOk === 100
          ? '<span class="ok" style="width:100%"></span>'
          : pOk === 0
            ? '<span class="no" style="width:100%"></span>'
            : `<span class="ok" style="width:${pOk}%"></span><span class="no" style="width:${100 - pOk}%"></span>`
      const was = ebenenUntertitel(e.labels, e.weitere)
      return `        <div class="layer">
          <div class="row">
            <span class="lv">${esc(ebeneAlsZeile(e.delta))}</span>
            <span class="track">${track}</span>
            <span class="cnt">${e.traegt} von ${e.geprueft}</span>
          </div>
          ${was ? `<p class="was">${esc(was)}</p>` : ''}
        </div>`
    })
    .join('\n')
}

/**
 * Der Aufklappbereich: Lücken nach Ebenen gruppiert, tiefste zuerst.
 *
 * Bis R4 war die Liste flach. Sie WAR bereits von unten nach oben sortiert —
 * nur sah man das nicht, weil nichts die Ebenen markierte. Die Gruppierung
 * macht die Reihenfolge sichtbar, statt sie zu behaupten.
 *
 * Die Zeile „In den übrigen N geprüften Bereichen…" ist hier ersatzlos
 * entfallen: Dieselbe Zahl steht schon in Abschnitt 03 unter „Das trägt".
 * Zweimal dieselbe Aussage liest sich wie zwei verschiedene.
 */
function aufklapp(f: Fundament): string {
  const tiefen = [...new Set(f.luecken.map((l) => l.fundamentTiefe))].sort((a, b) => a - b)
  return tiefen
    .map((t) => {
      const drauf = f.luecken.filter((l) => l.fundamentTiefe === t)
      return `        <div class="stufe">
          <p class="lv">${esc(ebeneAlsZeile(f.einstiegTiefe - t))}</p>
          <ul>
${drauf.map((l) => `            <li>${esc(l.label)}</li>`).join('\n')}
          </ul>
        </div>`
    })
    .join('\n')
}

function rueckbezugBlock(rb: Rueckbezug[], satz: Bausteinsatz, sessionId: string): string {
  const zeilen = rb
    .map((r) => {
      const text = satz.waehle('rueckbezug', r.fall, `${sessionId} ${r.thema}`, {
        belege: r.belege,
      })
      if (!text) return null
      // Drei Markierungen fuer vier Richtungen. „offen" und „nicht messbar"
      // teilen sich die neutrale: Beide sagen, dass diese Analyse nichts
      // hergibt. Ein goldenes Ausrufezeichen daneben laese sich als Befund —
      // und genau das sind sie nicht.
      const marke =
        r.richtung === 'entlastend'
          ? { klasse: 'ok', zeichen: '✓' }
          : r.richtung === 'bestaetigend'
            ? { klasse: 'hit', zeichen: '!' }
            : { klasse: 'off', zeichen: '?' }
      const { klasse, zeichen } = marke
      return `        <div class="rb">
          <span class="mark ${klasse}" aria-hidden="true">${zeichen}</span>
          <p>${esc(text)}</p>
        </div>`
    })
    .filter((x): x is string => x !== null)

  if (zeilen.length === 0) return ''
  return `      <div class="rueck">
${zeilen.join('\n')}
      </div>`
}

export function baueReport(e: ReportEingabe, satz: Bausteinsatz): string {
  const f = e.fundament
  const streuung = e.sessionId

  const sucheText = satz.waehle('suche', sucheFall(f), streuung, {
    geprueft: f.geprueft,
    ebenen: alsWort(f.ebenen.length),
  })
  const einbruchText = f.einbruch
    ? satz.waehle('abstieg_einbruch', 'standard', streuung, {
        ebene: ebeneImSatz(f.einbruch.delta),
        traegt: f.einbruch.traegt,
        geprueft: f.einbruch.geprueft,
      })
    : null
  // Nur sagen, wenn die unterste Ebene wirklich trägt UND es überhaupt einen
  // Abstieg gab — sonst wäre es eine Aussage über das aktuelle Thema.
  const bodenText =
    f.bodenTraegt && f.fundamentGeprueft
      ? satz.waehle('abstieg_boden', 'vollstaendig', streuung)
      : null
  const traegtText = satz.waehle('befund_traegt', 'standard', streuung, {
    traegt: f.traegt,
    geprueft: f.geprueft,
  })
  const fazitText = satz.waehle('fazit', e.verteilung, streuung)
  const empfehlungText = satz.waehle('empfehlung', e.verteilung, streuung)

  const musterAbschnitt =
    e.familien.length > 0
      ? `
  <!-- 4 MUSTER -->
  <section>
    <div class="step"><span class="step-n">04</span><h3>Wie es sich zeigt</h3></div>
    <p class="sub">Diese Denkschritte sind mehrfach gleich verlaufen — nicht einmalig, sondern als Muster.</p>
    <ul class="muster">
${e.familien.map((m) => `      <li>${esc(m.elterntext)}</li>`).join('\n')}
    </ul>
  </section>
`
      : `
  <!-- Muster entfällt: keine Fehlbild-Familie über der Schwelle -->
`
  const nrFazit = e.familien.length > 0 ? '05' : '04'

  const kontakt =
    e.ansprechpartner.name || e.ansprechpartner.email
      ? `  <p class="kontakt">
    Diese Analyse hat <b>${esc(e.ansprechpartner.name ?? 'das Edvance-Team')}</b> begleitet.
    Fragen dazu beantworten wir gern${
      e.ansprechpartner.email
        ? ` — schreiben Sie an <a href="mailto:${esc(e.ansprechpartner.email)}">${esc(e.ansprechpartner.email)}</a>`
        : ''
    }.
  </p>`
      : ''

  return `<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Eltern-Report · ${esc(e.vorname)}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Schibsted+Grotesk:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>${REPORT_CSS}</style>
</head>
<body>
<div class="wrap">

<div class="note">
<b>Entwurf zur Abstimmung (v3).</b> Alle Zahlen, Listen und Erzählbausteine stammen aus der
echten Sitzung <code>${esc(e.sessionId)}</code> vom ${esc(e.datum)}. Die Sätze kommen aus
<code>report_bausteine</code> und tragen dort eine Abnahme-Schranke — was nicht abgenommen ist,
erscheint hier gar nicht.
</div>

<div class="sheet">

  <header>
    <p class="eyebrow">Lernstandsanalyse · ${esc(e.datum)}</p>
    <h1>Was wir bei ${esc(e.vorname)} gesehen haben</h1>
    <div class="meta">
      <span>Klasse <b>${esc(e.klasse)}</b></span>
      <span>Fach <b>${esc(e.fach)}</b></span>
      <span>Umfang <b>${e.aufgaben} Aufgaben</b></span>
    </div>
  </header>

  <!-- 1 ANLASS -->
  <section>
    <div class="step"><span class="step-n">01</span><h3>Warum wir geschaut haben</h3></div>
    <p class="lead-copy">
${e.anlass}
    </p>
  </section>

  <!-- 2 SUCHE -->
  <section>
    <div class="step"><span class="step-n">02</span><h3>Wie wir gesucht haben</h3></div>
    <div class="descent">
${sucheText ? `      <p class="lead-copy">${esc(sucheText)}</p>` : ''}
      <div class="layers">
${ebenenspur(f)}
      </div>
${
  einbruchText || bodenText
    ? `      <div class="descent-note">
${einbruchText ? `        <p>${esc(einbruchText)}</p>` : ''}
${bodenText ? `        <p>${esc(bodenText)}</p>` : ''}
      </div>`
    : ''
}
    </div>
  </section>

  <!-- 3 BEFUND -->
  <section>
    <div class="step"><span class="step-n">03</span><h3>Was wir gefunden haben</h3></div>
    <p class="sub">Zuerst das, was trägt — darauf lässt sich aufbauen.</p>

    <div class="profil">
${radarSvg(e.profil)}
      <div>
        <h4>Profil über die Themenfamilien</h4>
        <p class="cap">Immer dieselben sechs Familien, damit zwei Analysen vergleichbar
        bleiben. Beide Flächen zählen gegen <b>alle</b> Bereiche der Familie — nicht nur
        gegen die geprüften.</p>
        <ul class="legende">
          <li><span class="l-aussen" aria-hidden="true"></span>
            <b>geprüft</b> — wie viel der Familie diese Analyse angesehen hat</li>
          <li><span class="l-innen" aria-hidden="true"></span>
            <b>trägt</b> — wie viel der Familie nachweislich trägt</li>
        </ul>
        <p class="cap">Liegen beide Linien dicht beieinander, trägt das Geprüfte. Klafft
        die innere weit nach innen, wurde gründlich geprüft und es trägt wenig. Bleiben
        beide klein, wurde hier kaum geprüft — das ist keine Aussage über Ihr Kind.</p>
        <p class="nenner">${esc(radarNenner(e.profil))}</p>
      </div>
    </div>

    <div class="two">
      <div class="box good">
        <h4>Das trägt</h4>
        <ul>
${f.tragend.map((x) => `          <li>${esc(x.label)}</li>`).join('\n')}
        </ul>
${traegtText ? `        <p class="tiefe">${esc(traegtText)}</p>` : ''}
      </div>
      <div class="box bad">
        <h4>Das trägt noch nicht</h4>
        <ul>
${[...f.luecken].reverse().map((x) => `          <li>${esc(x.label)}</li>`).join('\n')}
        </ul>
${
  // Nur behaupten, wenn es stimmt: Liegt eine Lücke AUF der Einstiegsebene,
  // ist sie nicht „unter dem aktuellen Thema", sondern Teil davon.
  f.luecken.every((l) => l.fundamentTiefe < f.einstiegTiefe)
    ? `        <p class="tiefe">Diese Bereiche liegen <b>unter</b> dem aktuellen Thema — sie
        werden dort vorausgesetzt.</p>`
    : ''
}
      </div>
    </div>
  </section>
${musterAbschnitt}
  <!-- DETAILS -->
  <section>
    <details class="deep">
      <summary>Was wir uns in den ersten Sitzungen genauer ansehen</summary>
      <div class="body">
        <p>Die Analyse ist eine Momentaufnahme aus wenigen Aufgaben. Der Coach prüft sie im
        Unterricht nach — von unten nach oben, weil das Obere auf dem Unteren aufbaut:</p>
${aufklapp(f)}
      </div>
    </details>
  </section>

  <!-- FAZIT + EMPFEHLUNG -->
  <section>
    <div class="step"><span class="step-n">${nrFazit}</span><h3>So geht es weiter</h3></div>
    <div class="close">
${fazitText ? `      <p>${esc(fazitText)}</p>` : ''}
      <p style="margin-top:12px;font-size:15px;color:rgba(255,255,255,.72)">
        Das ist der Stand nach dieser Analyse und bezieht sich auf die nächsten ein bis zwei
        Sitzungen — der Coach prüft ihn dort nach.
      </p>
${rueckbezugBlock(e.rueckbezuege, satz, e.sessionId)}

      <div class="paket">
        <div>
          <div class="name">${esc(e.paket)}</div>
          <div class="freq">${esc(e.frequenz)}</div>
        </div>
        <div class="why">
${empfehlungText ? `          ${esc(empfehlungText)}` : ''}
          <div class="off">Ein anderes Paket schließt nichts aus — es verändert, wie schnell
          wir vorankommen.</div>
        </div>
      </div>
    </div>
  </section>

${kontakt}

</div>

</div>
</body>
</html>
`
}
