import type { ReactNode } from 'react'

export type UserRole = 'student' | 'parent' | 'coach' | 'admin'
export type Role = UserRole | null

export type ProtectedRouteProps = {
  allowedRoles: UserRole[]
  children: ReactNode
  // Nicht zugelassene Rollen, die statt "Kein Zugriff" umgeleitet werden —
  // etwa ein Coach, der eine frueher fuer ihn offene Adresse aufruft.
  umleitungFuer?: Partial<Record<UserRole, string>>
  // Zusaetzlich zum Rollen-Check das Pruefrecht verlangen (darf_pruefen(): admin oder coach mit
  // profiles.darf_pruefen). Ohne Recht geht es zurueck auf /coach, mit Hinweis (Lena-Board).
  pruefrecht?: boolean
}
