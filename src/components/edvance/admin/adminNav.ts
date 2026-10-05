import {
  CalendarClock,
  ClipboardCheck,
  FileText,
  FolderOpen,
  Inbox,
  PenLine,
  ScrollText,
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
          id: 'stundenplan',
          route: '/admin/schedule',
          aktivBei: ['/admin/schedule', '/admin/slots', '/admin/slot-auswahl'],
          nameKey: 'nav.stundenplan',
          kurzKey: 'nav.kurz.stundenplan',
          icon: CalendarClock,
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
        { id: 'elternReports', nameKey: 'nav.elternReports', kurzKey: 'nav.kurz.elternReports', icon: FileText, bald: true },
        { id: 'lsaErgebnisse', nameKey: 'nav.lsaErgebnisse', kurzKey: 'nav.kurz.lsaErgebnisse', icon: ClipboardCheck, bald: true },
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
            '/admin/pflege',
            '/admin/content-gesundheit',
            '/admin/qs',
            '/admin/diagnostics',
            '/admin/report/*',
          ],
          nameKey: 'nav.itemPflege',
          kurzKey: 'nav.kurz.itemPflege',
          icon: PenLine,
          zaehler: 'itemPflege',
        },
      ],
    },
  ],
}
