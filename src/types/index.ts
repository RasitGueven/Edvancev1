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
  AnswerOption,
  AnswerPayload,
  CanonicalInputType,
  StudentAnswer,
  MCAnswerPayload,
  NumericAnswerPayload,
  ShortTextAnswerPayload,
  TrueFalseAnswerPayload,
  FreeTextAnswerPayload,
  MatchingAnswerPayload,
  ClozeAnswerPayload,
  ClozeBlank,
  CoordinateAnswerPayload,
  CoordinateGrid,
  CoordinateExpected,
} from './answerPayload'
export { isAnswerPayload } from './answerPayload'

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
  StudentFocusArea,
} from './screening'

export type {
  BadgeRarity,
  BadgeForm,
  Badge,
  StudentBadge,
  StreakRepairInventory,
} from './gamification'

export type {
  TaskStatus,
  Afb,
  AuthoringInputType,
  PartKind,
  PartOption,
  TaskPart,
  AuthoringTask,
  AuthoringTaskPatch,
  SolutionAnswers,
  TaskSolution,
  TaskSolutionPatch,
  ItemFlag,
  AuthoringListItem,
  AuthoringSchema,
  GroundingBeleg,
  GroundingQuote,
  GroundingRecord,
  GroundingRohteil,
} from './authoring'

export type {
  CompetencyCode,
  ProcessCompetency,
  MasteryStage,
  StudentCompetencyMastery,
} from './competency'
