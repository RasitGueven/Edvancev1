import { CalendarDays, ClipboardCheck, FolderOpen, HeartPulse, Sun } from 'lucide-react'
import type { NavKonfiguration } from '@/components/edvance/shell/navTypes'

/**
 * Leiste der Coach-Hülle (Coach-Sicht H6). Schlüssel im Namespace coach.
 * „Einsätze“ (Slots SL3) zeigt die eigenen Raum-Termine der Woche.
 * „Aufgaben prüfen“ nur mit Prüfrecht (darf_pruefen). Erstgespräch und
 * Screening-Ergebnisse fehlen bewusst: intake_sessions und screening_tests
 * sind leer (offene-punkte-h6.md). /coach/reports ist nur Admin.
 */
export function coachNav(darfPruefen: boolean): NavKonfiguration {
  return {
    namespace: 'coach',
    rolleKey: 'nav.rolle',
    gruppen: [
      {
        id: 'start',
        eintraege: [
          { id: 'heute', route: '/coach', nameKey: 'nav.heute', kurzKey: 'nav.kurz.heute', icon: Sun, zaehler: 'heute' },
        ],
      },
      {
        id: 'arbeit',
        titelKey: 'nav.gruppe.arbeit',
        eintraege: [
          {
            id: 'einsaetze',
            route: '/coach/einsaetze',
            aktivBei: ['/coach/einsaetze*'],
            nameKey: 'nav.einsaetze',
            kurzKey: 'nav.kurz.einsaetze',
            icon: CalendarDays,
          },
          {
            id: 'schueler',
            route: '/admin/akten',
            aktivBei: ['/admin/akten*', '/admin/report/*'],
            nameKey: 'nav.schueler',
            kurzKey: 'nav.kurz.schueler',
            icon: FolderOpen,
          },
          ...(darfPruefen
            ? [
                {
                  id: 'pruefen',
                  route: '/coach/pruefen',
                  aktivBei: ['/coach/pruefen*'],
                  nameKey: 'nav.pruefen',
                  kurzKey: 'nav.kurz.pruefen',
                  icon: ClipboardCheck,
                  zaehler: 'pruefen',
                },
              ]
            : []),
          {
            id: 'contentGesundheit',
            route: '/admin/content-gesundheit',
            nameKey: 'nav.contentGesundheit',
            kurzKey: 'nav.kurz.contentGesundheit',
            icon: HeartPulse,
          },
        ],
      },
    ],
  }
}

/**
 * Fokus-Seiten ohne Leiste (wie Entscheidung 11): die Live-Sicht einer Session
 * am iPad. Gilt für Admin und Coach, egal in welcher Layout-Route die Route
 * hängt. Das Druckbild des Eltern-Reports braucht keinen Eintrag: die Leiste
 * trägt print-hide.
 */
const FOKUS_PRAEFIXE = ['/coach/session/']

export function istFokusSeite(pfad: string): boolean {
  return FOKUS_PRAEFIXE.some((p) => pfad.startsWith(p))
}
