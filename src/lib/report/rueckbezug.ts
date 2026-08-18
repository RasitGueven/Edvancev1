// Eltern-Report — der Aufgriff der Eltern-Einschätzung (R4).
//
// Bis R4 nannte Abschnitt 01 wörtlich, was die Eltern angegeben hatten
// („Textverständnis", „Rechenwege", „Konzentration"), und danach kam der Report
// nie darauf zurück. Dabei steht die Antwort im Dokument: In beiden Sitzungen
// vom 16.08. trägt „Gleichungen aufstellen (Sachkontext)". „Ihre Sorge hat sich
// so nicht bestätigt, das Problem liegt woanders" ist die stärkste Aussage, die
// eine Lernstandsanalyse machen kann — und sie fehlte.
//
// ----------------------------------------------------------------------------
// Die Asymmetrie: Skills können entlasten, Fehlbilder nicht
// ----------------------------------------------------------------------------
// Ein Skill-Urteil ist beidseitig belastbar. 'traegt' entsteht, weil das Kind
// Aufgaben zu diesem Skill richtig gelöst hat — ein positiver Beleg.
//
// Eine Fehlbild-Familie ist das NICHT. Ihre Abwesenheit beweist nichts:
//
//   Sitzung 920d00ae — fünf falsche Antworten, null fehlbild_slug.
//   Sitzung d8b0d885 — dieselben Aufgaben, teils mit Slug, teils ohne.
//
// Ein Slug entsteht nur, wenn die GEGEBENE Antwort auf ein katalogisiertes
// Muster passt. Fehlt er, war die Antwort bloß nicht katalogisiert — nicht
// fehlerfrei. Aus „keine Familie über der Schwelle" auf „unauffällig" zu
// schließen hieße, aus fehlender Klassifikation ein Ergebnis zu machen.
//
// Deshalb:
//   skillKeys        -> können bestätigen UND entlasten
//   fehlbildFamilien -> können NUR bestätigen
//
// Ein Thema ohne zugeordnete Skills bekommt also nie einen entlastenden Satz.
// Für „Rechenwege" ist das der Normalfall: Die Skills heißen nach dem
// Verfahren, nicht nach dessen Durchführung.
//
// ----------------------------------------------------------------------------
// A3 bleibt unberührt
// ----------------------------------------------------------------------------
// Die A3-Invariante (S5/S7) verbietet genau einen Pfad: lead_assessments darf
// lsa_start nicht erreichen. Sie ist als Reveal-Metadatum BEIM AUSWERTEN
// ausdrücklich vorgesehen — der Report zeigt weakTopics seit R1 an. Hier wird
// nichts gestellt, nur gelesen, und zwar erst nach Abschluss der Sitzung.

import type {
  AnlassZuordnung,
  Fundament,
  FundamentSkill,
  Rueckbezug,
} from '@/types'
import type { ReportFehlbildFamilie } from '@/lib/reportFehlbilder'

const TRAEGT = 'traegt'

/**
 * Ab so vielen Aufgaben trägt ein entlastender Satz seine volle Fassung.
 *
 * Darunter wird derselbe Befund vorsichtiger formuliert (Fall-Suffix
 * `_schmal`), statt ihn wegzulassen: Die Eltern haben den Bereich genannt, sie
 * bekommen eine Antwort — nur eine, die ihre Grundlage nicht überzeichnet.
 */
export const MIN_BELEGE_ENTLASTUNG = 2

/**
 * Fall-Schlüssel-Stamm je Thema.
 *
 * Getrennt vom Zuordnungs-Datensatz, weil der Schlüssel in report_bausteine
 * steht und ASCII sein muss — `thema` trägt dagegen wörtlich den deutschen
 * Wert aus weak_topics, inklusive Umlaut. Ein Thema ohne Eintrag hier bekommt
 * keinen Rückbezug, selbst wenn eine Zuordnung existiert: dann fehlt der
 * Baustein-Namensraum, und ein Satz ohne Baustein gibt es nicht.
 */
const FALL_STAMM: Record<string, string> = {
  'Textverständnis': 'textverstaendnis',
  'Rechenwege': 'rechenwege',
  'Grundlagen fehlen': 'grundlagen',
  'Konzentration': 'konzentration',
  'Prüfungsangst': 'pruefungsangst',
  'Zeiteinteilung': 'zeiteinteilung',
}

export type RueckbezugInput = {
  /** lead_assessments.weak_topics, wörtlich. */
  weakTopics: readonly string[]
  /** Die Zeilen aus report_anlass_zuordnung. */
  zuordnungen: readonly AnlassZuordnung[]
  /** ALLE direkt geprüften Skills der Sitzung. */
  skills: readonly FundamentSkill[]
  /** Die bereits gebündelten Fehlbild-Familien über der Schwelle. */
  familien: readonly ReportFehlbildFamilie[]
  /** Die Schichtung — trägt den strukturellen Beleg für „Grundlagen fehlen". */
  fundament: Fundament
}

/**
 * Bildet die von den Eltern genannten Bereiche auf prüfbare Belege ab.
 *
 * Ergebnis in der Reihenfolge, in der die Eltern die Bereiche genannt haben —
 * das Gespräch soll ihrer Aufzählung folgen, nicht unserer Sortierung.
 *
 * Seit R5 fällt KEIN genannter Bereich mehr still weg. Jeder bekommt eine der
 * vier Richtungen — auch „dazu sagt diese Analyse nichts". Ein unbeantworteter
 * Punkt in Abschnitt 01 liest sich sonst wie ein stillschweigendes
 * „unauffällig", und genau das ist er nicht.
 *
 * Ohne Zeile in report_anlass_zuordnung (oder ohne Eintrag in FALL_STAMM) bleibt
 * ein Bereich weiterhin außen vor: Dann fehlt der Baustein-Namensraum, und ein
 * Satz ohne abgenommenen Baustein gibt es nicht.
 */
export function baueRueckbezuege(input: RueckbezugInput): Rueckbezug[] {
  const nachThema = new Map(input.zuordnungen.map((z) => [z.thema, z]))
  const familienKeys = new Set(input.familien.map((f) => f.familie))
  const ergebnis: Rueckbezug[] = []

  // Dieselbe Sorge kann mehrfach in weak_topics stehen (das Feld ist ein Array
  // ohne Unique). Zweimal derselbe Satz im Fazit wäre ein Fehler.
  const gesehen = new Set<string>()

  for (const thema of input.weakTopics) {
    const zuordnung = nachThema.get(thema)
    const stamm = FALL_STAMM[thema]
    if (!zuordnung || !stamm || gesehen.has(thema)) continue
    gesehen.add(thema)

    // Was die LSA grundsaetzlich nicht misst, bekommt genau einen Satz: dass
    // sie es nicht misst. Schweigen liest sich wie „unauffaellig".
    if (!zuordnung.messbar) {
      ergebnis.push({
        thema,
        fall: `${stamm}_nicht_messbar`,
        richtung: 'nicht_messbar',
        belege: 0,
      })
      continue
    }

    const rb = zuordnung.strukturell
      ? strukturell(stamm, input.fundament)
      : ueberBelege(stamm, zuordnung, input.skills, familienKeys)

    // Messbar, aber diese Sitzung gibt nichts her — in KEINE Richtung. Auch das
    // ist eine Antwort, und zwar die einzige ehrliche.
    ergebnis.push(
      rb
        ? { thema, ...rb }
        : { thema, fall: `${stamm}_offen`, richtung: 'offen', belege: 0 },
    )
  }

  return ergebnis
}

type Teil = Omit<Rueckbezug, 'thema'>

/**
 * „Grundlagen fehlen" — belegt an der Form des Fundaments, nicht an Skills.
 *
 * Drei Fälle, und der mittlere ist der interessante: Die Lücken liegen typisch
 * NICHT ganz unten. Bei beiden Sitzungen vom 16.08. trägt die unterste geprüfte
 * Ebene vollständig, der Einbruch sitzt in der Mitte. „Es fehlen Grundlagen"
 * stimmt dann — aber nicht so, wie Eltern es meinen, und der Report sagt das.
 */
function strukturell(stamm: string, f: Fundament): Teil | null {
  // Nichts unterhalb des Einstiegs geprüft: über die Grundlagen ist nichts
  // bekannt, in keine Richtung.
  if (!f.fundamentGeprueft) return null

  const darunter = f.ebenen.slice(1)
  const luecken = darunter.reduce((n, e) => n + (e.geprueft - e.traegt), 0)
  const geprueft = darunter.reduce((n, e) => n + e.geprueft, 0)

  if (luecken === 0) {
    // Wie bei den Skills: Entlastung auf einem einzigen geprüften Bereich ist
    // keine. Derselbe Befund, vorsichtiger formuliert.
    return {
      fall:
        geprueft >= MIN_BELEGE_ENTLASTUNG
          ? `${stamm}_entlastend`
          : `${stamm}_entlastend_schmal`,
      richtung: 'entlastend',
      belege: geprueft,
    }
  }
  return {
    fall: f.bodenTraegt
      ? `${stamm}_bestaetigend_mitte`
      : `${stamm}_bestaetigend_durchgehend`,
    richtung: 'bestaetigend',
    belege: geprueft,
  }
}

/**
 * Themen mit Skill- und/oder Familienzuordnung.
 *
 * Reihenfolge der Prüfung ist bewusst: Erst ein bestätigender Befund, dann die
 * Entlastung. Wer einen Beleg für das Problem hat, bekommt ihn zu sehen — auch
 * wenn daneben ein Skill trägt.
 */
function ueberBelege(
  stamm: string,
  z: AnlassZuordnung,
  skills: readonly FundamentSkill[],
  familienKeys: ReadonlySet<string>,
): Teil | null {
  const zugeordnet = skills.filter((s) => z.skillKeys.includes(s.skillKey))
  const nichtTragend = zugeordnet.filter((s) => s.zustand !== TRAEGT)
  const tragend = zugeordnet.filter((s) => s.zustand === TRAEGT)
  const familienTreffer = z.fehlbildFamilien.filter((f) => familienKeys.has(f))

  if (nichtTragend.length > 0 || familienTreffer.length > 0) {
    return {
      fall: `${stamm}_bestaetigend`,
      richtung: 'bestaetigend',
      belege: nichtTragend.length + familienTreffer.length,
    }
  }

  // Entlastung braucht positive Evidenz. Eine leere Familienliste ist keine.
  if (tragend.length > 0) {
    const belege = tragend.reduce((n, s) => n + s.proben, 0)
    return {
      // Ein Freispruch auf EINER Aufgabe ist keiner. Gegen die echten Sitzungen
      // ist das der Regelfall, nicht die Ausnahme: gleichung_modellieren — der
      // einzige Skill mit Sachkontext — wurde in beiden Sitzungen vom 16.08.
      // mit genau einer Aufgabe geprüft (einem MULTI_PART-Item mit zwei
      // Teilaufgaben, das ist EINE Aufgabe).
      //
      // Der Satz entfällt deshalb nicht — der Rückbezug ist der Punkt der
      // Übung —, aber er wechselt in eine Fassung, die den schmalen Ausschnitt
      // selbst benennt und auf die Nachprüfung durch den Coach verweist.
      fall:
        belege >= MIN_BELEGE_ENTLASTUNG
          ? `${stamm}_entlastend`
          : `${stamm}_entlastend_schmal`,
      richtung: 'entlastend',
      belege,
    }
  }

  return null
}
