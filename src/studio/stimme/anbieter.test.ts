import { describe, expect, it, vi } from 'vitest'
import { elevenAuslesen, elevenVertonen, platzhalterVertonen, stummeWav, wavDauerMs } from './anbieter'

describe('Stimm-Anbieter', () => {
  it('Platzhalter: stumme WAV passender Länge', () => {
    const v = platzhalterVertonen({ satz: 'Stell dir ein Quadrat aus neunundvierzig kleinen Kästchen vor.', davor: null, danach: null })
    expect(v.mime).toBe('audio/wav')
    expect(wavDauerMs(v.audio)).toBe(v.dauerMs)
    expect(v.dauerMs).toBeGreaterThan(3000)
    expect(stummeWav(1000).slice(44).every((b) => b === 0)).toBe(true)
  })

  it('ElevenLabs: Dauer aus dem letzten Zeitstempel', () => {
    const v = elevenAuslesen({
      audio_base64: btoa('ID3'),
      alignment: { characters: ['a', 'b'], character_start_times_seconds: [0, 0.4], character_end_times_seconds: [0.4, 1.234] },
    })
    expect(v.dauerMs).toBe(1234)
    expect(new TextDecoder().decode(v.audio)).toBe('ID3')
  })

  it('ElevenLabs: Kontext davor und danach, Schlüssel nie in der Fehlermeldung', async () => {
    const abruf = vi.fn().mockResolvedValue(new Response('nein', { status: 401 }))
    await expect(
      elevenVertonen({ satz: 'Mitte.', davor: 'Davor.', danach: 'Danach.' }, { schluessel: 'GEHEIM', stimme: 'v1', modell: 'm', abruf }),
    ).rejects.toThrow(/^elevenlabs: HTTP 401$/)
    const [, init] = abruf.mock.calls[0] as [string, RequestInit]
    expect(JSON.parse(init.body as string)).toMatchObject({ text: 'Mitte.', previous_text: 'Davor.', next_text: 'Danach.', model_id: 'm' })
  })
})
