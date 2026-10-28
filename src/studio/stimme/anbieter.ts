/**
 * Stimm-Anbieter für die Server-Route api/studio/stimme.ts (Anforderung Studio §5). Ohne Pfad-Alias,
 * weil die Vercel Function diese Datei direkt bündelt. Der ElevenLabs-Schlüssel kommt nur als Argument
 * aus der Server-Umgebung und erscheint nie in Fehlermeldungen.
 */

export type Vertonung = {
  audio: Uint8Array
  /** audio/mpeg oder audio/wav */
  mime: string
  endung: 'mp3' | 'wav'
  dauerMs: number
  /** Zeitstempel je Zeichen (ElevenLabs „with timestamps“); leer beim Platzhalter. */
  zeitstempel: Record<string, unknown>
}

export type Satzauftrag = { satz: string; davor: string | null; danach: string | null }

/** Geschätzte Sprechdauer für den Platzhalter: ruhiges Tempo, mindestens 0,8 s. */
export function platzhalterDauerMs(satz: string): number {
  return Math.max(800, Math.round(400 + satz.length * 65))
}

/** Stumme WAV-Datei (PCM 16 bit mono) der gewünschten Länge. */
export function stummeWav(dauerMs: number, abtastrate = 16000): Uint8Array {
  const proben = Math.round((dauerMs / 1000) * abtastrate)
  const daten = proben * 2
  const buf = new ArrayBuffer(44 + daten)
  const v = new DataView(buf)
  const text = (o: number, s: string) => [...s].forEach((c, i) => v.setUint8(o + i, c.charCodeAt(0)))
  text(0, 'RIFF')
  v.setUint32(4, 36 + daten, true)
  text(8, 'WAVE')
  text(12, 'fmt ')
  v.setUint32(16, 16, true)
  v.setUint16(20, 1, true)
  v.setUint16(22, 1, true)
  v.setUint32(24, abtastrate, true)
  v.setUint32(28, abtastrate * 2, true)
  v.setUint16(32, 2, true)
  v.setUint16(34, 16, true)
  text(36, 'data')
  v.setUint32(40, daten, true)
  return new Uint8Array(buf)
}

/** Länge einer WAV-Datei in Millisekunden aus dem Kopf (für Tests und Prüfungen). */
export function wavDauerMs(wav: Uint8Array): number {
  const v = new DataView(wav.buffer, wav.byteOffset, wav.byteLength)
  return Math.round((v.getUint32(40, true) / v.getUint32(28, true)) * 1000)
}

export function platzhalterVertonen(a: Satzauftrag): Vertonung {
  const dauerMs = platzhalterDauerMs(a.satz)
  return { audio: stummeWav(dauerMs), mime: 'audio/wav', endung: 'wav', dauerMs, zeitstempel: {} }
}

type ElevenAntwort = {
  audio_base64?: string
  alignment?: { characters: string[]; character_start_times_seconds: number[]; character_end_times_seconds: number[] }
}

/** Antwort von „text-to-speech/{voice}/with-timestamps“ auslesen. */
export function elevenAuslesen(antwort: ElevenAntwort): Vertonung {
  if (!antwort.audio_base64) throw new Error('elevenlabs: Antwort ohne Audio')
  const bin = atob(antwort.audio_base64)
  const audio = Uint8Array.from(bin, (c) => c.charCodeAt(0))
  const ende = antwort.alignment?.character_end_times_seconds ?? []
  const dauerMs = Math.max(1, Math.round((ende.length ? ende[ende.length - 1] : 0) * 1000))
  return { audio, mime: 'audio/mpeg', endung: 'mp3', dauerMs, zeitstempel: antwort.alignment ?? {} }
}

export async function elevenVertonen(
  a: Satzauftrag,
  opt: { schluessel: string; stimme: string; modell: string; abruf?: typeof fetch },
): Promise<Vertonung> {
  const abruf = opt.abruf ?? fetch
  const res = await abruf(
    `https://api.elevenlabs.io/v1/text-to-speech/${encodeURIComponent(opt.stimme)}/with-timestamps?output_format=mp3_44100_128`,
    {
      method: 'POST',
      headers: { 'xi-api-key': opt.schluessel, 'content-type': 'application/json' },
      body: JSON.stringify({
        text: a.satz,
        model_id: opt.modell,
        language_code: 'de',
        ...(a.davor ? { previous_text: a.davor } : {}),
        ...(a.danach ? { next_text: a.danach } : {}),
      }),
    },
  )
  if (!res.ok) throw new Error(`elevenlabs: HTTP ${res.status}`)
  return elevenAuslesen((await res.json()) as ElevenAntwort)
}
