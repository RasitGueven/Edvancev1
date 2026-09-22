import { describe, expect, it } from 'vitest'
import { inhaltsfeldVorschlag, istDirektSetzbar } from './einordnung'

describe('inhaltsfeldVorschlag', () => {
  it('leitet das Inhaltsfeld aus dem Cluster ab', () => {
    expect(inhaltsfeldVorschlag('Geometrie & Messen')).toBe('geometrie')
    expect(inhaltsfeldVorschlag('Daten & Zufall')).toBe('stochastik')
  })

  it('schlaegt ohne oder bei unbekanntem Cluster nichts vor', () => {
    expect(inhaltsfeldVorschlag(null)).toBeNull()
    expect(inhaltsfeldVorschlag('Unbekannt')).toBeNull()
  })
})

describe('istDirektSetzbar', () => {
  it('kennt die vier Felder aus Schritt 4', () => {
    expect(istDirektSetzbar('clusterMissing')).toBe(true)
    expect(istDirektSetzbar('stoffankerMissing')).toBe(true)
  })

  it('schickt alles andere in den Editor', () => {
    expect(istDirektSetzbar('solutionMissing')).toBe(false)
    expect(istDirektSetzbar('assetAltMissing')).toBe(false)
  })
})
