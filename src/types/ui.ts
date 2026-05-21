import type { AttendanceStatus } from './session'

export type AvatarProps = {
  initials: string
  attendance?: AttendanceStatus
  className?: string
}

export type BadgeVariant =
  | 'active' | 'done' | 'upcoming'
  | 'success' | 'warning' | 'error' | 'info' | 'accent' | 'celebration'

export type BadgeProps = {
  variant: BadgeVariant
  className?: string
  children?: import('react').ReactNode
}

export type SupabaseResult<T> = {
  data: T | null
  error: string | null
}
