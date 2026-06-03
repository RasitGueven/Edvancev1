import { Navigate, Route, Routes } from 'react-router-dom'
import { Login } from '@/pages/Login'
import { DesignShowcase } from '@/pages/DesignShowcase'
import { MockIndex } from '@/pages/mock/MockIndex'
import { MockScreeningCoach } from '@/pages/mock/MockScreeningCoach'
import { MockDndWidgets } from '@/pages/mock/MockDndWidgets'
import { MockTaskWidgets } from '@/pages/mock/MockTaskWidgets'
import { MockScreeningParent } from '@/pages/mock/MockScreeningParent'
import { MockFirstSession } from '@/pages/mock/MockFirstSession'
import { MockLernpfad } from '@/pages/mock/MockLernpfad'
import { StudentDashboard } from '@/pages/student/StudentDashboard'
import { CoachDashboard } from '@/pages/coach/CoachDashboard'
import { ParentDashboard } from '@/pages/parent/ParentDashboard'
import { ScreeningReportPage as ParentScreeningReportPage } from '@/pages/parent/ScreeningReportPage'
import { AdminDashboard } from '@/pages/admin/AdminDashboard'
import { OnboardingPage } from '@/pages/admin/OnboardingPage'
import { LambacherPreview } from '@/pages/admin/LambacherPreview'
import { LeadsPage } from '@/pages/admin/LeadsPage'
import { SchedulePage } from '@/pages/admin/SchedulePage'
import { CoachesPage } from '@/pages/admin/CoachesPage'
import { AssignmentsPage } from '@/pages/admin/AssignmentsPage'
import { XpRulesPage } from '@/pages/admin/XpRulesPage'
import { TiersPage } from '@/pages/admin/TiersPage'
import { DiagnosticsPage } from '@/pages/admin/DiagnosticsPage'
import { ScreeningItemsPage } from '@/pages/admin/ScreeningItemsPage'
import { ScreeningItemEditorPage } from '@/pages/admin/ScreeningItemEditorPage'
import { ScreeningCoveragePage } from '@/pages/admin/ScreeningCoveragePage'
import { IntakePage } from '@/pages/coach/IntakePage'
import { ScreeningResultsPage } from '@/pages/coach/ScreeningResultsPage'
import { ReportsPage } from '@/pages/coach/ReportsPage'
import { ClusterView } from '@/pages/student/ClusterView'
import { TaskPlayer } from '@/pages/student/TaskPlayer'
import { ProtectedRoute } from '@/components/edvance/ProtectedRoute'
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
              <TaskPlayer />
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
        <Route
          path="/coach/intake"
          element={
            <ProtectedRoute allowedRoles={['coach', 'admin']}>
              <IntakePage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/coach/screening-results"
          element={
            <ProtectedRoute allowedRoles={['coach', 'admin']}>
              <ScreeningResultsPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/coach/reports"
          element={
            <ProtectedRoute allowedRoles={['coach', 'admin']}>
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
        <Route
          path="/admin"
          element={
            <ProtectedRoute allowedRoles={['admin']}>
              <AdminDashboard />
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/onboarding"
          element={
            <ProtectedRoute allowedRoles={['admin']}>
              <OnboardingPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/lambacher-preview"
          element={
            <ProtectedRoute allowedRoles={['admin']}>
              <LambacherPreview />
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/leads"
          element={
            <ProtectedRoute allowedRoles={['admin', 'coach']}>
              <LeadsPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/schedule"
          element={
            <ProtectedRoute allowedRoles={['admin']}>
              <SchedulePage />
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
        <Route
          path="/admin/xp-rules"
          element={
            <ProtectedRoute allowedRoles={['admin']}>
              <XpRulesPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/tiers"
          element={
            <ProtectedRoute allowedRoles={['admin']}>
              <TiersPage />
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
        <Route
          path="/admin/screening-items"
          element={
            <ProtectedRoute allowedRoles={['admin']}>
              <ScreeningItemsPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/screening-items/:id/edit"
          element={
            <ProtectedRoute allowedRoles={['admin']}>
              <ScreeningItemEditorPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/screening-items/new"
          element={
            <ProtectedRoute allowedRoles={['admin']}>
              <ScreeningItemEditorPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/screening-coverage"
          element={
            <ProtectedRoute allowedRoles={['admin']}>
              <ScreeningCoveragePage />
            </ProtectedRoute>
          }
        />

        <Route path="/showcase" element={<DesignShowcase />} />
        <Route path="/mock" element={<MockIndex />} />
        <Route path="/mock/screening-coach" element={<MockScreeningCoach />} />
        <Route path="/mock/screening-parent" element={<MockScreeningParent />} />
        <Route path="/mock/first-session" element={<MockFirstSession />} />
        <Route path="/mock/lernpfad" element={<MockLernpfad />} />
        <Route path="/mock/dnd-widgets" element={<MockDndWidgets />} />
        <Route path="/mock/task-widgets" element={<MockTaskWidgets />} />
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
