import type { ReactNode } from 'react'

export type UserRole = 'student' | 'parent' | 'coach' | 'admin'
export type Role = UserRole | null

export type ProtectedRouteProps = {
  allowedRoles: UserRole[]
  children: ReactNode
}
