// Zentrale TypeScript-Typen für das gesamte Edvance-Projekt.
// Alle Props-Interfaces, Domain-Types und Enums leben hier als Re-Exports.

export type { UserRole, Role, ProtectedRouteProps } from './auth'

export { THEMES } from './theme'
export type { Theme, ThemeColors } from './theme'

export type {
  AvatarProps,
  BadgeVariant,
  BadgeProps,
  SupabaseResult,
} from './ui'

export type {
  SchoolType,
  OnboardingFormData,
  StepProps,
  SummaryStepProps,
  CoachStepProps,
  StepIndicatorProps,
  TierStepProps,
  OnboardingData,
} from './onboarding'

export type {
  Coach,
  SchoolKind,
  LeadStatus,
  LeadGoal,
  Lead,
  LeadInput,
  Student,
  StudentInput,
  StudentWithName,
  IntakeStatus,
  IntakeSession,
  IntakeInput,
  TierPlan,
  TierInput,
  SubscriptionStatus,
  StudentSubscription,
  StudentCoach,
} from './domain'

export type {
  AttendanceStatus,
  SessionStatus,
  CoachingSession,
  SessionStudent,
  Intervention,
  StudentTaskProgress,
  StudentProgress,
  XpRule,
  XpEvent,
  ParentReportStatus,
  ParentReport,
  ParentReportInput,
  ParentReportDraft,
} from './session'

export type {
  ContentType,
  CognitiveType,
  InputType,
  Subject,
  SkillCluster,
  Microskill,
  TaskAsset,
  Task,
  DiagnosticTaskInput,
  RunTask,
  DiagnosticTask,
  DiagnosticTest,
  TaskCoachMetadata,
} from './content'

export type {
  ScreeningStatus,
  ScreeningTest,
  ScreeningTestInput,
  ScreeningRating,
  ScreeningLevel,
  ScreeningAfb,
  ScreeningPhase,
  ScreeningInputType,
  ScreeningCheckType,
  ScreeningItem,
  ScreeningTeilaufgabe,
  ScreeningItemInput,
  ScreeningItemResult,
  ScreeningItemResultInput,
  ScreeningItemRating,
  ScreeningItemRatingInput,
} from './screening'
