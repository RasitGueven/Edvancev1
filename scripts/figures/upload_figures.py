#!/usr/bin/env python3
"""Generierte Abbildungen erzeugen, pruefen, hochladen und in task_figures stempeln.

    python3 scripts/figures/upload_figures.py [--dry-run]

WIRD VON RASIT AUSGEFUEHRT, NICHT VON CLAUDE. Kein Upload im PR, keine
Credentials im Repo. Alle Zugaenge kommen aus der Umgebung:

    DATABASE_URL          Postgres (Lesen/Schreiben task_figures)
    SUPABASE_URL          z.B. https://<ref>.supabase.co
    SUPABASE_SERVICE_KEY  service_role-Key (Storage-Upload)

ABHAENGIGKEIT (offenes Loch, im PR benannt): die Generatoren aus PR #96
(scripts/figures/koordinatensystem.py, pruefe_koordinatensystem.py) liegen zum
Zeitpunkt dieses PRs NOCH NICHT im Repo. Dieses Skript importiert sie ueber die
unten dokumentierte, DUENNE Adapterschicht (zeichne / pruefe). Weicht die
tatsaechliche #96-Signatur ab, sind es genau diese zwei Funktionen, die man
anpasst — sonst nichts.

WAS ES TUT:
  - liest task_figures-Zeilen, die noch KEINEN svg_hash tragen ODER deren
    aktueller Parameter-Hash vom gespeicherten abweicht (Regenerierung),
  - erzeugt je Zeile ZWEI SVGs (theme='dunkel' und 'hell'),
  - prueft JEDES SVG, BEVOR irgendetwas hochgeladen wird — faellt die Pruefung,
    wird fuer diese Zeile nichts geladen und nichts geschrieben (ein falsches
    Bild ist schlimmer als kein Bild),
  - laedt nach generiert/<task_id>/<generator>-{dunkel,hell}.svg,
  - schreibt svg_hash + erzeugt_am zurueck,
  - --dry-run: alles ausser Upload und DB-Schreiben.

IDEMPOTENZ: svg_hash = sha256 ueber generator + kanonische params. Gleiche
Parameter -> gleicher Hash -> nichts zu tun. (Eine reine Generator-CODE-Aenderung
ohne Parameteraenderung wird so NICHT erkannt — dann per --force neu laden;
bewusste Grenze, im PR vermerkt.)
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from pathlib import Path

WURZEL = Path(__file__).resolve().parents[2]
BUCKET = "task-assets"
THEMES = ("dunkel", "hell")

# ── Adapter auf die #96-Generatoren (die EINZIGE Stelle, die #96 kennt) ──────
#
# Erwartete Schnittstelle (bei Abweichung hier anpassen):
#   koordinatensystem.zeichne(params: dict, theme: str) -> str            (SVG)
#   pruefe_koordinatensystem.pruefe(svg: str, params: dict) -> tuple[bool, str]


def _lade_generator(name: str):
    sys.path.insert(0, str(WURZEL / "scripts" / "figures"))
    if name == "koordinatensystem":
        import koordinatensystem  # type: ignore
        import pruefe_koordinatensystem  # type: ignore

        return koordinatensystem.zeichne, pruefe_koordinatensystem.pruefe
    raise SystemExit(f"Unbekannter Generator '{name}' — kein Adapter (Positivliste in der Migration).")


# ── Hash / Umgebung ──────────────────────────────────────────────────────────


def params_hash(generator: str, params: dict) -> str:
    roh = generator + "\n" + json.dumps(params, sort_keys=True, ensure_ascii=False)
    return hashlib.sha256(roh.encode("utf-8")).hexdigest()


def env(name: str) -> str:
    v = os.environ.get(name)
    if not v:
        raise SystemExit(f"Umgebungsvariable {name} fehlt.")
    return v


# ── DB (psycopg2) ────────────────────────────────────────────────────────────


def _connect():
    try:
        import psycopg2  # type: ignore
    except ImportError as e:
        raise SystemExit("psycopg2 wird benoetigt (pip install psycopg2-binary).") from e
    return psycopg2.connect(env("DATABASE_URL"))


def lade_offene(conn) -> list[dict]:
    with conn.cursor() as cur:
        cur.execute(
            "select task_id, generator, params, alt_text, svg_hash from task_figures"
        )
        return [
            {
                "task_id": str(r[0]),
                "generator": r[1],
                "params": r[2],
                "alt_text": r[3],
                "svg_hash": r[4],
            }
            for r in cur.fetchall()
        ]


def stempel(conn, task_id: str, svg_hash: str) -> None:
    with conn.cursor() as cur:
        cur.execute(
            "update task_figures set svg_hash=%s, erzeugt_am=now() where task_id=%s",
            (svg_hash, task_id),
        )
    conn.commit()


# ── Storage-Upload (REST, service_role) ──────────────────────────────────────


def upload(pfad: str, svg: str) -> None:
    import urllib.request

    url = f"{env('SUPABASE_URL')}/storage/v1/object/{BUCKET}/{pfad}"
    req = urllib.request.Request(
        url,
        data=svg.encode("utf-8"),
        method="POST",
        headers={
            "Authorization": f"Bearer {env('SUPABASE_SERVICE_KEY')}",
            "Content-Type": "image/svg+xml",
            "x-upsert": "true",  # Regenerierung ueberschreibt
        },
    )
    with urllib.request.urlopen(req) as resp:  # noqa: S310 (bewusste, feste Host-URL)
        if resp.status not in (200, 201):
            raise SystemExit(f"Upload {pfad} fehlgeschlagen: HTTP {resp.status}")


# ── Ablauf ───────────────────────────────────────────────────────────────────


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true",
                    help="alles ausser Upload und DB-Schreiben")
    ap.add_argument("--force", action="store_true",
                    help="neu laden, auch wenn der Parameter-Hash unveraendert ist")
    args = ap.parse_args()

    conn = _connect()
    zeilen = lade_offene(conn)

    geladen = uebersprungen = fehler = 0
    for z in zeilen:
        h = params_hash(z["generator"], z["params"])
        if z["svg_hash"] == h and not args.force:
            uebersprungen += 1
            continue

        zeichne, pruefe = _lade_generator(z["generator"])

        # Erst BEIDE Themes erzeugen UND pruefen, dann erst hochladen.
        svgs: dict[str, str] = {}
        ok = True
        for theme in THEMES:
            svg = zeichne(z["params"], theme)
            bestanden, meldung = pruefe(svg, z["params"])
            if not bestanden:
                print(f"  FEHLER {z['task_id']} [{theme}]: {meldung} — nichts hochgeladen")
                ok = False
                break
            svgs[theme] = svg
        if not ok:
            fehler += 1
            continue

        for theme, svg in svgs.items():
            pfad = f"generiert/{z['task_id']}/{z['generator']}-{theme}.svg"
            if args.dry_run:
                print(f"  [dry-run] wuerde laden: {pfad} ({len(svg)} B)")
            else:
                upload(pfad, svg)

        if args.dry_run:
            print(f"  [dry-run] wuerde svg_hash setzen: {z['task_id']} -> {h[:12]}")
        else:
            stempel(conn, z["task_id"], h)
        geladen += 1

    print(f"\ngeladen={geladen} uebersprungen={uebersprungen} fehler={fehler}"
          + (" (dry-run)" if args.dry_run else ""))
    if fehler:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
