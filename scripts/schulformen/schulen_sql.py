"""SF-1 · S1: Datenmigration der Realschulen, Gesamtschulen und Sekundarschulen aus dem Schulverzeichnis NRW.

Quelle: docs/schulformen/sf1/quellen/schulverzeichnis-auszug.csv (Auszug aus
https://www.schulministerium.nrw.de/BiPo/OpenData/Schuldaten/schuldaten.csv, abgerufen 13.11.2026).
Der Anzeigename steht hier ausgeschrieben je Schulnummer (die amtliche Bezeichnung ist auf drei Felder verteilt
und beginnt teils mit „Stadt Köln“ oder „Städt.“). Alles andere kommt unverändert aus dem Auszug.

    python3 scripts/schulformen/schulen_sql.py <version> > supabase/migrations/<version>_sf1_schulen.sql
"""
import csv
import sys
from pathlib import Path

AUSZUG = Path(__file__).resolve().parents[2] / "docs/schulformen/sf1/quellen/schulverzeichnis-auszug.csv"
SCHULFORM = {"10": "Realschule", "14": "Sekundarschule", "15": "Gesamtschule"}
TRAEGER = {"1": "öffentlich", "2": "privat"}
ORT = {"05315000": "Köln", "05362032": "Kerpen"}

NAME = {
    # Realschulen Köln
    "160064": "Henry-Ford-Realschule",
    "160076": "Geschwister-Scholl-Schule",
    "160090": "Ferdinand-Lassalle-Realschule",
    "160106": "Elly-Heuss-Knapp-Realschule",
    "160118": "Realschule Im Hasental",
    "160120": "Edith-Stein-Realschule",
    "160131": "Peter-Ustinov-Schule",
    "160155": "Erzbischöfliche Ursulinenschule Köln (Realschule)",
    "160179": "Theodor-Heuss-Schule",
    "160180": "Johann-Bendel-Schule",
    "160192": "Albert-Schweitzer-Schule",
    "160209": "Käthe-Kollwitz-Schule",
    "160210": "Bertha-von-Suttner-Schule",
    "160222": "Eichendorff-Schule",
    "160260": "Realschule am Rhein",
    "160430": "Johannes-Gutenberg-Schule",
    "160568": "Wilhelm-Busch-Realschule",
    "160570": "Max-Planck-Realschule",
    "160581": "Otto-Lilienthal-Schule",
    "197567": "Werner Heisenberg Realschule",
    # Gesamtschulen Köln
    "100036": "Gesamtschule Helios",
    "100041": "Gesamtschule Wasseramselweg",
    "100068": "Gesamtschule Berrenrather Straße",
    "100071": "Gesamtschule Dellbrücker Mauspfad",
    "100169": "Freie Naturschulen Köln, Gesamtschule",
    "100208": "Sieben Brücken Schule",
    "100210": "Gesamtschule Am Wassermann",
    "100211": "Ernst-Simons-Gesamtschule",
    "100212": "Gesamtschule Ossendorf",
    "100219": "Erzbischöfliche Gesamtschule am Bildungscampus Köln-Kalk",
    "100235": "Gesamtschule Kalk",
    "164161": "Gesamtschule Köln-Rodenkirchen",
    "183726": "Gesamtschule Köln-Holweide",
    "184287": "Heinrich-Böll-Schule",
    "184913": "Lise-Meitner-Gesamtschule",
    "184937": "Willy-Brandt-Gesamtschule",
    "185176": "Europaschule Köln, Gesamtschule Zollstock",
    "187902": "Max-Ernst-Gesamtschule",
    "188165": "Katharina-Henoth-Schule",
    "193021": "Freie Schule Köln, Gesamtschule",
    "195959": "Carl-von-Ossietzky-Gesamtschule",
    "196459": "BilinGO Campus Gesamtschule",
    "197488": "Offene Schule Köln",
    "198742": "Trude-Herr-Gesamtschule",
    "198912": "igis Köln, Integrierte Gesamtschule Innenstadt",
    # Gesamtschule Kerpen
    # Ort im Namen: In Köln gibt es eine gleichnamige Schule (184937); lsa_schule_von_sitzung sucht den
    # Freitext ohne Ort und braucht einen eindeutigen Treffer.
    "191942": "Willy-Brandt-Gesamtschule Kerpen",
}


def q(v: str | None) -> str:
    return "null" if v in (None, "") else "'" + v.replace("'", "''") + "'"


def main() -> None:
    version = sys.argv[1]
    rows = list(csv.DictReader(AUSZUG.open(encoding="utf-8"), delimiter=";"))
    nummern = {r["Schulnummer"] for r in rows}
    if nummern != set(NAME):
        sys.exit(f"Namensliste passt nicht zum Auszug: {sorted(nummern ^ set(NAME))}")
    werte = []
    for r in rows:
        if r["Schulbetriebsschluessel"] != "1":
            sys.exit(f"{r['Schulnummer']}: Schulbetriebsschlüssel {r['Schulbetriebsschluessel']}")
        werte.append(
            f"  ({q(r['Schulnummer'])}, {q(NAME[r['Schulnummer']])}, {q(ORT[r['Gemeindeschluessel']])}, "
            f"{q(SCHULFORM[r['Schulform']])}, {q(TRAEGER[r['Rechtsform']])}, {q(r['Homepage'])})"
        )
    print(f"""-- ============================================================================
-- SF-1 · S1 Daten: Realschulen, Gesamtschulen und Sekundarschulen in Köln, Gesamtschulen in Kerpen
-- ============================================================================
-- Erzeugt von scripts/schulformen/schulen_sql.py — nicht von Hand ändern.
-- Fundstelle: Schulverzeichnis NRW (Open Data des MSB),
--   https://www.schulministerium.nrw.de/BiPo/OpenData/Schuldaten/schuldaten.csv, abgerufen 13.11.2026 08:22 UTC,
--   SHA-256 8732daec4f1b67df090280fa415407858a251449ddbfaa010a378df116502c59.
--   Auszug: docs/schulformen/sf1/quellen/schulverzeichnis-auszug.csv (Schulform 10/14/15, Gemeinde Köln 05315000;
--   Schulform 15, Gemeinde Kerpen 05362032). Köln: {sum(r['Schulform'] == '10' for r in rows)} Realschulen, \
{sum(r['Schulform'] == '15' and r['Gemeindeschluessel'] == '05315000' for r in rows)} Gesamtschulen, keine Sekundarschule;
--   Kerpen: {sum(r['Gemeindeschluessel'] == '05362032' for r in rows)} Gesamtschule. Alle mit Schulbetriebsschlüssel 1.
-- Felder wie bei den Gymnasien (20261001125708): name, ort, schulform, traeger, website; stadtteil steht nicht im
-- Verzeichnis und bleibt leer. Neu: schulnummer. Eine Schule, deren Schulnummer schon da ist, wird übersprungen;
-- ein Namensgleicher am selben Ort ebenfalls (die Prüfabfrage zählt die Schulnummern nach).
-- Rollback: supabase/rollback/{version}_sf1_schulen.sql

insert into public.schulen (schulnummer, name, ort, schulform, traeger, website)
select v.schulnummer, v.name, v.ort, v.schulform, v.traeger, v.website
  from (values
{(','+chr(10)).join(werte)}
  ) as v (schulnummer, name, ort, schulform, traeger, website)
 where not exists (select 1 from public.schulen s where s.schulnummer = v.schulnummer)
on conflict do nothing;""")


if __name__ == "__main__":
    main()
