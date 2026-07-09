import { test } from '@playwright/test'

// Zielkette der Kernschleife über die 3 Rollen (Schüler → Coach → Eltern).
// Bewusst als `test.fixme` angelegt: die Schritte beschreiben, wohin die Reise
// geht — implementiert werden sie erst, wenn die zugehörigen Lücken geschlossen
// sind. Keine erfundenen Selektoren; nur die Schrittstruktur.
//
// Gap-Analyse + Reihenfolge der Folge-Specs: docs/audits/KERNSCHLEIFE-GAP-AUDIT.md

test.describe('Kernschleife: Schüler → Coach → Eltern', () => {
  // --- Schüler ---------------------------------------------------------------

  test.fixme('Schüler loggt sich ein und landet auf dem Dashboard', async () => {
    /* TODO nach P03b+ */
  })

  test.fixme('Schüler startet eine Session', async () => {
    /* TODO nach P03b: /student/session/:id lädt echte Tasks statt WARMUP_TASKS */
  })

  test.fixme('Schüler löst 3 Aufgaben; kein Richtig/Falsch-Feedback', async () => {
    /* TODO nach P03b — FernUSG: kind-seitig niemals Korrektheit anzeigen */
  })

  test.fixme('XP des Schülers ist nach der Session gestiegen', async () => {
    /* TODO nach P03b: XP fließt serverseitig über den RPC complete_task */
  })

  // --- Coach -----------------------------------------------------------------

  test.fixme('Coach loggt sich ein und sieht den Fortschritt des Schülers', async () => {
    /* TODO nach P03b/P03g: Coach sieht die abgeschlossene Session des Schülers */
  })

  test.fixme('Coach vergibt Mastery für eine Kompetenz', async () => {
    /* TODO nach P03c — FernUSG-Gate: grantMastery ist der einzige Schreibpfad */
  })

  test.fixme('Schüler ohne Coach-Rolle kann keine Mastery setzen', async () => {
    /* TODO nach P03c — negativer Pfad, deckt den Gate-Trigger ab */
  })

  // --- Zurück zum Schüler ----------------------------------------------------

  test.fixme('Lernpfad des Schülers ist nach der Mastery-Vergabe fortgeschritten', async () => {
    /* TODO nach P03d: Mastery gated Cluster-/Task-Verfügbarkeit */
  })

  // --- Eltern ----------------------------------------------------------------

  test.fixme('Eltern loggen sich ein und der Report zeigt die Session', async () => {
    /* TODO nach P03h: Report liest Task-Progress + Mastery-Historie */
  })

  test.fixme('Eltern sehen keinen unveröffentlichten Report-Entwurf', async () => {
    /* TODO nach P03h — negativer Pfad, deckt die Draft/Published-RLS ab */
  })
})
