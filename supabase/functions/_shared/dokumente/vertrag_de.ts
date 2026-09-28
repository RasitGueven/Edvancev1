// Die Textbausteine des Vertrags-PDF — als TypeScript, nicht als Datei.
//
// Warum nicht die .md direkt lesen: Der Supabase-Bundler nimmt nur den
// Import-Graph der TypeScript-Dateien mit. Ein Deno.readTextFile auf eine .md
// im Function-Ordner liefe lokal und waere nach dem Deploy tot.
//
// Damit gibt es die Vorlage zweimal: hier und unter
// src/pages/admin/vertraege/dokumente/de/vertrag.md fuer die Druckansicht.
// Das ist eine bewusste Doppelung mit Wachhund — vorlagenGleich.test.ts
// vergleicht beide Seiten Zeichen fuer Zeichen und wird rot, sobald eine
// Seite allein geaendert wird. Die saubere Loesung (Vorlagentexte in
// vertrag_dokumente, eine Quelle fuer beide) steht in den Folgeaufgaben.

/** Fassung, muss zu vertrag_dokumente.version passen. */
export const VERTRAG_VERSION = "platzhalter-v1"

/** Wortgleich mit src/pages/admin/vertraege/dokumente/de/vertrag.md. */
export const VERTRAG_MD = `# Vertrag über Lernbegleitung

> **PLATZHALTER — NOCH KEIN RECHTSTEXT.** Dieser Text ist ohne rechtliche Bedeutung und darf so nicht im Echtbetrieb verwendet werden. Er steht hier, damit Erfassen, Prüfen, Unterschreiben und Drucken vollständig gebaut werden können.

## Vertragspartner

**Edvance** (Anbieter) und

{{eltern_name}}
{{anschrift}}
Telefon: {{eltern_telefon}} · E-Mail: {{eltern_email}}

## Teilnehmendes Kind

{{kind_name}}, geboren am {{kind_geburtsdatum}}
Klasse {{klasse}} · Fach {{fach}} · Schule: {{schule}}

## Leistung und Preis

- Paket: **{{paket}}**
- Laufzeit: **{{laufzeit}}**
- Umfang: **{{einheiten}} Coaching-Einheiten** à 60 Minuten
- Monatlicher Beitrag: **{{preis}}**, **{{beitraege}}** Beiträge
- Gesamtpreis: **{{gesamtpreis}}**
- Vertragsbeginn: **{{vertragsbeginn}}**
- Vertragsende: **{{vertragsende}}**

{{ferienklausel}}

## Weitere Regelungen

Hier stehen später Leistungsumfang, Laufzeit und Kündigung, Zahlungsbedingungen, Ausfallregelungen und Haftung. Den Text legt eine rechtskundige Person fest.`

/** Wortgleich mit de/vertraege.json → doc.ferienklausel. */
export const FERIENKLAUSEL =
  "Geschuldet sind {{einheiten}} Coaching-Einheiten. Das Vertragsende ist der Stichtag, bis zu dem sie abgerufen werden können — es verschiebt sich um die {{tage}} Ferientage der Laufzeit auf den {{ende}}. Der Beitrag wird in den ersten sechs Monaten erhoben; die darüber hinausgehende Laufzeit ist beitragsfrei."

/** Wortgleich mit de/vertraege.json → doc.keineFerienklausel. */
export const KEINE_FERIENKLAUSEL =
  "Die Laufzeit umfasst zwölf volle Kalendermonate mit zwölf Beiträgen."

/** Wortgleich mit de/vertraege.json → form.laufzeitOption. */
export const LAUFZEIT_TEXT: Record<number, string> = {
  6: "6 Monate · Halbjahrespaket",
  12: "12 Monate · Jahrespaket",
}
