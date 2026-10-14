// Die Texte der Auth-Mails. Ton und Anrede wie die Mails aus mail_senden
// ("Guten Tag …", Sie-Form, "Herzliche Grüße / Ihr Edvance-Team"), kurz,
// ohne Marketing.
//
// Warum nicht in src/i18n: Diese Mails haben in der Oberflaeche keine
// Vorschau, nur die Edge Function liest sie. Eine Doppelung mit Wachhund wie
// bei den Vertragsmails (dokumente/texte.ts) waere hier reiner Aufwand.
//
// Platzhalter: {{anrede}} ("Guten Tag Name" oder "Guten Tag"), {{link}},
// {{code}}, {{gueltig}}.

export type MailArt = 'invite' | 'recovery' | 'signup' | 'email_change' | 'reauthentication' | 'magiclink'

export const ARTEN: readonly MailArt[] = [
  'invite',
  'recovery',
  'signup',
  'email_change',
  'reauthentication',
  'magiclink',
]

/** Muss zur Einstellung "Email OTP Expiration" (86400 s) passen. */
export const GUELTIG = '24 Stunden'

const GRUSS = 'Herzliche Grüße\nIhr Edvance-Team'

export const TEXTE: Record<MailArt, { betreff: string; text: string }> = {
  invite: {
    betreff: 'Ihr Zugang zu Edvance',
    text:
      '{{anrede}},\n\n' +
      'Sie wurden zu Edvance eingeladen. Über den folgenden Link legen Sie Ihr Passwort fest; ' +
      'damit ist auch Ihre E-Mail-Adresse bestätigt:\n\n{{link}}\n\n' +
      'Der Link gilt {{gueltig}} und lässt sich einmal verwenden. Ist er abgelaufen, ' +
      'antworten Sie einfach auf diese Mail, dann schicken wir eine neue Einladung.\n\n' +
      'Falls Sie diese Mail nicht erwartet haben, können Sie sie ignorieren.\n\n' +
      GRUSS,
  },
  recovery: {
    betreff: 'Neues Passwort für Edvance',
    text:
      '{{anrede}},\n\n' +
      'für Ihr Konto bei Edvance wurde ein neues Passwort angefordert. Über den folgenden Link ' +
      'legen Sie es fest:\n\n{{link}}\n\n' +
      'Der Link gilt {{gueltig}} und lässt sich einmal verwenden. Haben Sie kein neues Passwort ' +
      'angefordert, können Sie diese Mail ignorieren; Ihr bisheriges Passwort gilt weiter.\n\n' +
      GRUSS,
  },
  signup: {
    betreff: 'Bitte bestätigen Sie Ihre E-Mail-Adresse',
    text:
      '{{anrede}},\n\n' +
      'bitte bestätigen Sie Ihre E-Mail-Adresse für Edvance über den folgenden Link:\n\n{{link}}\n\n' +
      'Der Link gilt {{gueltig}}. Falls Sie diese Mail nicht erwartet haben, können Sie sie ignorieren.\n\n' +
      GRUSS,
  },
  email_change: {
    betreff: 'Änderung Ihrer E-Mail-Adresse bei Edvance',
    text:
      '{{anrede}},\n\n' +
      'für Ihr Konto bei Edvance wurde eine Änderung der E-Mail-Adresse angefordert. ' +
      'Bitte bestätigen Sie sie über den folgenden Link:\n\n{{link}}\n\n' +
      'Der Link gilt {{gueltig}}. Haben Sie die Änderung nicht angefordert, antworten Sie bitte ' +
      'auf diese Mail; Ihre bisherige Adresse bleibt bis zur Bestätigung gültig.\n\n' +
      GRUSS,
  },
  reauthentication: {
    betreff: 'Ihr Bestätigungscode für Edvance',
    text:
      '{{anrede}},\n\n' +
      'Ihr Bestätigungscode lautet:\n\n    {{code}}\n\n' +
      'Geben Sie ihn nur in Edvance ein und nicht weiter. Haben Sie keinen Code angefordert, ' +
      'können Sie diese Mail ignorieren.\n\n' +
      GRUSS,
  },
  magiclink: {
    betreff: 'Ihr Anmeldelink für Edvance',
    text:
      '{{anrede}},\n\n' +
      'über den folgenden Link melden Sie sich bei Edvance an:\n\n{{link}}\n\n' +
      'Der Link gilt {{gueltig}} und lässt sich einmal verwenden. Haben Sie keinen Link ' +
      'angefordert, können Sie diese Mail ignorieren.\n\n' +
      GRUSS,
  },
}
