"""Parser der Didaktischen Kommentierung -> Merkmale je Teilaufgabe + Fehler.

Quelle: je Teilaufgabe eine Tabelle mit den Zeilen Leitidee / Allgemeine
Kompetenz / Anforderungsbereich / Kompetenzstufe. Danach ein Absatzblock
'Folgende Schwierigkeiten und Fehler sind zu erwarten:' mit den typischen
Fehlern - woertlich, inklusive '[Fehlloesung: 400 m]'.

Es wird nichts abgeleitet, was nicht dasteht: AFB und K-Tags kommen aus den
Tabellenzellen, typische Fehler aus den Absaetzen.
"""
import re

from c02_docparse import blocks, norm_ws

LEITIDEE = re.compile(r"^Leitidee", re.I)
KOMPETENZ = re.compile(r"^Allgemeine\s*Kompetenz", re.I)
AFB = re.compile(r"^Anforderungsbereich", re.I)
STUFE = re.compile(r"^Kompetenzstufe", re.I)

K_TAG = re.compile(r"\(K\s?(\d)\)")
ROMAN = {"I": 1, "II": 2, "III": 3}

# Zwei Formatgenerationen der Handreichung benennen den Fehlerblock verschieden.
FEHLER_START = re.compile(
    r"Folgende\s+(Schwierigkeiten\s+und\s+Fehler|Fehler\s+und\s+Schwierigkeiten)"
    r"|^Mögliche\s+Schwierigkeiten\s*$", re.I)
FEHLER_ENDE = re.compile(
    r"^(Anregungen|Literatur|Quellen|Mögliche\s+Weiterführung|Hinweise\s+zur)", re.I)
# Zwischenueberschrift innerhalb des Fehlerblocks - kein Fehler, nur Gliederung.
FEHLER_UEBERSCHRIFT = re.compile(r"^(Zu\s+)?Teilaufgabe\s*\d+\s*:?$", re.I)


def _row_label(row):
    return norm_ws(row[0]).replace("\n", "") if row else ""


def _row_value(row):
    return norm_ws(" ".join(row[1:])) if len(row) > 1 else ""


def _merkmale(table):
    """Eine 'Merkmale der Teilaufgabe'-Tabelle -> Dict. None wenn keine."""
    fields = {}
    for row in table:
        label, value = _row_label(row), _row_value(row)
        if LEITIDEE.match(label):
            fields["leitidee_raw"] = value
        elif KOMPETENZ.match(label):
            fields["kompetenz_raw"] = value
            fields["k_tags"] = ["K%s" % k for k in K_TAG.findall(value)]
        elif AFB.match(label):
            fields["afb_raw"] = value
            fields["afb"] = ROMAN.get(value.strip().upper())
        elif STUFE.match(label):
            fields["kompetenzstufe_raw"] = value
    return fields if "leitidee_raw" in fields else None


def _fehler(paras):
    """Verbatim-Absaetze des Fehlerblocks."""
    out, aktiv = [], False
    for text in paras:
        if FEHLER_START.search(text):
            aktiv = True
            continue
        if aktiv and FEHLER_ENDE.match(text):
            break
        if aktiv and FEHLER_UEBERSCHRIFT.match(text.strip()):
            continue
        if aktiv and len(text) > 15:
            out.append(norm_ws(text))
    return out


def parse(path):
    """{'teilaufgaben': [merkmale...], 'typische_fehler': [...], 'quelle': name}"""
    if not path:
        return {"teilaufgaben": [], "typische_fehler": [], "quelle": None}
    tas, paras = [], []
    for kind, payload in blocks(path):
        if kind == "para":
            paras.append(payload)
            continue
        merkmale = _merkmale(payload)
        if merkmale:
            merkmale["nr"] = len(tas) + 1
            tas.append(merkmale)
    return {
        "teilaufgaben": tas,
        "typische_fehler": _fehler(paras),
        "quelle": path.split("/")[-1],
    }
