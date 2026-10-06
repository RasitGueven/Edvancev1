// Fake-Supabase für Bildschirmfotos (H6). Erfundene Beispieldaten, keine Prod-Kopie.
const rolle = (sessionStorage.getItem('harness-rolle') ?? 'coach') as 'coach' | 'admin'
const USER = { id: `u-${rolle}`, email: rolle === 'coach' ? 'zz.coach@edvance.de' : 'zz.admin@edvance.de', user_metadata: {} }

function heute(h: number, m = 0): string {
  const d = new Date()
  d.setHours(h, m, 0, 0)
  return d.toISOString()
}
const morgen = new Date(Date.now() + 86400000)
morgen.setHours(16, 0, 0, 0)

const zeile = (id: string, reihenfolge: number, lena_status = 'offen', kurztitel = id) => ({
  task_id: id, stufe: 'zweite', thema_key: 'kreis', thema_label: 'Kreis: Umfang und Fläche', thema_sort: 470,
  skill_key: 'geo_kreis_umfang', skill_label: 'Umfang des Kreises', kurztitel, reihenfolge,
  lena_status, geaendert: false, letzte_dauer_sek: null,
})

const sicht = {
  werte: [{ teil: null, werte: [{ wert: '22,62', schreibweisen: ['22,62', '22.62'] }] }],
  mc: null,
  regel: { art: 'wert', mitte: null, toleranz: null, einheit_pflicht: false, einheit: 'm', einheit_am_feld: true },
  fehler: [{ slug: 'pi_vergessen', werte: [{ teil: null, wert: '7,2' }], text: 'π weggelassen.', klartext: 'Lässt π weg.' }],
  weitere_hinweise: [],
  skill_key: 'geo_kreis_umfang',
  afb: 'II',
  flach_regel: true,
  ohne_erkennung: false,
}

const aufgabe = {
  task_id: 't1',
  kopf: { kurztitel: 'Umfang · Radius 3,6 m', stufe: 'zweite', thema_key: 'kreis', thema_label: 'Kreis: Umfang und Fläche', hilfsmittel: 'Taschenrechner, Stift und Zettel' },
  aufgabe: { input_type: 'NUMERIC', unit: 'm', status: 'draft', lena_status: 'offen', pruef_version: 3, ausschluss: null, pilot: false, team_beanstandet: false, parts: [], optionen: [], bild_vorhanden: false },
  ...sicht,
  loesungsweg: 'U = 2 · π · 3,6 m ≈ 22,62 m',
  fertigkeit: { key: 'geo_kreis_umfang', label: 'Umfang des Kreises', thema_key: 'kreis', thema_label: 'Kreis: Umfang und Fläche', stufe: 'zweite', voraussetzungen: ['Werte in Terme einsetzen'] },
  fertigkeit_optionen: [{ key: 'geo_kreis_umfang', label: 'Umfang des Kreises', gruppe: 'thema' }, { key: 'term_einsetzen', label: 'Werte in Terme einsetzen', gruppe: 'voraussetzung' }],
  afb_sicher: 'mittel',
  ausgang: sicht,
  aenderungen: [],
  letzte_pruefung: null,
  auffaelligkeiten: [],
}


const TABELLEN: Record<string, Record<string, unknown>[]> = {
  profiles: [
    { id: 'u-coach', role: 'coach', full_name: 'ZZ_Lena Beispiel' },
    { id: 'u-admin', role: 'admin', full_name: 'ZZ_Rasit Beispiel' },
  ],
  coaching_sessions: [
    { id: 's1', created_at: heute(8), coach_id: USER.id, room: 'Raum 1', scheduled_at: heute(15), status: 'scheduled' },
    { id: 's2', created_at: heute(8), coach_id: USER.id, room: 'Raum 2', scheduled_at: heute(17), status: 'scheduled' },
    { id: 's3', created_at: heute(8), coach_id: USER.id, room: 'Raum 1', scheduled_at: morgen.toISOString(), status: 'scheduled' },
  ],
  schuelerakten: [
    { student_id: 'k1', name: 'ZZ_Efe Demir', klasse: 9, schule_id: null, schule: 'ZZ_Gymnasium', akte_seit: '2026-09-15', zustand: 'aktiv', ruhend_seit: null, letzte_session: null },
  ],
  student_subjects: [{ student_id: 'k1', subjects: { name: 'Mathematik' } }],
  pruef_einstellungen: [{ hilfsmittel: 'Taschenrechner, Stift und Zettel', nur_pilot: false, grund_pflicht: false }],
}

const RPC: Record<string, unknown> = {
  darf_pruefen: true,
  pruef_board: [
    zeile('t1', 1, 'offen', 'Umfang · Radius 3,6 m'), zeile('t2', 2, 'offen', 'Fläche · Radius 2 cm'),
    zeile('t3', 3, 'offen', 'Durchmesser aus Umfang'), zeile('t4', 4, 'passt', 'Kreisring'),
  ],
  pruef_aufgabe: aufgabe,
  einheiten_stand: {
    art: 'laufend', einheiten: 29, beginn: '2026-09-01', stichtag: '2027-06-15', verbraucht: 6, offen: 23,
    soll: 5.8, rueckstand: -0.2, ampel: 'im_plan', wochen_rest: 30, noetig_pro_woche: 0.8, gleichmaessig_pro_woche: 0.8,
  },
  akte_sessions: [
    { session_id: 's9', scheduled_at: '2026-09-29T13:00:00Z', coach_name: 'ZZ_Lena Beispiel', attendance: 'present' },
    { session_id: 's8', scheduled_at: '2026-09-22T13:00:00Z', coach_name: 'ZZ_Lena Beispiel', attendance: 'present' },
  ],
  fortschritt: [{ fach_id: 'm', fach: 'Mathematik', thema: 'Algebra & Funktionen', station: 2, stationen: 5,
    kompetenzen: [{ kompetenz: 'ZZ_Lineare Gleichungen lösen', prozess: null, coach: 'ZZ_Lena Beispiel', am: '2026-09-29T13:00:00Z' }] }],
  board_schueler: [],
}

function abfrage(tabelle: string) {
  let zeilen = [...(TABELLEN[tabelle] ?? [])]
  let eins = false
  let kopf = false
  const ergebnis = () => {
    const data = eins ? (zeilen[0] ?? null) : kopf ? null : zeilen
    return { data, error: null, count: zeilen.length }
  }
  const b: Record<string, unknown> = {}
  const self = new Proxy(b, {
    get(_t, prop: string) {
      if (prop === 'then') return (ok: (v: unknown) => unknown, nein?: (e: unknown) => unknown) => Promise.resolve(ergebnis()).then(ok, nein)
      if (prop === 'single' || prop === 'maybeSingle') return () => { eins = true; return self }
      if (prop === 'eq') return (spalte: string, wert: unknown) => {
        zeilen = zeilen.filter((z) => !(spalte in z) || z[spalte] === wert)
        return self
      }
      if (prop === 'in') return (spalte: string, werte: unknown[]) => {
        zeilen = zeilen.filter((z) => !(spalte in z) || werte.includes(z[spalte]))
        return self
      }
      if (prop === 'select') return (_s?: string, opt?: { head?: boolean }) => { if (opt?.head) kopf = true; return self }
      return () => self
    },
  })
  return self
}

export const supabase = {
  from: (t: string) => abfrage(t),
  rpc: (fn: string) => Promise.resolve({ data: RPC[fn] ?? null, error: null }),
  auth: {
    getSession: () => Promise.resolve({ data: { session: { user: USER } }, error: null }),
    onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => {} } } }),
    signOut: () => Promise.resolve({ error: null }),
    signInWithPassword: () => Promise.resolve({ data: null, error: null }),
  },
  channel: () => ({ on() { return this }, subscribe() { return this } }),
  removeChannel: () => {},
  storage: { from: () => ({ createSignedUrl: () => Promise.resolve({ data: null, error: null }) }) },
}
