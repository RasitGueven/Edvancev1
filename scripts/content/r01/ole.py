"""EMF-Extraktion aus Word-97-Binaerdateien (.doc).

74 der 299 VERA-Items liegen nur als .doc vor. Der Altbestand hat sie deshalb
gar nicht erst angefasst (status 'doc_pending'). Ihr Aufgabentext steckt — wie
bei den .docx — in EMF-Vektorgrafiken; antiword sieht dort nur "[pic]".

Der Weg dorthin, ohne externe Abhaengigkeit:

  .doc = CFB/OLE-Compound-Datei  ->  Stream "Data"  ->  Escher-Records
       ->  msofbtBlip_EMF (0xF01A)  ->  deflate  ->  EMF

Warum ein eigener CFB-Reader: Ein CFB-Stream liegt NICHT am Stueck in der Datei,
sondern in 512-Byte-Sektoren, die ueber die FAT verkettet sind. Wer im Rohbytes-
strom nach der EMF-Signatur sucht, findet nichts — die Signatur selbst kann an
einer Sektorgrenze zerrissen sein. Erst der zusammengesetzte Stream ist lesbar.
"""
import struct
import zlib
from pathlib import Path

FREE = 0xFFFFFFFA  # ab hier: Sonderwerte (ENDOFCHAIN, FATSECT, ...)
MAGIC = b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1"


def streams(data):
    """CFB-Datei -> {Streamname: Bytes}. Reine Struktur, keine Auslegung."""
    if data[:8] != MAGIC:
        raise ValueError("keine CFB/OLE-Datei")
    ssz = 1 << struct.unpack_from("<H", data, 30)[0]
    mssz = 1 << struct.unpack_from("<H", data, 32)[0]
    dir_start = struct.unpack_from("<I", data, 48)[0]
    mini_start = struct.unpack_from("<I", data, 60)[0]
    difat_start = struct.unpack_from("<I", data, 68)[0]

    def sec(i):
        return data[512 + i * ssz: 512 + (i + 1) * ssz]

    # FAT-Sektorliste: 109 Eintraege im Header, der Rest ueber die DIFAT-Kette.
    fatsecs = [v for v in (struct.unpack_from("<I", data, 76 + 4 * i)[0]
                           for i in range(109)) if v < FREE]
    s = difat_start
    while s < FREE:
        blk = sec(s)
        fatsecs += [v for v in (struct.unpack_from("<I", blk, 4 * i)[0]
                                for i in range((ssz // 4) - 1)) if v < FREE]
        s = struct.unpack_from("<I", blk, ssz - 4)[0]

    fat = []
    for f in fatsecs:
        blk = sec(f)
        fat += [struct.unpack_from("<I", blk, 4 * i)[0] for i in range(ssz // 4)]

    def chain(start, table):
        out, c, seen = [], start, set()
        while c < FREE and c not in seen:
            seen.add(c)
            out.append(c)
            c = table[c] if c < len(table) else 0xFFFFFFFE
        return out

    dird = b"".join(sec(i) for i in chain(dir_start, fat))
    entries = []
    for i in range(len(dird) // 128):
        e = dird[i * 128:(i + 1) * 128]
        nlen = struct.unpack_from("<H", e, 64)[0]
        entries.append((
            e[:max(0, nlen - 2)].decode("utf-16-le", "replace"),
            e[66],                                       # 2=Stream, 5=Root
            struct.unpack_from("<I", e, 116)[0],         # Startsektor
            struct.unpack_from("<Q", e, 120)[0],         # Groesse
        ))

    minifat = []
    for f in chain(mini_start, fat):
        blk = sec(f)
        minifat += [struct.unpack_from("<I", blk, 4 * i)[0] for i in range(ssz // 4)]
    root = next(e for e in entries if e[1] == 5)
    minidata = b"".join(sec(i) for i in chain(root[2], fat))

    out = {}
    for name, typ, start, size in entries:
        if typ != 2:
            continue
        # Kleine Streams (<4096) liegen im Mini-Stream, nicht in den Sektoren.
        if size < 4096:
            raw = b"".join(minidata[i * mssz:(i + 1) * mssz]
                           for i in chain(start, minifat))
        else:
            raw = b"".join(sec(i) for i in chain(start, fat))
        out[name] = raw[:size]
    return out


# Escher-Blip-Typen. Metafiles (EMF/WMF) tragen einen 34-Byte-Kopf und sind in
# aller Regel deflate-gepackt; Raster (JPEG/PNG/DIB) tragen 17 (bzw. 33) Byte
# und liegen roh. Beides kommt in den VERA-Quellen vor: der Aufgabentext steckt
# mal als Vektor, mal als Bitmap im Dokument.
BLIP = {
    0xF01A: ("emf", "meta"), 0xF01B: ("wmf", "meta"),
    0xF01D: ("jpeg", "raster"), 0xF01E: ("png", "raster"),
    0xF01F: ("dib", "raster"),
}


def _blips(buf, off, end, found):
    """Escher-Baum ablaufen und jedes Bild-Blip einsammeln."""
    while off + 8 <= end:
        verinst, typ, ln = struct.unpack_from("<HHI", buf, off)
        if typ == 0 or ln > len(buf):
            return
        body = off + 8
        if (verinst & 0xF) == 0xF:                      # Container -> absteigen
            _blips(buf, body, min(end, body + ln), found)
        elif typ == 0xF007:                             # msofbtBSE
            # Der Blip liegt IM BSE-Record, hinter dessen 36-Byte-Kopf — kein
            # Container-Flag, also muss hier von Hand abgestiegen werden.
            _blips(buf, body + 36, min(end, body + ln), found)
        elif typ in BLIP:
            ext, klasse = BLIP[typ]
            inst = verinst >> 4
            # rgbUid(16) [+ rgbUidPrimary(16), wenn das inst-Feld zwei UIDs
            # ansagt], dann der Typkopf. Danach beginnen die Bilddaten.
            two_uids = inst in (0x3D5, 0x217, 0x46B, 0x6E1, 0x7A9)
            p = body + 16 + (16 if two_uids else 0)
            if klasse == "meta":
                data = buf[p + 34: body + ln]
                if buf[p + 32] == 0:                    # 0 = deflate, 254 = roh
                    try:
                        data = zlib.decompress(data)
                    except zlib.error:
                        off += 8 + ln
                        continue
                if ext == "emf" and data[40:44] != b" EMF":
                    off += 8 + ln
                    continue
            else:
                data = buf[p + 1: body + ln]            # 1 Byte tag, dann roh
            found.append((ext, data))
        off += 8 + ln


def media_in_doc(path):
    """Bilder aus einer .doc — in Dokumentreihenfolge, dedupliziert.

    Rueckgabe wie render.media_in_docx: [(name, ext, bytes), ...]
    """
    st = streams(Path(path).read_bytes())
    found = []
    for name in ("Data", "WordDocument", "1Table"):
        if name in st:
            # Der Data-Stream beginnt mit dem PICF-Header (cbHeader = 68).
            _blips(st[name], 68 if name == "Data" else 0, len(st[name]), found)
    out, seen = [], set()
    for ext, data in found:
        h = hash(data)
        if h in seen or len(data) < 64:
            continue
        seen.add(h)
        out.append((f"doc_image{len(out) + 1}.{ext}", ext, data))
    return out
