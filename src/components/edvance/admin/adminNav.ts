import {
  BookOpenCheck,
  CalendarClock,
  CalendarRange,
  Clapperboard,
  ClipboardCheck,
  FileText,
  FolderOpen,
  Gauge,
  Inbox,
  Library,
  PenLine,
  ScrollText,
  SlidersHorizontal,
  Sun,
  Users,
  UsersRound,
} from 'lucide-react'
import type { NavKonfiguration } from '@/components/edvance/shell/navTypes'

/**
 * Leiste der Admin-Hülle (Bauauftrag Admin-Hülle H2, Bereiche nach CI-1 Teil B):
 * Heute · Kinder · Inhalte · Planung, Stellschrauben im Fuß. Routen, aktivBei
 * und Zähler sind unverändert. Schlüssel im Namespace admin.
 */
export const ADMIN_NAV: NavKonfiguration = {
  namespace: 'admin',
  rolleKey: 'nav.rolle',
  horizont: true,
  gruppen: [
    {
      id: 'heute',
      eintraege: [{ id: 'heute', route: '/admin', nameKey: 'nav.heute', kurzKey: 'nav.kurz.heute', icon: Sun }],
    },
    {
      id: 'kinder',
      titelKey: 'nav.gruppe.kinder',
      icon: UsersRound,
      eintraege: [
        { id: 'leads', route: '/admin/leads', nameKey: 'nav.leads', kurzKey: 'nav.kurz.leads', icon: Inbox, zaehler: 'leads' },
        { id: 'schueler', route: '/admin/akten', aktivBei: ['/admin/akten*'], nameKey: 'nav.schueler', kurzKey: 'nav.kurz.schueler', icon: FolderOpen },
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
          id: 'lsaReports',
          route: '/admin/lsa-reports',
          // Ein geöffneter Report gehört zur Liste, nicht zur Item-Pflege (LR-1).
          aktivBei: ['/admin/lsa-reports', '/admin/report/*'],
          nameKey: 'nav.lsaReports',
          kurzKey: 'nav.kurz.lsaReports',
          icon: ClipboardCheck,
        },
        { id: 'elternReports', nameKey: 'nav.elternReports', kurzKey: 'nav.kurz.elternReports', icon: FileText, bald: true },
      ],
    },
    {
      id: 'inhalte',
      titelKey: 'nav.gruppe.inhalte',
      icon: Library,
      eintraege: [
        {
          id: 'itemPflege',
          route: '/admin/authoring',
          // Ohne eigenen Menüpunkt, nur über die Adresse oder Links erreichbar (ci1-bestand.md 4b).
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
        // FR-2: Ampel je Schule und Klassenarbeit, Fokus-Schulen, Sammelfreigabe.
        { id: 'lsaAbdeckung', route: '/admin/lsa-abdeckung', nameKey: 'nav.lsaAbdeckung', kurzKey: 'nav.kurz.lsaAbdeckung', icon: Gauge },
        // L5: abgeleitete Mathearbeiten je Schule und Klasse (bestätigen, korrigieren).
        {
          id: 'klassenarbeiten',
          route: '/admin/klassenarbeiten',
          nameKey: 'nav.klassenarbeiten',
          kurzKey: 'nav.kurz.klassenarbeiten',
          icon: BookOpenCheck,
        },
        // Reihe 1, Bauauftrag B: Erklärvideos.
        { id: 'studio', route: '/admin/studio', nameKey: 'nav.studio', kurzKey: 'nav.kurz.studio', icon: Clapperboard },
      ],
    },
    {
      id: 'planung',
      titelKey: 'nav.gruppe.planung',
      icon: CalendarRange,
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
  ],
  fuss: [
    {
      id: 'stellschrauben',
      route: '/admin/stellschrauben',
      nameKey: 'nav.stellschrauben',
      kurzKey: 'nav.kurz.stellschrauben',
      icon: SlidersHorizontal,
    },
  ],
}
