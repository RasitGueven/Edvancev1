"""Parser der IQB-Auswertungsdateien -> belegte Loesungen je Teilaufgabe.

Struktur der Quelle: Absatz 'Teilaufgabe N' leitet eine Tabelle ein, deren
Zeilen [Code, Inhalt] sind. Code ist RICHTIG / FALSCH / aehnliches.

Harte Regel: Jede abgeleitete Antwort muss WOERTLICH in ihrer Quellzelle
stehen. Was der Text nicht hergibt, wird nicht ergaenzt. Die Pruefung
`_verbatim` erzwingt das maschinell - sie ist der Kern des Groundings.
"""
import re

from c02_docparse import blocks, norm_ws

TEILAUFGABE = re.compile(r"^Teilaufgabe\s*(\d+)", re.I)
RICHTIG = re.compile(r"^\s*RICHTIG", re.I)
FALSCH = re.compile(r"^\s*FALSCH", re.I)

# Antwortvarianten, die die Quelle ausdruecklich nennt.
AUCH = re.compile(
    r"\bauch\s+(?:die\s+(?:Antwort|Angabe|Loesung|Lösung)\s+)?"
    r"([^.,;()]+?)\s*(?:wird\s+akzeptiert|werden\s+akzeptiert|\)|,|;|\.|$)", re.I)
# Dezimalkomma schuetzen: nur an Komma+Leerzeichen trennen ('0,016 km, 160 dm').
ZB = re.compile(r"z\.\s?B\.\s*:?\s*([^\[\]]+?)(?:\)|\]|$)", re.I)
ZB_SPLIT = re.compile(r",\s+|\s+oder\s+", re.I)
ODER = re.compile(r"\bODER\b")
# 'ODER' auf eigener Zeile trennt gleichwertige Musterloesungen.
ODER_ZEILE = re.compile(r"(?mi)^[\s•]*ODER[\s.]*$")
# 'UND' auf eigener Zeile bzw. eine geforderte Begruendung: die Antwort besteht
# aus Wahl + Freitext und ist nicht automatisch korrigierbar.
UND_ZEILE = re.compile(r"(?mi)^[\s•]*UND[\s.]*$")
BEGRUENDUNG = re.compile(r"Begründung|nachvollziehbarer Rechenweg|begründe", re.I)
INTERVALL = re.compile(r"Intervall\s*\[[^\]]+\]")

# Freitext-Loesung: lange, satzartige Antworten sind nicht auto-korrigierbar.
MAX_ANTWORT_LEN = 60
MAX_VARIANTE_LEN = 30


def _verbatim(candidate, source):
    """Steht die Antwort so (bis auf Whitespace) in der Quelle?"""
    a = re.sub(r"\s+", "", candidate).lower()
    b = re.sub(r"\s+", "", source).lower()
    return bool(a) and a in b


def _is_freitext(line):
    words = line.split()
    return len(line) > MAX_ANTWORT_LEN or (len(words) > 8 and line.rstrip().endswith("."))


def _variants(cell, primary):
    """Ausdruecklich genannte Alternativantworten aus einer RICHTIG-Zelle.

    Nur wenn die Musterloesung selbst eine Zahl enthaelt, zaehlen 'auch ...'-
    und 'z. B. ...'-Listen als gleichwertige *Werte*. Steht dort ein Wort
    ('Nein', 'Saarland'), zaehlen sie Loesungs*wege* auf ('z. B. Dreisatz') -
    das sind keine Antworten.
    """
    if not re.search(r"\d", primary):
        return []
    out = []
    for match in AUCH.finditer(cell):
        # 'Auch "1 Million" oder "1 Mio." wird akzeptiert' nennt zwei Varianten.
        out += [t.strip() for t in ZB_SPLIT.split(match.group(1))]
    for match in ZB.finditer(cell):
        out += [t.strip() for t in ZB_SPLIT.split(match.group(1))]
    out = [v.strip(" .;\"„“") for v in out]
    return [v for v in out
            if v and len(v) <= MAX_VARIANTE_LEN and re.search(r"\d", v)]


def _primary(cell):
    """Erste Zeile der RICHTIG-Zelle = die Musterloesung."""
    for line in cell.split("\n"):
        line = line.strip()
        if line:
            return line
    return ""


def _clean(answer):
    answer = re.sub(r"\s*\([^)]*\)\s*$", "", answer).strip(" .;:")
    return re.sub(r"\s+", " ", answer)


def _teilaufgabe(rows, quelle):
    """Ein TA-Block -> {loesung, kodierung, akzeptierte_antworten, typische_fehler}."""
    richtig = [r[1] for r in rows if len(r) > 1 and RICHTIG.match(r[0])]
    falsch = [r[1] for r in rows if len(r) > 1 and FALSCH.match(r[0])]
    if not richtig:
        return None

    cell = norm_ws(richtig[0])
    primary = _primary(cell)
    result = {
        "loesung": primary,
        "kodierung": cell,
        "typische_fehler": norm_ws(falsch[0]) if falsch else "",
        "akzeptierte_antworten": [],
        "_problems": [],
        "_grounding": {"quelle": quelle, "zitat": cell[:400]},
    }

    # 'ODER' auf eigener Zeile trennt gleichwertige Loesungen; bleibt danach
    # nichts uebrig, stand die Loesung nur als Grafik in der Zelle.
    segmente = [_primary(seg) for seg in ODER_ZEILE.split(cell)]
    segmente = [s for s in segmente if s]
    if not segmente:
        result["_problems"].append("auswertung_zelle_leer")
        return result

    if UND_ZEILE.search(cell) or BEGRUENDUNG.search(cell):
        result["_problems"].append("antwort_erfordert_begruendung")
        return result
    if _is_freitext(primary):
        result["_problems"].append("loesung_ist_freitext")
        return result

    kandidaten = [_clean(s) for s in segmente if not _is_freitext(s)]
    kandidaten += [_clean(v) for v in _variants(cell, primary)]
    for weitere in richtig[1:]:  # eigene RICHTIG-Zeile: gleichwertige Loesung
        alt = ODER.sub("", _primary(norm_ws(weitere))).strip()
        if alt and not _is_freitext(alt):
            kandidaten.append(_clean(alt))

    quelle_gesamt = " ".join(norm_ws(r) for r in richtig)
    seen, answers = set(), []
    for kandidat in kandidaten:
        if not kandidat or kandidat.lower() in seen:
            continue
        if kandidat.endswith(":"):
            continue  # Ueberschrift eines Loesungswegs ('Iterativ:'), keine Antwort
        if not _verbatim(kandidat, quelle_gesamt):
            result["_problems"].append("verworfen_nicht_woertlich:%s" % kandidat[:30])
            continue
        seen.add(kandidat.lower())
        answers.append(kandidat)

    result["akzeptierte_antworten"] = answers
    if INTERVALL.search(cell):
        result["_problems"].append("loesung_ist_intervall")
    # Satz-Erkennung an Woertern, nicht an Tokens: '700 000 000 000' ist eine Zahl.
    if any(len(re.findall(r"[A-Za-zÄÖÜäöüß]{2,}", a)) > 2 for a in answers):
        result["_problems"].append("antwort_ist_satz")
    if not answers:
        result["_problems"].append("auswertung_ohne_konkrete_loesung")
    return result


def parse(path):
    """[TA-Dict] in Reihenfolge der Teilaufgaben. Leer, wenn nichts belegbar."""
    if not path:
        return []
    quelle = path.split("/")[-1]
    tas, current, pending = [], None, []
    for kind, payload in blocks(path):
        if kind == "para":
            match = TEILAUFGABE.match(payload)
            if match:
                current = int(match.group(1))
            continue
        parsed = _teilaufgabe(payload, quelle)
        if parsed is None:
            continue
        parsed["nr"] = current if current is not None else len(pending) + 1
        pending.append(parsed)

    # Mehrere Tabellen derselben Teilaufgabe (RICHTIG/ODER/FALSCH getrennt)
    for ta in pending:
        vorhanden = next((t for t in tas if t["nr"] == ta["nr"]), None)
        if vorhanden is None:
            tas.append(ta)
        else:
            vorhanden["akzeptierte_antworten"] += [
                a for a in ta["akzeptierte_antworten"]
                if a not in vorhanden["akzeptierte_antworten"]]
            vorhanden["_problems"] += ta["_problems"]

    # Eine Verweigerung setzt sich durch: Zusatztabellen ('zu Teilaufgabe 2')
    # beschreiben Loesungswege und duerfen die Ablehnung nicht ueberstimmen.
    for ta in tas:
        if {"antwort_erfordert_begruendung", "loesung_ist_freitext"} & set(ta["_problems"]):
            ta["akzeptierte_antworten"] = []
    return sorted(tas, key=lambda t: t["nr"])
