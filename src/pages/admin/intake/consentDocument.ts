// Text der DSGVO-Einwilligung, die die Eltern im Erstgespraech unterschreiben.
//
// ACHTUNG: Das ist ein PLATZHALTER, kein Rechtstext. Er steht hier, damit der
// Unterschriften-Fluss vollstaendig gebaut und getestet werden kann. Vor dem
// ersten echten Einsatz muss ihn eine rechtskundige Person ersetzen — und dabei
// CONSENT_DOCUMENT_VERSION hochzaehlen, damit sich unterschriebene Fassungen
// spaeter auseinanderhalten lassen.

/** Wird zusammen mit der Unterschrift am Lead gespeichert. */
export const CONSENT_DOCUMENT_VERSION = 'platzhalter-v1'

export const CONSENT_DOCUMENT_TITLE = 'Einwilligung in die Verarbeitung der Lerndaten'

export const CONSENT_DOCUMENT_TEXT = `PLATZHALTER — NOCH KEIN RECHTSTEXT

Dieser Text ist ein Platzhalter fuer die spaetere Einwilligungserklaerung. Er
ist rechtlich ohne Bedeutung und darf so nicht im Echtbetrieb verwendet werden.
Er steht hier ausschliesslich, damit der Ablauf — lesen, unterschreiben,
speichern — vollstaendig gebaut und geprueft werden kann.

Was an dieser Stelle spaeter stehen muss, hat eine rechtskundige Person
festzulegen. Erwartbar sind unter anderem: wer verantwortlich ist, welche Daten
zu welchem Zweck verarbeitet werden, auf welcher Rechtsgrundlage, wie lange sie
gespeichert bleiben, wer sie einsehen kann, sowie die Rechte der betroffenen
Person und der Hinweis auf den jederzeitigen Widerruf.

Mit der Unterschrift unter diesem Platzhalter wird KEINE wirksame Einwilligung
erteilt. Solange die Versionskennung mit "platzhalter" beginnt, ist die erfasste
Unterschrift nur ein technischer Nachweis, dass der Ablauf durchlaufen wurde —
kein Beleg fuer eine erteilte Einwilligung.

Vor dem Echtbetrieb zu tun:
1. Diesen Text durch die gepruefte Einwilligungserklaerung ersetzen.
2. CONSENT_DOCUMENT_VERSION auf eine neue Kennung setzen.
3. Klaeren, wie mit Unterschriften umzugehen ist, die auf dieser
   Platzhalter-Fassung beruhen.`
