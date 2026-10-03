// Fester Testkatalog fuer die Themensuche: ein Auszug aus dem Katalog vom
// 03.10.2026 (Labels und Schlagworte wie in public.themen), damit die Tests
// nicht an der DB haengen.
import type { Thema } from '@/types'

const t = (
  thema_key: string,
  stufe: Thema['stufe'],
  sort: number,
  label: string,
  schlagworte: string[],
): Thema => ({ thema_key, fach: 'mathematik', stufe, sort, label, schlagworte })

export const TEST_KATALOG: Thema[] = [
  t('rechnen_natuerliche_zahlen', 'erprobung', 20, 'Rechnen mit natürlichen Zahlen', [
    'grundrechenarten',
    'punkt vor strich',
  ]),
  t('daten_streumasse', 'erprobung', 30, 'Daten, Diagramme und Kenngrößen', [
    'säulendiagramm',
    'mittelwert',
  ]),
  t('brueche', 'erprobung', 90, 'Brüche und Anteile', ['brüche', 'kürzen', 'pizza']),
  t('rationale_zahlen', 'erste', 210, 'Rationale Zahlen', ['negative zahlen', 'betrag']),
  t('zinsrechnung', 'erste', 230, 'Prozent- und Zinsrechnung', [
    'prozent',
    'zinsen',
    'zinsrechnung',
    'zinseszins',
  ]),
  t('lineare_funktionen', 'erste', 260, 'Lineare Funktionen', [
    'steigung',
    'steigungsdreieck',
    'y-achsenabschnitt',
  ]),
  t('terme_binomische_formeln', 'erste', 270, 'Terme mit mehreren Variablen und binomische Formeln', [
    'binomische formeln',
    'binomisch',
    'ausklammern',
  ]),
  t('zufallsexperimente', 'erste', 280, 'Zufall und Wahrscheinlichkeit', [
    'wahrscheinlichkeit',
    'baumdiagramm',
    'pfadregeln',
  ]),
  t('thales_konstruktionen', 'erste', 310, 'Kreise und Dreiecke: Thales und besondere Linien', [
    'thales',
    'satz des thales',
    'thaleskreis',
  ]),
  t('reelle_zahlen', 'zweite', 410, 'Reelle Zahlen und Wurzeln', [
    'reelle zahlen',
    'irrationale zahlen',
    'wurzel',
    'quadratwurzel',
    'pi',
  ]),
  t('quadratische_funktionen', 'zweite', 430, 'Quadratische Funktionen', [
    'parabel',
    'normalparabel',
    'scheitelpunkt',
  ]),
  t('aehnlichkeit', 'zweite', 460, 'Ähnlichkeit und zentrische Streckung', [
    'ähnlichkeit',
    'strahlensatz',
  ]),
  t('kreis', 'zweite', 470, 'Kreis: Umfang und Fläche', ['kreis', 'kreisumfang', 'pi', 'radius']),
  t('trigonometrie', 'zweite', 500, 'Trigonometrie', ['sinus', 'steigungswinkel']),
  t('exponentialfunktionen', 'zweite', 510, 'Exponentielles Wachstum', [
    'wachstum',
    'zinseszins',
  ]),
  t('bedingte_wahrscheinlichkeit', 'zweite', 530, 'Bedingte Wahrscheinlichkeit', [
    'vierfeldertafel',
    'baumdiagramm',
  ]),
]
