import {
  BookOpenCheck,
  CalendarClock,
  Clapperboard,
  ClipboardCheck,
  FileText,
  FolderOpen,
  Inbox,
  PenLine,
  ScrollText,
  SlidersHorizontal,
  Sun,
  Users,
} from 'lucide-react'
import type { NavKonfiguration } from '@/components/edvance/shell/navTypes'

/** Leiste der Admin-Hülle (Bauauftrag Admin-Hülle, H2 Punkt 1). Schlüssel im Namespace admin. */
export const ADMIN_NAV: NavKonfiguration = {
  namespace: 'admin',
  rolleKey: 'nav.rolle',
  gruppen: [
    {
      id: 'start',
      eintraege: [{ id: 'heute', route: '/admin', nameKey: 'nav.heute', kurzKey: 'nav.kurz.heute', icon: Sun }],
    },
    {
      id: 'vertrieb',
      titelKey: 'nav.gruppe.vertrieb',
      eintraege: [
        { id: 'leads', route: '/admin/leads', nameKey: 'nav.leads', kurzKey: 'nav.kurz.leads', icon: Inbox, zaehler: 'leads' },
      ],
    },
    {
      id: 'betrieb',
      titelKey: 'nav.gruppe.betrieb',
      eintraege: [
        {
          id: 'slots',
          route: '/admin/slots',
          // Einzel-Sessions: Reiter Stundenplan der Slots; /admin/schedule leitet dorthin um (S2).
          aktivBei: ['/admin/slots*', '/admin/schedule', '/admin/slot-auswahl'],
          nameKey: 'nav.slots',
          kurzKey: 'nav.kurz.slots',
          icon: CalendarClock,
          zaehler: 'slots',
        },
        { id: 'schueler', route: '/admin/akten', aktivBei: ['/admin/akten*'], nameKey: 'nav.schueler', kurzKey: 'nav.kurz.schueler', icon: FolderOpen },
        {
          id: 'coaches',
          route: '/admin/coaches',
          aktivBei: ['/admin/coaches', '/admin/assignments'],
          nameKey: 'nav.coaches',
          kurzKey: 'nav.kurz.coaches',
          icon: Users,
        },
      ],
    },
    {
      id: 'verwaltung',
      titelKey: 'nav.gruppe.verwaltung',
      eintraege: [
        {
          id: 'vertraege',
          route: '/admin/vertraege',
          aktivBei: ['/admin/vertraege*'],
          nameKey: 'nav.vertraege',
          kurzKey: 'nav.kurz.vertraege',
          icon: ScrollText,
          zaehler: 'vertraege',
        },
        {
          id: 'stellschrauben',
          route: '/admin/stellschrauben',
          nameKey: 'nav.stellschrauben',
          kurzKey: 'nav.kurz.stellschrauben',
          icon: SlidersHorizontal,
        },
        { id: 'elternReports', nameKey: 'nav.elternReports', kurzKey: 'nav.kurz.elternReports', icon: FileText, bald: true },
        {
          id: 'lsaReports',
          route: '/admin/lsa-reports',
          // Ein geöffneter Report gehört zur Liste, nicht zur Item-Pflege (LR-1).
          aktivBei: ['/admin/lsa-reports', '/admin/report/*'],
          nameKey: 'nav.lsaReports',
          kurzKey: 'nav.kurz.lsaReports',
          icon: ClipboardCheck,
        },
        // L5: abgeleitete Mathearbeiten je Schule und Klasse (bestätigen, korrigieren).
        {
          id: 'klassenarbeiten',
          route: '/admin/klassenarbeiten',
          nameKey: 'nav.klassenarbeiten',
          kurzKey: 'nav.kurz.klassenarbeiten',
          icon: BookOpenCheck,
        },
      ],
    },
    {
      id: 'inhalte',
      titelKey: 'nav.gruppe.inhalte',
      eintraege: [
        {
          id: 'itemPflege',
          route: '/admin/authoring',
          aktivBei: [
            '/admin/authoring*',
            '/admin/content-gesundheit',
            '/admin/qs',
            '/admin/diagnostics',
            '/admin/pruefen/erklaerungen*',
          ],
          nameKey: 'nav.itemPflege',
          kurzKey: 'nav.kurz.itemPflege',
          icon: PenLine,
          zaehler: 'itemPflege',
        },
        // Reihe 1, Bauauftrag B: Erklärvideos.
        { id: 'studio', route: '/admin/studio', nameKey: 'nav.studio', kurzKey: 'nav.kurz.studio', icon: Clapperboard },
      ],
    },
  ],
}
