import { Navigate, Route, Routes } from 'react-router-dom'
import { Login } from '@/pages/Login'
import { TokenSeite } from '@/pages/auth/TokenSeite'
import { PasswortVergessenPage } from '@/pages/auth/PasswortVergessenPage'
import { MeinKontoPage } from '@/pages/konto/MeinKontoPage'
import { DesignShowcase } from '@/pages/DesignShowcase'
import { MockSession } from '@/pages/mock/session/MockSession'
import { StudentDashboard } from '@/pages/student/StudentDashboard'
import { CoachDashboard } from '@/pages/coach/CoachDashboard'
import { MeineEinsaetzePage } from '@/pages/coach/einsaetze/MeineEinsaetzePage'
import { ParentDashboard } from '@/pages/parent/ParentDashboard'
import { ScreeningReportPage as ParentScreeningReportPage } from '@/pages/parent/ScreeningReportPage'
import { HeutePage } from '@/pages/admin/HeutePage'
import { AuthoringItemsPage } from '@/pages/admin/AuthoringItemsPage'
import { ItemBoardPage } from '@/pages/admin/ItemBoardPage'
import { AuthoringEditorPage } from '@/pages/admin/AuthoringEditorPage'
import { AdminPruefansichtPage } from '@/pages/admin/pruefen/AdminPruefansichtPage'
import { ReiheEndePage } from '@/pages/admin/pruefen/ReiheEndePage'
import { ContentHealthPage } from '@/pages/admin/ContentHealthPage'
import { LeadsPage } from '@/pages/admin/LeadsPage'
import { SlotsPage } from '@/pages/admin/slots/SlotsPage'
import { ScheduleUmleitung, TerminUmleitung } from '@/pages/admin/slots/SlotsUmleitung'
import { KindPage as SlotsKindPage } from '@/pages/admin/slots/kind/KindPage'
import { CoachesPage } from '@/pages/admin/CoachesPage'
import { AssignmentsPage } from '@/pages/admin/AssignmentsPage'
import { DiagnosticsPage } from '@/pages/admin/DiagnosticsPage'
import { StellschraubenPage } from '@/pages/admin/stellschrauben/StellschraubenPage'
import { KlassenarbeitenPage } from '@/pages/admin/klassenarbeiten/KlassenarbeitenPage'
import { LsaReportsPage } from '@/pages/admin/lsaReports/LsaReportsPage'
import { QsPage } from '@/pages/admin/QsPage'
import { ReportPage } from '@/pages/admin/ReportPage'
import { BoardPage as AktenBoardPage } from '@/pages/admin/akten/BoardPage'
import { AktePage } from '@/pages/admin/akten/AktePage'
import { VertraegeMenuePage } from '@/pages/admin/VertraegeMenuePage'
import { VertragDetailPage } from '@/pages/admin/VertragDetailPage'
import { VertragPage } from '@/pages/admin/VertragPage'
import { VertragUnterlagenPage } from '@/pages/admin/VertragUnterlagenPage'
import { ReportsPage } from '@/pages/coach/ReportsPage'
import { PruefenUebersichtPage } from '@/pages/coach/pruefen/PruefenUebersichtPage'
import { PruefansichtPage } from '@/pages/coach/pruefen/PruefansichtPage'
import { ErklaerDetailPage } from '@/pages/coach/pruefen/erklaer/ErklaerDetailPage'
import { ErklaerListePage } from '@/pages/coach/pruefen/erklaer/ErklaerListePage'
import { BauformListePage } from '@/pages/coach/pruefen/bauformen/BauformListePage'
import { BauformDetailPage } from '@/pages/coach/pruefen/bauformen/BauformDetailPage'
import { ClusterView } from '@/pages/student/ClusterView'
import { TaskPlayerStillgelegt } from '@/pages/student/TaskPlayerStillgelegt'
import { ProtectedRoute } from '@/components/edvance/ProtectedRoute'
import { COACH_LIVE_ROLLEN, CoachLivePage } from '@/pages/coach/live/CoachLivePage'
import { AdminLayout } from '@/components/edvance/admin/AdminLayout'
import { ThemePanel } from '@/components/edvance/ThemePanel'
import { DiagnosisProvider } from '@/context/DiagnosisContext'
import { ScreeningSession } from '@/pages/ScreeningSession'
import { TaskWidgetDemo } from '@/pages/student/TaskWidgetDemo'
import { DesignDemo } from '@/pages/demo/DesignDemo'
import { GraphDemo } from '@/pages/demo/GraphDemo'
import { V3Showcase } from '@/pages/demo/v3/V3Showcase'

export default function App(): JSX.Element {
  return (
    <DiagnosisProvider>
      <Routes>
        <Route path="/login" element={<Login />} />
        {/* Konto K1: Ziele der Auth-Mails und „Passwort vergessen“. Oeffentlich, der
            Token aus der Mail wird erst nach einem Klick eingeloest. */}
        <Route path="/auth/einladung" element={<TokenSeite art="einladung" />} />
        <Route path="/auth/neues-passwort" element={<TokenSeite art="neuesPasswort" />} />
        <Route path="/auth/bestaetigen" element={<TokenSeite art="bestaetigen" />} />
        <Route path="/auth/passwort-vergessen" element={<PasswortVergessenPage />} />

        <Route
          path="/student"
          element={
            <ProtectedRoute allowedRoles={['student']}>
              <StudentDashboard />
            </ProtectedRoute>
          }
        />
        <Route
          path="/student/cluster/:clusterId"
          element={
            <ProtectedRoute allowedRoles={['student']}>
              <ClusterView />
            </ProtectedRoute>
          }
        />
        <Route
          path="/student/task/:taskId"
          element={
            <ProtectedRoute allowedRoles={['student']}>
              {/* Web-TaskPlayer stillgelegt (Session-Rahmen P1, Entscheidung 24). */}
              <TaskPlayerStillgelegt />
            </ProtectedRoute>
          }
        />
        {/* Coach-Hülle (H6): dieselbe Rollenweiche wie die Admin-Seiten — Admin
            sieht die Admin-Hülle, Coach die Coach-Hülle. Fokus-Seiten ohne Leiste
            (Live-Sicht /coach/session/*) stehen außerhalb jeder Layout-Route;
            AdminLayout lässt sie auch innerhalb ohne Leiste (istFokusSeite). */}
        <Route element={<AdminLayout />}>
          {/* Mein Konto (K1): Admin und Coach, jeweils in der eigenen Hülle. */}
          <Route
            path="/konto"
            element={
              <ProtectedRoute allowedRoles={['admin', 'coach']}>
                <MeinKontoPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/coach"
            element={
              <ProtectedRoute allowedRoles={['coach']}>
                <CoachDashboard />
              </ProtectedRoute>
            }
          />
          {/* Meine Einsätze (Slots SL3): nur Coach; ein Admin plant im Wochenplan. */}
          <Route
            path="/coach/einsaetze"
            element={
              <ProtectedRoute allowedRoles={['coach']} umleitungFuer={{ admin: '/admin/slots' }}>
                <MeineEinsaetzePage />
              </ProtectedRoute>
            }
          />
          {/* Aufgaben pruefen (Lena-Board): admin und coach, jeweils nur mit Pruefrecht. */}
          <Route
            path="/coach/pruefen"
            element={
              <ProtectedRoute allowedRoles={['admin', 'coach']} pruefrecht>
                <PruefenUebersichtPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/coach/pruefen/:taskId"
            element={
              <ProtectedRoute allowedRoles={['admin', 'coach']} pruefrecht>
                <PruefansichtPage />
              </ProtectedRoute>
            }
          />
          {/* Bauformen pruefen (Sessionreihe 1, A5): Lena prueft je Bauform, Admins geben die Reihe frei. */}
          <Route
            path="/coach/pruefen/bauformen"
            element={
              <ProtectedRoute allowedRoles={['admin', 'coach']} pruefrecht>
                <BauformListePage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/coach/pruefen/bauformen/:bauformId"
            element={
              <ProtectedRoute allowedRoles={['admin', 'coach']} pruefrecht>
                <BauformDetailPage />
              </ProtectedRoute>
            }
          />
          {/* Erklaersequenzen pruefen (L6): Lena prueft je Kernidee, ein Admin gibt unter /admin frei. */}
          <Route
            path="/coach/pruefen/erklaerungen"
            element={
              <ProtectedRoute allowedRoles={['admin', 'coach']} pruefrecht>
                <ErklaerListePage modus="lena" />
              </ProtectedRoute>
            }
          />
          <Route
            path="/coach/pruefen/erklaerungen/:kernideeId"
            element={
              <ProtectedRoute allowedRoles={['admin', 'coach']} pruefrecht>
                <ErklaerDetailPage modus="lena" />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/pruefen/erklaerungen"
            element={
              <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach/pruefen/erklaerungen' }}>
                <ErklaerListePage modus="admin" />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/pruefen/erklaerungen/:kernideeId"
            element={
              <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach/pruefen/erklaerungen' }}>
                <ErklaerDetailPage modus="admin" />
              </ProtectedRoute>
            }
          />
        </Route>
        {/* Erstgespräch und Screening-Ergebnisse stillgelegt (H6, keine Daten): alte
            Links landen auf /coach. Die Seiten-Dateien sind Altlast (offene-punkte-h6.md). */}
        <Route path="/coach/intake" element={<Navigate to="/coach" replace />} />
        <Route path="/coach/screening-results" element={<Navigate to="/coach" replace />} />
        {/* Elternreport-Altseite mit eigenem Rahmen, nur Admin, nicht in der Leiste. */}
        <Route
          path="/coach/reports"
          element={
            // Eltern-Reports schreibt nur der Admin (S2b, Entscheidung 26).
            <ProtectedRoute allowedRoles={['admin']}>
              <ReportsPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/parent"
          element={
            <ProtectedRoute allowedRoles={['parent']}>
              <ParentDashboard />
            </ProtectedRoute>
          }
        />
        <Route
          path="/parent/screening"
          element={
            <ProtectedRoute allowedRoles={['parent']}>
              <ParentScreeningReportPage />
            </ProtectedRoute>
          }
        />
        {/* Admin-Hülle (Bauauftrag Admin-Hülle H2): alle Admin-Seiten als Kinder
            einer Layout-Route. AdminLayout gibt nur der Rolle admin die Leiste;
            die Zugriffsprüfung bleibt in der ProtectedRoute jeder Kind-Route. */}
        <Route element={<AdminLayout />}>
          <Route
            path="/admin"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <HeutePage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/leads"
            element={
              // Schuelerakte S1: Coaches lesen leads nicht mehr (coach_rls).
              // Wer die alte Adresse aufruft, landet auf dem Coach-Dashboard.
              <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach' }}>
                <LeadsPage />
              </ProtectedRoute>
            }
          />
          {/* Vertragsprozess — nur Verwaltung (Vertrag & Zahlung). */}
          <Route
            path="/admin/vertraege"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <VertraegeMenuePage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/vertraege/:id/detail"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <VertragDetailPage />
              </ProtectedRoute>
            }
          />
          {/* Slots W2: der Stundenplan ist im Wochenplan aufgegangen; die alte Adresse leitet dorthin (Woche bleibt). */}
          <Route
            path="/admin/schedule"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <ScheduleUmleitung />
              </ProtectedRoute>
            }
          />
          {/* Slots (Bauauftrag Slots, SL2): nur Admins; ein Coach landet auch über die direkte Adresse in
              seinen Einsätzen (Abnahmefall 14). /admin/slot-auswahl (S10) leitet in die Kinder-Liste. */}
          <Route
            path="/admin/slots"
            element={
              <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach/einsaetze' }}>
                <SlotsPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/slots/termin/:datum/:zeitId"
            element={
              <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach/einsaetze' }}>
                {/* Slots W2: die Termin-Seite ist das Slot-Panel im Wochenplan (?slot=…). */}
                <TerminUmleitung />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/slots/kind/:studentId"
            element={
              <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach/einsaetze' }}>
                <SlotsKindPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/slot-auswahl"
            element={
              <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach/einsaetze' }}>
                <Navigate to="/admin/slots?reiter=kinder" replace />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/coaches"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <CoachesPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/assignments"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <AssignmentsPage />
              </ProtectedRoute>
            }
          />
          {/* Eltern-Report zu einer LSA-Sitzung. Coach darf ihn öffnen — er
              führt damit das Elterngespräch. */}
          {/* Menue "Schueler" (Schuelerakte S2): Board und Akte fuer Admin und
              Coach. Welche Akten jemand sieht, entscheidet die Datenbank
              (board_schueler / schuelerakten: Coach nur aktive Akten). */}
          <Route
            path="/admin/akten"
            element={
              <ProtectedRoute allowedRoles={['admin', 'coach']}>
                <AktenBoardPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/akten/:studentId"
            element={
              <ProtectedRoute allowedRoles={['admin', 'coach']}>
                <AktePage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/report/:sessionId"
            element={
              <ProtectedRoute allowedRoles={['admin', 'coach']}>
                <ReportPage />
              </ProtectedRoute>
            }
          />
          {/* Liste aller abgeschlossenen LSAs (LR-1) — nur Verwaltung. */}
          <Route
            path="/admin/lsa-reports"
            element={
              <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach' }}>
                <LsaReportsPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/klassenarbeiten"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <KlassenarbeitenPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/stellschrauben"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <StellschraubenPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/diagnostics"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <DiagnosticsPage />
              </ProtectedRoute>
            }
          />
          {/* Item-Pflege, Expertenliste und Editor: nur admin (Lena-Board). Lena prueft
              unter /coach/pruefen; Coaches landen auf /coach. */}
          <Route
            path="/admin/authoring"
            element={
              <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach' }}>
                <ItemBoardPage />
              </ProtectedRoute>
            }
          />
          {/* Die Filterliste (A05) bleibt als Expertenansicht neben dem Board. */}
          <Route
            path="/admin/authoring/liste"
            element={
              <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach' }}>
                <AuthoringItemsPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/authoring/:id"
            element={
              <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach' }}>
                <AuthoringEditorPage />
              </ProtectedRoute>
            }
          />
          {/* Content-Gesundheit: Mängel-Übersicht des Bestands. Coach sichtet,
              entfernen (Admin-Write) darf laut RLS nur Admin — die Seite schaltet um. */}
          <Route
            path="/admin/content-gesundheit"
            element={
              <ProtectedRoute allowedRoles={['coach', 'admin']}>
                <ContentHealthPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/qs"
            element={
              <ProtectedRoute allowedRoles={['admin']}>
                <QsPage />
              </ProtectedRoute>
            }
          />
        </Route>

        {/* Fokus-Seiten ohne Leiste (Entscheidung 11): Vertrags-Abschluss mit den
            Eltern am iPad, Unterlagen und die Admin-Pruefansicht laufen im Vollbild. */}
        <Route
          path="/admin/vertraege/:id"
          element={
            <ProtectedRoute allowedRoles={['admin']}>
              <VertragPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/vertraege/:id/unterlagen"
          element={
            <ProtectedRoute allowedRoles={['admin']}>
              <VertragUnterlagenPage />
            </ProtectedRoute>
          }
        />
        {/* Coach-Live-Sicht einer Session (Session-Rahmen C1): Fokus-Seite ohne Leiste,
            ausserhalb jeder Layout-Route; Coach und Admin, keine Schuelerkonten. */}
        <Route
          path="/coach/session/:id/live"
          element={
            <ProtectedRoute allowedRoles={COACH_LIVE_ROLLEN}>
              <CoachLivePage />
            </ProtectedRoute>
          }
        />
        {/* Admin-Pruefansicht: eine Aufgabe auf einem Bildschirm, mit Reihe (Fokusseite, nur admin). */}
        <Route
          path="/admin/pruefen/ende"
          element={
            <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach' }}>
              <ReiheEndePage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/pruefen/:taskId"
          element={
            <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach' }}>
              <AdminPruefansichtPage />
            </ProtectedRoute>
          }
        />
        {/* Die Pflege-Strecke ist durch die Admin-Pruefansicht ersetzt: alte Links landen in der Expertenliste. */}
        <Route
          path="/admin/pflege"
          element={
            <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach' }}>
              <Navigate to="/admin/authoring/liste?hinweis=pflege" replace />
            </ProtectedRoute>
          }
        />

        <Route path="/showcase" element={<DesignShowcase />} />
        <Route path="/mock" element={<Navigate to="/mock/session" replace />} />
        <Route path="/mock/session" element={<MockSession />} />
        <Route path="/demo/widgets" element={<TaskWidgetDemo />} />
        <Route path="/demo/design" element={<DesignDemo />} />
        <Route path="/demo/graph" element={<GraphDemo />} />
        <Route path="/demo/v3" element={<V3Showcase />} />

        {/* Screening: stiller, adaptiver, auto-bewerteter Lauf (eingeloggt).
            Coach = Beobachter (kein Rating in diesem Flow). */}
        <Route
          path="/screening"
          element={
            <ProtectedRoute allowedRoles={['student', 'coach', 'admin']}>
              <ScreeningSession />
            </ProtectedRoute>
          }
        />

        <Route path="/" element={<Navigate to="/login" replace />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>

      <ThemePanel />
    </DiagnosisProvider>
  )
}
