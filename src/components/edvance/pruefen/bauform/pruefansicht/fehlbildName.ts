// Name eines typischen Fehlers in der Prüfansicht (SP-1b N2): zuerst ein Name je Bauform (fehlbildName.<BAUFORM>.<key>,
// z. B. NF-5, wo derselbe Schlüssel etwas anderes bedeutet), sonst der allgemeine (fehlbild.<key>), sonst der Satz aus
// fehlbild_labels. Kein neuer Fehlbild-Schlüssel, also kein Versionswechsel.
import type { i18n as I18n, TFunction } from 'i18next'

export function fehlbildName(t: TFunction, i18n: I18n, bauform: string, key: string, rueckfall: string | null): string | null {
  if (i18n.exists(`bauformPruefen:fehlbildName.${bauform}.${key}`)) return t(`fehlbildName.${bauform}.${key}`)
  if (i18n.exists(`bauformPruefen:fehlbild.${key}`)) return t(`fehlbild.${key}`)
  return rueckfall
}
