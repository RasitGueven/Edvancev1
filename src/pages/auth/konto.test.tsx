// Konto K1 im Browser-Teil: Einladung annehmen, neues Passwort, Passwort
// vergessen, Mein Konto, und dass die Login-Anmeldung (auch Kiosk/Tablet)
// unveraendert bleibt.
//
// Der Supabase-Client ist eine Attrappe; geprueft wird, WELCHE Auth-Aufrufe
// in welcher Reihenfolge kommen — vor allem, dass der Token aus der Mail erst
// nach dem Klick eingeloest wird (Mail-Scanner oeffnen Links vorab).

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'

const sb = vi.hoisted(() => {
  const ok = (data: unknown = {}) => Promise.resolve({ data, error: null })
  return {
    ok,
    auth: {
      verifyOtp: vi.fn(() => ok({ session: {} })),
      updateUser: vi.fn(() => ok({ user: {} })),
      resetPasswordForEmail: vi.fn(() => ok()),
      signInWithPassword: vi.fn(() => ok({ user: { id: 'u1' } })),
      signOut: vi.fn(() => Promise.resolve({ error: null })),
    },
  }
})
vi.mock('@/lib/supabase/client', () => ({ supabase: { auth: sb.auth } }))

const authZustand = vi.hoisted(() => ({
  rolle: null as string | null,
  signIn: vi.fn(() => Promise.resolve({ error: null as string | null })),
}))
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({
    user: authZustand.rolle ? { id: 'u1', email: 'zz-coach@example.org' } : null,
    role: authZustand.rolle,
    loading: false,
    signIn: authZustand.signIn,
    signOut: vi.fn(),
  }),
}))

import { TokenSeite } from './TokenSeite'
import { PasswortVergessenPage } from './PasswortVergessenPage'
import { MeinKontoPage } from '@/pages/konto/MeinKontoPage'
import { Login } from '@/pages/Login'
import { passwortPruefen } from '@/lib/passwort'

function zeige(pfad: string): void {
  render(
    <MemoryRouter initialEntries={[pfad]}>
      <Routes>
        <Route path="/auth/einladung" element={<TokenSeite art="einladung" />} />
        <Route path="/auth/neues-passwort" element={<TokenSeite art="neuesPasswort" />} />
        <Route path="/auth/bestaetigen" element={<TokenSeite art="bestaetigen" />} />
        <Route path="/auth/passwort-vergessen" element={<PasswortVergessenPage />} />
        <Route path="/konto" element={<MeinKontoPage />} />
        <Route path="/login" element={<Login />} />
        <Route path="/coach" element={<p>Coach-Start</p>} />
        <Route path="/student" element={<p>Schueler-Start</p>} />
      </Routes>
    </MemoryRouter>,
  )
}

function tippe(label: RegExp | string, wert: string): void {
  fireEvent.change(screen.getByLabelText(label), { target: { value: wert } })
}

const GUT = 'vier woerter sind lang genug'

beforeEach(() => {
  vi.clearAllMocks()
  authZustand.rolle = null
})

describe('Einladung annehmen', () => {
  it('loest den Token erst nach dem Klick auf „Weiter“ ein, nie beim Laden', async () => {
    zeige('/auth/einladung?token_hash=zz_hash&type=invite')
    expect(screen.getByRole('heading', { name: 'Willkommen bei Edvance' })).toBeInTheDocument()
    // Laden allein (wie ein Mail-Scanner) verbraucht nichts.
    await new Promise((r) => setTimeout(r, 20))
    expect(sb.auth.verifyOtp).not.toHaveBeenCalled()

    fireEvent.click(screen.getByRole('button', { name: 'Weiter' }))
    await screen.findByRole('heading', { name: 'Passwort festlegen' })
    expect(sb.auth.verifyOtp).toHaveBeenCalledTimes(1)
    expect(sb.auth.verifyOtp).toHaveBeenCalledWith({ token_hash: 'zz_hash', type: 'invite' })
  })

  it('setzt das Passwort und leitet zur Startseite der Rolle', async () => {
    zeige('/auth/einladung?token_hash=zz_hash&type=invite')
    fireEvent.click(screen.getByRole('button', { name: 'Weiter' }))
    await screen.findByRole('heading', { name: 'Passwort festlegen' })
    tippe('Neues Passwort', GUT)
    tippe('Neues Passwort wiederholen', GUT)
    authZustand.rolle = 'coach'
    fireEvent.click(screen.getByRole('button', { name: 'Passwort festlegen' }))
    expect(await screen.findByText('Coach-Start')).toBeInTheDocument()
    expect(sb.auth.updateUser).toHaveBeenCalledWith({ password: GUT })
  })

  it('falscher type oder fehlender Token: keine Einloesung, Hinweis', async () => {
    zeige('/auth/einladung?token_hash=zz_hash&type=recovery')
    expect(screen.getByRole('heading', { name: 'Dieser Link gilt nicht mehr' })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Weiter' })).not.toBeInTheDocument()
    expect(sb.auth.verifyOtp).not.toHaveBeenCalled()
  })

  it('abgelaufener Token: Hinweis statt Passwortformular', async () => {
    sb.auth.verifyOtp.mockResolvedValueOnce({ data: null, error: { code: 'otp_expired', message: 'x' } } as never)
    zeige('/auth/einladung?token_hash=zz_alt&type=invite')
    fireEvent.click(screen.getByRole('button', { name: 'Weiter' }))
    expect(await screen.findByText(/Die Einladung ist abgelaufen/)).toBeInTheDocument()
  })
})

describe('Neues Passwort per Link', () => {
  it('loest erst nach Klick ein, prueft die Regeln vor updateUser', async () => {
    zeige('/auth/neues-passwort?token_hash=zz_r&type=recovery')
    expect(sb.auth.verifyOtp).not.toHaveBeenCalled()
    fireEvent.click(screen.getByRole('button', { name: 'Weiter' }))
    await screen.findByRole('heading', { name: 'Neues Passwort festlegen' })
    expect(sb.auth.verifyOtp).toHaveBeenCalledWith({ token_hash: 'zz_r', type: 'recovery' })

    tippe('Neues Passwort', 'kurz')
    tippe('Neues Passwort wiederholen', 'kurz')
    fireEvent.click(screen.getByRole('button', { name: 'Passwort speichern' }))
    expect(await screen.findByRole('alert')).toHaveTextContent('mindestens 10 Zeichen')

    tippe('Neues Passwort', GUT)
    tippe('Neues Passwort wiederholen', GUT + 'x')
    fireEvent.click(screen.getByRole('button', { name: 'Passwort speichern' }))
    expect(await screen.findByRole('alert')).toHaveTextContent('nicht gleich')
    expect(sb.auth.updateUser).not.toHaveBeenCalled()

    tippe('Neues Passwort wiederholen', GUT)
    fireEvent.click(screen.getByRole('button', { name: 'Passwort speichern' }))
    await screen.findByRole('heading', { name: 'Gespeichert' })
    expect(sb.auth.updateUser).toHaveBeenCalledWith({ password: GUT })
  })
})

describe('Passwortregeln', () => {
  it('nur die Laenge zaehlt, keine Sonderzeichen-Pflicht', () => {
    expect(passwortPruefen('123456789', '123456789')).toBe('zu_kurz')
    expect(passwortPruefen('abcdefghij', 'abcdefghij')).toBeNull()
    expect(passwortPruefen('abcdefghij', 'abcdefghik')).toBe('ungleich')
  })
})

describe('Passwort vergessen', () => {
  const antwort = 'Wenn es ein Konto mit dieser Adresse gibt, ist eine Mail unterwegs.'

  it.each([
    ['Konto vorhanden', () => sb.ok()],
    ['kein Konto', () => sb.ok()],
    ['Fehler von Auth', () => Promise.resolve({ data: null, error: { code: 'over_email_send_rate_limit', status: 429 } })],
    ['Netzfehler', () => Promise.reject(new Error('offline'))],
  ])('antwortet immer gleich (%s)', async (_fall, verhalten) => {
    sb.auth.resetPasswordForEmail.mockImplementationOnce(verhalten as never)
    zeige('/auth/passwort-vergessen')
    tippe('E-Mail', 'zz-wer@example.org')
    fireEvent.click(screen.getByRole('button', { name: 'Link anfordern' }))
    expect(await screen.findByRole('heading', { name: 'Passwort vergessen' })).toBeInTheDocument()
    expect(await screen.findByText(antwort)).toBeInTheDocument()
    expect(sb.auth.resetPasswordForEmail).toHaveBeenCalledWith('zz-wer@example.org', {
      redirectTo: `${window.location.origin}/auth/neues-passwort`,
    })
  })
})

describe('Mein Konto', () => {
  beforeEach(() => {
    authZustand.rolle = 'coach'
  })

  function aendern(alt: string): void {
    tippe('Bisheriges Passwort', alt)
    tippe('Neues Passwort', GUT)
    tippe('Neues Passwort wiederholen', GUT)
    fireEvent.click(screen.getByRole('button', { name: 'Passwort ändern' }))
  }

  it('prueft das alte Passwort vor updateUser und meldet die anderen Sitzungen ab', async () => {
    zeige('/konto')
    aendern('altes passwort')
    expect(await screen.findByRole('status')).toHaveTextContent('Passwort geändert')
    expect(sb.auth.signInWithPassword).toHaveBeenCalledWith({ email: 'zz-coach@example.org', password: 'altes passwort' })
    const anmelden = sb.auth.signInWithPassword.mock.invocationCallOrder[0]
    const setzen = sb.auth.updateUser.mock.invocationCallOrder[0]
    const abmelden = sb.auth.signOut.mock.invocationCallOrder[0]
    expect(anmelden).toBeLessThan(setzen)
    expect(setzen).toBeLessThan(abmelden)
    expect(sb.auth.signOut).toHaveBeenCalledWith({ scope: 'others' })
  })

  it('falsches altes Passwort: kein updateUser', async () => {
    sb.auth.signInWithPassword.mockResolvedValueOnce({
      data: null,
      error: { code: 'invalid_credentials', message: 'Invalid login credentials' },
    } as never)
    zeige('/konto')
    aendern('falsch')
    expect(await screen.findByRole('alert')).toHaveTextContent('Das bisherige Passwort stimmt nicht.')
    expect(sb.auth.updateUser).not.toHaveBeenCalled()
    expect(sb.auth.signOut).not.toHaveBeenCalled()
  })
})

describe('Login (auch Tablet/Kiosk) unveraendert', () => {
  it('meldet mit E-Mail und Passwort an, ohne Mail- oder Token-Aufruf, und hat den Vergessen-Link', async () => {
    zeige('/login')
    tippe('E-Mail', 'platz-3@edvance.invalid')
    tippe('Passwort', 'zugangscode')
    fireEvent.click(screen.getByRole('button', { name: 'Anmelden' }))
    await waitFor(() => expect(authZustand.signIn).toHaveBeenCalledWith('platz-3@edvance.invalid', 'zugangscode'))
    expect(sb.auth.verifyOtp).not.toHaveBeenCalled()
    expect(sb.auth.resetPasswordForEmail).not.toHaveBeenCalled()
    expect(screen.getByRole('link', { name: 'Passwort vergessen?' })).toHaveAttribute('href', '/auth/passwort-vergessen')
  })

  it('angemeldet als Schueler: weiter zur Schueler-Startseite', async () => {
    authZustand.rolle = 'student'
    zeige('/login')
    expect(await screen.findByText('Schueler-Start')).toBeInTheDocument()
  })
})
