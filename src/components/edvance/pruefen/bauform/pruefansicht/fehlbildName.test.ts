// SP-1b N2: Namen typischer Fehler. Alle 50 Schlüssel haben einen kurzen Namen (kein Satz), die Überschreibung je
// Bauform greift nur für NF-5, Platzhalter PAR-4 `wie` ist „Veränderung“.
import { describe, expect, it } from 'vitest'
import i18n from '@/i18n'
import texte from '@/i18n/locales/de/bauformPruefen.json'
import entwurf from '../../../../../../docs/freigabe/sp1/klartext-entwurf.json'
import { fehlbildName } from './fehlbildName'

const t = i18n.getFixedT('de', 'bauformPruefen')
const schluessel = Object.keys((entwurf as { fehlbilder: Record<string, string> }).fehlbilder)

describe('fehlbildName', () => {
  it('alle 50 Schlüssel der Bauformen haben einen kurzen Namen, keinen Satz', () => {
    expect(schluessel).toHaveLength(50)
    for (const k of schluessel) {
      const name = fehlbildName(t, i18n, 'XX-1', k, 'Rückfall-Satz.')
      expect(name, k).not.toBe('Rückfall-Satz.')
      expect(name!.length, k).toBeLessThanOrEqual(60)
      expect(name, k).not.toMatch(/\.$/)
    }
  })

  it('Überschreibung je Bauform greift nur für NF-5', () => {
    expect(fehlbildName(t, i18n, 'NF-5', 'qf_ergaenzung_nicht_abgezogen', null)).toBe('Fehlerzeile richtig, Begründung falsch')
    expect(fehlbildName(t, i18n, 'NF-5', 'qf_ergaenzung_ohne_a', null)).toBe('Fehlerzeile richtig, Begründung falsch')
    expect(fehlbildName(t, i18n, 'NF-2', 'qf_ergaenzung_nicht_abgezogen', null)).toBe('Ergänzung nicht abgezogen')
    expect(fehlbildName(t, i18n, 'NF-3', 'qf_ergaenzung_ohne_a', null)).toBe('Ergänzung ohne Vorfaktor')
    expect(Object.keys((texte as { fehlbildName: Record<string, unknown> }).fehlbildName)).toEqual(['NF-5'])
  })

  it('vorgegebene Namen und Platzhalter PAR-4', () => {
    expect(t('fehlbild.qf_binom_vorzeichen')).toBe('Vorzeichen bei der binomischen Formel falsch')
    expect(t('fehlbild.qf_oeffnung_aus_e')).toBe('Öffnung am Vorzeichen der Zahl hinten abgelesen')
    expect(t('fehlbild.qf_nullprodukt_vorzeichen')).toBe('Nullstellen oder Lösungen mit falschem Vorzeichen')
    expect(t('platzhalter.PAR-4.wie')).toBe('Veränderung')
  })

  it('ohne Namen fällt die Anzeige auf den Satz zurück', () => {
    expect(fehlbildName(t, i18n, 'XX-1', 'qf_gibt_es_nicht', 'Satz aus fehlbild_labels.')).toBe('Satz aus fehlbild_labels.')
  })
})
