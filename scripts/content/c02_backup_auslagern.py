"""C02 - die fabrizierten Altfelder aus dem Pool in eine Audit-Datei auslagern.

Phase 0 hat die KI-erfundenen Inhaltsfelder nach `_fabriziert_backup` im Item
verschoben. Als Beweisstueck sind sie wertvoll, im Produktionsdatensatz haben
sie nichts verloren - sie verdoppeln die Datei und stehen neben genau den
Feldern, die sie ersetzen sollten.

Einmalig auszufuehren; danach ist der Pool schlank und die Altdaten liegen in
data/c02_fabriziert_backup.json.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from vera_lib import load_items, save_items  # noqa: E402

BACKUP = "data/c02_fabriziert_backup.json"

items = load_items()
ausgelagert = {}
for item in items:
    daten = item.pop("_fabriziert_backup", None)
    if daten:
        ausgelagert[item["titel"]] = daten

if ausgelagert:
    json.dump(ausgelagert, open(BACKUP, "w"), ensure_ascii=False, indent=1)
save_items(items)

print("Items                  : %d" % len(items))
print("Backups ausgelagert    : %d -> %s" % (len(ausgelagert), BACKUP))
print("Pool-Groesse           : %.1f MB" % (os.path.getsize("data/vera8_komplett_enriched.json") / 1e6))
print("Backup-Groesse         : %.1f MB" % (os.path.getsize(BACKUP) / 1e6 if ausgelagert else 0))
