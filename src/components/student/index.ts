/**
 * Geteilte Schüler-Design-Sprache (dunkle „Midnight-Academy"-Bühne).
 * NUR für Schüler-Surfaces — kein Import in Parent/Coach-Pfade (Stil-Leak).
 */
export { SessionButton } from './SessionButton'
export {
  STAGE_BG,
  STAGE_TEXT,
  displayMasteryStage,
  masteryStageForLevel,
} from './masteryClasses'
