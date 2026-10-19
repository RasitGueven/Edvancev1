// Tablet-Präsentation — Einstellungen, die die Gründer in der Abnahme festlegen.

import type { TpAnzeige } from '@/types'

/**
 * Zählweise „übersprungen" (Entscheidung 4 der Anforderung).
 * - kombiniert: Übungsbedarf wie auf dem Druckbogen, übersprungen zählt mit
 *   („davon x übersprungen").
 * - getrennt: Übungsbedarf ohne übersprungen, eigene dritte Zahl.
 * In der Ansicht gibt es keinen Schalter.
 */
export const UEBERSPRUNGEN_ANZEIGE: TpAnzeige = 'kombiniert'
