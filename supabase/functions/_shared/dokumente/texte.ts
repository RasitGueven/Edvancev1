// ERZEUGT von tools/dokumente-buendeln.mjs — nicht von Hand bearbeiten.
//
// Die Textbausteine der Vertragsunterlagen als TypeScript. Warum nicht die
// .md direkt lesen: Der Supabase-Bundler nimmt nur den Import-Graph der
// TypeScript-Dateien mit. Ein Deno.readTextFile auf eine .md im Function-
// Ordner liefe lokal und waere nach dem Deploy tot.
//
// Damit gibt es die Vorlagen zweimal. Bewusste Doppelung mit Wachhund:
// vorlagenGleich.test.ts erzeugt diese Datei im Test noch einmal und
// vergleicht sie mit der eingecheckten. Aendert jemand nur eine Seite,
// wird der Test rot und nennt den Befehl, der es richtet.

export type DokumentArt = "vertrag" | "sepa_mandat" | "agb" | "widerruf" | "datenschutz_vertrag" | "einwilligung_fotos"

/** Die Arten, die je Vertrag entstehen — mit eingesetzten Werten. */
export const JE_VERTRAG: DokumentArt[] = ["vertrag", "sepa_mandat"]

/** Die Arten, die fuer alle gleich sind — eine Datei je Fassung. */
export const JE_FASSUNG: DokumentArt[] = ["agb", "widerruf", "datenschutz_vertrag", "einwilligung_fotos"]

/** Fassungskennung je Art, muss zu vertrag_dokumente.version passen. */
export const FASSUNG: Record<DokumentArt, string> = {
  vertrag: "platzhalter-v1",
  sepa_mandat: "platzhalter-v1",
  agb: "platzhalter-v1",
  widerruf: "platzhalter-v1",
  datenschutz_vertrag: "platzhalter-v1",
  einwilligung_fotos: "platzhalter-v1",
}

/** Wortgleich mit src/pages/admin/vertraege/dokumente/de/<art>.md. */
export const TEXT: Record<DokumentArt, string> = {
  vertrag: "# Vertrag über Lernbegleitung\n\n> **PLATZHALTER — NOCH KEIN RECHTSTEXT.** Dieser Text ist ohne rechtliche Bedeutung und darf so nicht im Echtbetrieb verwendet werden. Er steht hier, damit Erfassen, Prüfen, Unterschreiben und Drucken vollständig gebaut werden können.\n\n## Vertragspartner\n\n**Edvance** (Anbieter) und\n\n{{eltern_name}}\n{{anschrift}}\nTelefon: {{eltern_telefon}} · E-Mail: {{eltern_email}}\n\n## Teilnehmendes Kind\n\n{{kind_name}}, geboren am {{kind_geburtsdatum}}\nKlasse {{klasse}} · Fach {{fach}} · Schule: {{schule}}\n\n## Leistung und Preis\n\n- Paket: **{{paket}}**\n- Laufzeit: **{{laufzeit}}**\n- Umfang: **{{einheiten}} Coaching-Einheiten** à 60 Minuten\n- Monatlicher Beitrag: **{{preis}}**, **{{beitraege}}** Beiträge\n- Gesamtpreis: **{{gesamtpreis}}**\n- Vertragsbeginn: **{{vertragsbeginn}}**\n- Vertragsende: **{{vertragsende}}**\n\n{{ferienklausel}}\n\n## Weitere Regelungen\n\nHier stehen später Leistungsumfang, Laufzeit und Kündigung, Zahlungsbedingungen, Ausfallregelungen und Haftung. Den Text legt eine rechtskundige Person fest.",
  sepa_mandat: "# SEPA-Lastschriftmandat\n\n> **PLATZHALTER — NOCH KEIN RECHTSTEXT.** Wortlaut und Pflichtangaben des Mandats sind vor dem Echtbetrieb zu prüfen.\n\n- Zahlungsempfänger: **Edvance**\n- Gläubiger-Identifikationsnummer: **{{glaeubiger_id}}**\n- Mandatsreferenz: **{{mandatsreferenz}}**\n\nIch ermächtige den Zahlungsempfänger, Zahlungen von meinem Konto mittels Lastschrift einzuziehen. Zugleich weise ich mein Kreditinstitut an, die vom Zahlungsempfänger auf mein Konto gezogenen Lastschriften einzulösen.\n\nHinweis: Ich kann innerhalb von acht Wochen, beginnend mit dem Belastungsdatum, die Erstattung des belasteten Betrages verlangen. Es gelten dabei die mit meinem Kreditinstitut vereinbarten Bedingungen.\n\n## Kontoinhaber:in\n\n{{kontoinhaber}}\n{{anschrift}}\n\n- IBAN: **{{iban}}**\n- Betrag: **{{preis}}** monatlich, ab **{{vertragsbeginn}}**",
  agb: "# Allgemeine Geschäftsbedingungen\n\n> **PLATZHALTER — NOCH KEIN RECHTSTEXT.** Die AGB werden vor dem Echtbetrieb von einer rechtskundigen Person erstellt. Beim Ersetzen die Versionskennung in `vertrag_dokumente` und im Dokumentregister hochzählen.",
  widerruf: "# Widerrufsbelehrung\n\n> **PLATZHALTER — NOCH KEIN RECHTSTEXT.** Belehrung und Muster-Widerrufsformular werden vor dem Echtbetrieb eingesetzt.\n\n## Muster-Widerrufsformular\n\n(Wenn Sie den Vertrag widerrufen wollen, dann füllen Sie bitte dieses Formular aus und senden Sie es zurück.)\n\n- An: Edvance\n- Hiermit widerrufe(n) ich/wir den von mir/uns abgeschlossenen Vertrag über die Erbringung der folgenden Dienstleistung: ____________________\n- Bestellt am / erhalten am: ____________________\n- Name des/der Verbraucher(s): ____________________\n- Anschrift des/der Verbraucher(s): ____________________\n- Datum, Unterschrift: ____________________",
  datenschutz_vertrag: "# Datenschutzhinweise zum Vertrag\n\n> **PLATZHALTER — NOCH KEIN RECHTSTEXT.** Diese Hinweise betreffen die Verarbeitung der Vertrags- und Zahlungsdaten. Sie sind **nicht** die Einwilligung in die Verarbeitung der Lerndaten aus der Lernstandsanalyse — die ist ein eigenes Dokument mit eigener Unterschrift.",
  einwilligung_fotos: "# Einwilligung Fotos\n\n> **PLATZHALTER — NOCH KEIN RECHTSTEXT.** Optionale Einwilligung. Sie ist freiwillig und keine Voraussetzung für den Vertrag.",
}

/** Wortgleich mit de/vertraege.json → doc.* */
export const FERIENKLAUSEL = "Geschuldet sind {{einheiten}} Coaching-Einheiten. Das Vertragsende ist der Stichtag, bis zu dem sie abgerufen werden können — es verschiebt sich um die {{tage}} Ferientage der Laufzeit auf den {{ende}}. Der Beitrag wird in den ersten sechs Monaten erhoben; die darüber hinausgehende Laufzeit ist beitragsfrei."
export const KEINE_FERIENKLAUSEL = "Die Laufzeit umfasst zwölf volle Kalendermonate mit zwölf Beiträgen."
export const GLAEUBIGER_ID_FEHLT = "**Gläubiger-Identifikationsnummer fehlt — dieses Mandat ist nicht gültig.** Es wurde erzeugt, damit der Ablauf vollständig ist. Vor dem ersten Einzug muss die Nummer eingetragen und das Mandat neu erstellt werden."

/** Wortgleich mit de/vertraege.json → mail.* — die Texte, die an Eltern gehen. */
export const MAIL: Record<string, string> = {
  bestaetigungBetreff: "Ihr Vertrag mit Edvance für {{kind}}",
  bestaetigungText: "Guten Tag {{eltern}},\n\nvielen Dank für Ihr Vertrauen. Anbei finden Sie alle Unterlagen zum Vertrag für {{kind}}:\n{{liste}}\n\nDer Vertrag läuft vom {{beginn}} bis zum {{ende}}. Bis einschließlich {{widerruf}} können Sie ihn ohne Angabe von Gründen widerrufen; die Widerrufsbelehrung liegt bei.\n\nDen Zugang für {{kind}} richten wir vor dem ersten Termin gemeinsam ein. Bei Fragen antworten Sie einfach auf diese Mail.\n\nHerzliche Grüße\nIhr Edvance-Team",
  unterlagenBetreff: "Ihre Vertragsunterlagen von Edvance",
  unterlagenText: "Guten Tag {{eltern}},\n\nanbei die Unterlagen für {{kind}}. Bitte drucken Sie den Vertrag und das SEPA-Mandat aus, unterschreiben beides und senden es uns zurück — bis zum {{bis}}.\n{{liste}}\n\nDer Vertrag kommt erst zustande, wenn uns das unterschriebene Original vorliegt. Bis dahin ist für Sie nichts verbindlich.\n\nBei Fragen antworten Sie einfach auf diese Mail.\n\nHerzliche Grüße\nIhr Edvance-Team",
  zugangscodeBetreff: "Ihr neuer Zugangscode für Edvance",
  zugangscodeText: "Guten Tag {{eltern}},\n\nder Zugangscode für {{kind}} lautet:\n\n    {{code}}\n\nDer bisherige Code gilt nicht mehr. Geben Sie den Code bitte nicht weiter — er gehört zu diesem einen Zugang.\n\nHerzliche Grüße\nIhr Edvance-Team",
  terminBetreff: "Ihr Erstgespräch bei Edvance am {{datum}}",
  terminText: "Guten Tag,\n\nhiermit bestätigen wir den Termin für das Erstgespräch mit {{kind}}:\n\nTermin: {{datum}}, {{uhrzeit}} Uhr\nOrt: {{ort}}\nDauer: {{dauer}}\n\nZu Beginn sprechen wir mit Ihnen und {{kind}} über die Schule und darüber, was gerade schwerfällt. Danach bearbeitet {{kind}} etwa 20 Minuten lang Aufgaben am Tablet, während wir mit Ihnen weitersprechen; anschließend besprechen wir gemeinsam, was wir gesehen haben.\n\nBitte bringen Sie mit: das Mathe-Heft (Schulheft), das Hausaufgabenheft und – falls vorhanden – die letzte Klassenarbeit.\n\nFalls der Termin nicht passt oder Sie Fragen haben, antworten Sie einfach auf diese Mail.\n\nHerzliche Grüße\nIhr Edvance-Team",
  terminDauer: "etwa 60 Minuten – Gespräch und eine 20-minütige Lernstandsanalyse am Tablet",
  anhangZeile: "- {{name}}",
}

/** Wortgleich mit de/vertraege.json → form.laufzeitOption. */
export const LAUFZEIT_TEXT: Record<number, string> = {
  6: "6 Monate · Halbjahrespaket",
  12: "12 Monate · Jahrespaket",
}
