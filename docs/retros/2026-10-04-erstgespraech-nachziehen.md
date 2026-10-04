# Retro 2026-10-04 – Erstgespräch nachziehen (W5-c)

## Gebaut
- RPC `lead_thema_setzen`: das aktuelle Thema eines Leads atomar setzen, ersetzen oder
  entfernen (nur Admin). `themen.ts` ruft nur noch sie auf.
- Terminbestätigung an die Eltern: neuer Anlass `terminbestaetigung` in `mail_senden`
  (`termin.ts`), Protokoll `lead_mail_versand` + `lead_mail_protokollieren`, Modal mit
  Vorschau an der Lead-Karte („Termin vereinbart“ → Menü).
- Belege: pgTAP 12/12 (lokal mit pgTAP aus dem Debian-Paket), Prüfskript in der
  Wegwerf-DB grün (schreibend und read-only), Deno 4/4 mit gestubbtem Graph, Vitest grün,
  Schema-Abzug aus der Wegwerf-DB (nur Zusätze).

## Entscheidungen
Siehe `docs/intake/erstgespraech-nachziehen.md`.

## Nachtrag (nach dem Einspielen)
- Kein fester Standort: Der Ort ist jetzt Pflichtfeld im Versand-Dialog und wird mit dem
  Termin protokolliert (`lead_mail_versand.ort`, Migration `20261004003339`). Die
  Standortvorlage ist entfallen. Die Dauer hat den Wortlaut von Rasit.

## Offen
- `20261004003339` einspielen, dann `mail_senden` deployen.
- „Thema entfernen“ kann die DB, die Oberfläche bietet es nicht an.

## Gelernt
- pgTAP lässt sich ohne Root lokal nutzen: `apt-get download postgresql-18-pgtap`, das
  Extension-SQL mit `search_path=extensions,public` direkt in die Wegwerf-DB laden und
  im Test die `create extension`-Zeile ersetzen.
- `npx deno@2 check` / `deno test` laufen ohne Installation und prüfen die Edge Function.
