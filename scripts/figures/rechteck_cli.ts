/**
 * Bruecke fuer upload_figures.py: liest {"params": …, "theme": …} von stdin und
 * schreibt das SVG von `zeichne` nach stdout. Fehler gehen als Klartext nach
 * stderr, Exit-Code 1 — die Python-Seite (rechteck.py) macht daraus ValueError.
 *
 * Aufruf: node_modules/.bin/tsx scripts/figures/rechteck_cli.ts < eingabe.json
 */

import { zeichne } from './rechteck'

let roh = ''
process.stdin.setEncoding('utf8')
process.stdin.on('data', (teil: string) => {
  roh += teil
})
process.stdin.on('end', () => {
  try {
    const { params, theme } = JSON.parse(roh) as { params: unknown; theme: unknown }
    process.stdout.write(zeichne(params, theme))
  } catch (e) {
    process.stderr.write(e instanceof Error ? e.message : String(e))
    process.exit(1)
  }
})
