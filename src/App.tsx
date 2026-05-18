import { Navigate, Route, Routes } from 'react-router-dom'
import { Login } from '@/pages/Login'
import { DesignShowcase } from '@/pages/DesignShowcase'
import { StudentDashboard } from '@/pages/student/StudentDashboard'
import { CoachDashboard } from '@/pages/coach/CoachDashboard'
import { ParentDashboard } from '@/pages/parent/ParentDashboard'
import { AdminDashboard } from '@/pages/admin/AdminDashboard'
import { OnboardingPage } from '@/pages/admin/OnboardingPage'
import { LambacherPreview } from '@/pages/admin/LambacherPreview'
import { LeadsPage } from '@/pages/admin/LeadsPage'
import { TiersPage } from '@/pages/admin/TiersPage'
import { DiagnosticsPage } from '@/pages/admin/DiagnosticsPage'
import { ScreeningItemsPage } from '@/pages/admin/ScreeningItemsPage'
import { IntakePage } from '@/pages/coach/IntakePage'
import { ScreeningResultsPage } from '@/pages/coach/ScreeningResultsPage'
import { ClusterView } from '@/pages/student/ClusterView'
import { TaskPlayer } from '@/pages/student/TaskPlayer'
import { ProtectedRoute } from '@/components/edvance/ProtectedRoute'
import { ThemePanel } from '@/components/edvance/ThemePanel'
import { DiagnosisProvider } from '@/context/DiagnosisContext'
import { DiagnosisSession } from '@/pages/DiagnosisSession'
import { DiagnosisResult } from '@/pages/DiagnosisResult'
import { ScreeningSession } from '@/pages/ScreeningSession'
import { TaskWidgetDemo } from '@/pages/student/TaskWidgetDemo'
import { DesignDemo } from '@/pages/demo/DesignDemo'

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
          path="/parent"
          element={
            <ProtectedRoute allowedRoles={['parent']}>
              <ParentDashboard />
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

        <Route path="/showcase" element={<DesignShowcase />} />
        <Route path="/demo/widgets" element={<TaskWidgetDemo />} />
        <Route path="/demo/design" element={<DesignDemo />} />

        {/* Diagnose-Engine (lokal, ohne Login – Tablet-Sicht).
            Coach erreicht den Coach-View über ?view=coach. */}
        <Route path="/diagnosis" element={<DiagnosisSession />} />
        <Route path="/diagnosis/result" element={<DiagnosisResult />} />

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
        <Route
          path="/screening/result"
          element={
            <ProtectedRoute allowedRoles={['student', 'coach', 'admin']}>
              <DiagnosisResult />
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
