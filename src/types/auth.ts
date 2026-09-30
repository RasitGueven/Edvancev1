import type { ReactNode } from 'react'

export type UserRole = 'student' | 'parent' | 'coach' | 'admin'
export type Role = UserRole | null

export type ProtectedRouteProps = {
  allowedRoles: UserRole[]
  children: ReactNode
  // Nicht zugelassene Rollen, die statt "Kein Zugriff" umgeleitet werden —
  // etwa ein Coach, der eine frueher fuer ihn offene Adresse aufruft.
  umleitungFuer?: Partial<Record<UserRole, string>>
}
