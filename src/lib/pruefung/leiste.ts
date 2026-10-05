// Die Entscheidungsleiste der Admin-Pruefansicht (Bauauftrag C 8): je Status hoechstens zwei Knoepfe und
// ein „…“-Menue. Reine Funktion, damit die Matrix ohne Oberflaeche getestet werden kann.
//
// | Status                       | Primaer       | Sekundaer       | „…“                                  |
// | offen, passt, passt·geaendert | ✓ Freigeben   | Zurueck an Lena | Zurueckweisen, Im Editor oeffnen     |
// | rueckfrage                   | ✓ Freigeben   | Zurueck an Lena | Zurueckweisen, Im Editor oeffnen     |
// | beanstandet (Lena oder Team) | Zurueck an Lena | Im Editor oeffnen | Zurueckweisen (nur Lenas „Passt nicht“) |
// | ready                        | —             | Im Editor oeffnen | Freigabe zuruecknehmen              |
// Bei Ausschluss heisst „Zurueck an Lena“ „Auf Offen setzen“; bei draft mit Ausschluss entfaellt der Knopf.

export type LeistenAktion = 'freigeben' | 'anLena' | 'aufOffen' | 'zurueckweisen' | 'editor' | 'freigabeZurueck'

export type LeistenLage = {
  status: string
  /** pruef_ausschluss ist gesetzt: Lena sieht die Aufgabe nicht. */
  ausgeschlossen: boolean
  /** Vom Team beanstandet (pruef_team_beanstandet). */
  team: boolean
}

export type LeistenKnoepfe = {
  primaer: LeistenAktion | null
  sekundaer: LeistenAktion | null
  menue: LeistenAktion[]
}

export function leistenKnoepfe({ status, ausgeschlossen, team }: LeistenLage): LeistenKnoepfe {
  const anLena: LeistenAktion = ausgeschlossen ? 'aufOffen' : 'anLena'
  if (status === 'ready') return { primaer: null, sekundaer: 'editor', menue: ['freigabeZurueck'] }
  if (status === 'beanstandet') {
    return { primaer: anLena, sekundaer: 'editor', menue: team ? [] : ['zurueckweisen'] }
  }
  // offen, passt, passt · geaendert, rueckfrage
  const zurueck = status === 'draft' && ausgeschlossen ? null : anLena
  return { primaer: 'freigeben', sekundaer: zurueck, menue: ['zurueckweisen', 'editor'] }
}

/** Der Schluessel des Infotexts links in der Leiste (pruefenAdmin:leiste.info.*). */
export function leistenInfo(l: LeistenLage & { lenaStatus: string; geaendert: number; befund: string | null }): string {
  if (l.status === 'ready') return 'freigegeben'
  if (l.status === 'beanstandet') return l.ausgeschlossen ? 'beanstandetOffen' : 'beanstandet'
  if (l.befund) return 'befund'
  if (l.status === 'rueckfrage') return 'rueckfrage'
  if (l.status === 'draft') return l.ausgeschlossen ? 'nichtBeiLena' : 'offen'
  return l.geaendert > 0 ? 'geaendert' : 'passt'
}
