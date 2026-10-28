"""Erzeugt docs/reihe1/B/skripte/V1.json … V8.json (Bauauftrag B8). Nur Skelett; Welten kommen später."""
import json, sys, os

AUS = sys.argv[1]


def beat(i, titel, kernidee, baustein, params, text):
    return {"id": f"b{i}", "titel": titel, "kernidee": kernidee, "baustein": baustein, "params": params,
            "text": {"skelett": text}}


def opt(antwort, rueckmeldung, richtig=False, fehlbild=None, ruecksprung=None):
    o = {"antwort": antwort}
    if richtig:
        o["richtig"] = True
    if fehlbild:
        o["fehlbild"] = fehlbild
    if ruecksprung:
        o["ruecksprung"] = ruecksprung
    o["rueckmeldung"] = rueckmeldung
    return o


def check(nach, frage, optionen, zwillinge):
    return {"nach_beat": nach, "frage": {"skelett": frage}, "optionen": optionen,
            "zwillinge": [{"frage": {"skelett": f}, "optionen": o} for f, o in zwillinge]}


def skript(nr, skill, titel, beats, checks):
    d = {"skill_key": skill, "titel": titel, "welten": ["skelett"], "beats": beats, "minichecks": checks}
    with open(os.path.join(AUS, f"V{nr}.json"), "w") as f:
        json.dump(d, f, ensure_ascii=False, indent=2)
        f.write("\n")


KS = "koordinatensystem"
TZ = "term_zeile"

# ---------------------------------------------------------------- V1
skript(1, "fkt_quadr_parabel", "Die Normalparabel", [
    beat(1, "Worum es geht", "k1", "titelkarte", {"titel": "Die Normalparabel", "untertitel": "y = x² Schritt für Schritt"},
         "Heute geht es um die wichtigste Kurve dieser Reihe: die Normalparabel."),
    beat(2, "x hoch zwei ausrechnen", "k1", TZ, {"terme": ["0^2 = 0", "1^2 = 1", "2^2 = 4", "3^2 = 9"]},
         "Wir rechnen für ein paar x-Werte x hoch zwei aus. Null, eins, vier, neun."),
    beat(3, "Ein Quadrat ist nie negativ", "k1", TZ,
         {"terme": ["(-1)^2 = 1", "(-2)^2 = 4", "(-3)^2 = 9"], "hervorheben": [1]},
         "Und für negative x? Minus zwei mal minus zwei ergibt plus vier. Ein Quadrat ist nie negativ."),
    beat(4, "Punkte eintragen", "k1", KS,
         {"x_bereich": [-4, 4], "y_bereich": [-1, 10], "punkte": [[-3, 9], [-2, 4], [-1, 1], [0, 0], [1, 1], [2, 4], [3, 9]]},
         "Wir tragen die Punkte ein. Zu jedem x gehört ein Punkt, sein y-Wert ist das Quadrat."),
    beat(5, "Die Kurve durch alle Punkte", "k1", KS,
         {"x_bereich": [-4, 4], "y_bereich": [-1, 10], "parabel": [1, 0, 0], "wertetabelle": [-3, -2, -1, 0, 1, 2, 3],
          "gleichung": "y = x^2"},
         "Verbinden wir die Punkte, entsteht eine gebogene Kurve. Das ist die Normalparabel."),
    beat(6, "Der Scheitel im Ursprung", "k1", KS,
         {"x_bereich": [-4, 4], "y_bereich": [-1, 10], "parabel": [1, 0, 0], "scheitel_markieren": True},
         "Ihr tiefster Punkt heißt Scheitel. Bei der Normalparabel liegt er im Ursprung."),
    beat(7, "Symmetrisch zur y-Achse", "k1", KS,
         {"x_bereich": [-4, 4], "y_bereich": [-1, 10], "parabel": [1, 0, 0], "gerade_y": 4, "schnitt_markieren": True},
         "Links und rechts sieht sie gleich aus. Zwei und minus zwei haben beide den y-Wert vier. Die Parabel ist symmetrisch zur y-Achse."),
    beat(8, "Merksatz", "k1", "merksatz",
         {"text": "Die Normalparabel ist symmetrisch zur y-Achse, nach oben geöffnet, ihr Scheitel liegt im Ursprung.",
          "formel": "y = x^2"},
         "Merk dir: Ein Quadrat ist nie negativ. Deshalb ist die Normalparabel nach oben geöffnet."),
    beat(9, "Weiter zur Aufgabe", "k1", "endkarte", {"frage": "Welcher Punkt liegt auf der Normalparabel?"},
         "Jetzt bist du dran."),
], [
    check("b3", "Berechne (−4)².", [
        opt("16", "Genau. (−4) · (−4) = 16.", richtig=True),
        opt("−16", "Minus mal minus ergibt plus. (−4)² = 16.", fehlbild="qf_quadrat_negativ", ruecksprung="b3"),
        opt("−8", "Hoch zwei heißt mit sich selbst malnehmen, nicht mal zwei."),
    ], [("Berechne (−5)².", [
        opt("25", "Genau. (−5) · (−5) = 25.", richtig=True),
        opt("−25", "Minus mal minus ergibt plus. (−5)² = 25.", fehlbild="qf_quadrat_negativ", ruecksprung="b3"),
        opt("−10", "Hoch zwei heißt mit sich selbst malnehmen, nicht mal zwei."),
    ])]),
    check("b7", "P(3 | 9) liegt auf der Normalparabel. Welcher Punkt liegt auch darauf?", [
        opt("(−3 | 9)", "Genau. (−3)² = 9, die Parabel ist symmetrisch.", richtig=True),
        opt("(−3 | −9)", "(−3)² ist plus 9, nicht minus 9.", fehlbild="qf_quadrat_negativ", ruecksprung="b3"),
        opt("(9 | 3)", "Erst kommt x, dann y. Der y-Wert ist das Quadrat von x.", fehlbild="qf_scheitel_koordinaten_vertauscht",
            ruecksprung="b4"),
    ], [("P(4 | 16) liegt auf der Normalparabel. Welcher Punkt liegt auch darauf?", [
        opt("(−4 | 16)", "Genau. (−4)² = 16, die Parabel ist symmetrisch.", richtig=True),
        opt("(−4 | −16)", "(−4)² ist plus 16, nicht minus 16.", fehlbild="qf_quadrat_negativ", ruecksprung="b3"),
        opt("(16 | 4)", "Erst kommt x, dann y. Der y-Wert ist das Quadrat von x.", fehlbild="qf_scheitel_koordinaten_vertauscht",
            ruecksprung="b4"),
    ])]),
])

# ---------------------------------------------------------------- V2
N = {"x_bereich": [-4, 4], "y_bereich": [-1, 9], "normalparabel": True}
skript(2, "fkt_quadr_parabel", "Strecken, stauchen, spiegeln", [
    beat(1, "Worum es geht", "k2", "titelkarte", {"titel": "Strecken, stauchen, spiegeln", "untertitel": "y = a · x²"},
         "Was passiert mit der Parabel, wenn vor dem x hoch zwei eine Zahl steht?"),
    beat(2, "Der Maßstab", "k2", KS, {"x_bereich": [-4, 4], "y_bereich": [-1, 9], "parabel": [1, 0, 0],
                                         "wertetabelle": [-2, -1, 0, 1, 2]},
         "Unser Maßstab ist die Normalparabel. Bei x gleich eins ist der y-Wert eins."),
    beat(3, "a = 2 im Vergleich", "k2", TZ, {"terme": ["y = 2x^2", "x = 1:\\; y = 2 \\cdot 1^2 = 2"]},
         "Jetzt steht eine Zwei davor. Die Zahl davor nennen wir a. Bei x gleich eins wird der y-Wert doppelt so groß: zwei statt eins."),
    beat(4, "Gestreckt: enger", "k2", KS, {**N, "parabel": [1, 0, 0], "parabel_ziel": [2, 0, 0], "wertetabelle": [-2, -1, 0, 1, 2]},
         "Alle y-Werte verdoppeln sich. Die Parabel steigt schneller und wird enger. Man sagt: gestreckt."),
    beat(5, "Gestaucht: weiter", "k2", KS, {**N, "parabel": [1, 0, 0], "parabel_ziel": [0.5, 0, 0]},
         "Steht ein Halb davor, halbieren sich alle y-Werte. Die Parabel wird weiter. Man sagt: gestaucht."),
    beat(6, "Negativ: nach unten geöffnet", "k2", KS,
         {"x_bereich": [-4, 4], "y_bereich": [-9, 9], "normalparabel": True, "parabel": [1, 0, 0], "parabel_ziel": [-1, 0, 0]},
         "Ist a negativ, wechseln alle y-Werte das Vorzeichen. Die Parabel ist nach unten geöffnet, der Scheitel ist jetzt der höchste Punkt."),
    beat(7, "Merksatz", "k2", "merksatz",
         {"text": "Betrag von a größer als 1: enger. Kleiner als 1: weiter. a negativ: nach unten geöffnet.",
          "formel": "y = a \\cdot x^2"},
         "Merk dir: Der Betrag von a entscheidet über eng oder weit, das Vorzeichen über oben oder unten."),
    beat(8, "Weiter zur Aufgabe", "k2", "endkarte", {"frage": "Welche Parabel ist am engsten?"}, "Jetzt bist du dran."),
], [
    check("b5", "Welche Parabel ist enger als die Normalparabel?", [
        opt("y = 3x²", "Genau. Mit a = 3 werden alle y-Werte dreimal so groß.", richtig=True),
        opt("y = 0,3x²", "Ein a zwischen 0 und 1 macht die Parabel weiter, nicht enger.", fehlbild="qf_streckfaktor_umgekehrt",
            ruecksprung="b5"),
        opt("y = x² + 3", "Die Zahl hinten verschiebt nur nach oben. Die Form bestimmt a.", fehlbild="qf_oeffnung_aus_e",
            ruecksprung="b4"),
    ], [("Welche Parabel ist enger als die Normalparabel?", [
        opt("y = 4x²", "Genau. Mit a = 4 werden alle y-Werte viermal so groß.", richtig=True),
        opt("y = 0,4x²", "Ein a zwischen 0 und 1 macht die Parabel weiter, nicht enger.", fehlbild="qf_streckfaktor_umgekehrt",
            ruecksprung="b5"),
        opt("y = x² + 4", "Die Zahl hinten verschiebt nur nach oben. Die Form bestimmt a.", fehlbild="qf_oeffnung_aus_e",
            ruecksprung="b4"),
    ])]),
    check("b6", "Wie sieht y = −2x² im Vergleich zur Normalparabel aus?", [
        opt("nach unten, enger", "Genau. Minus heißt unten, 2 heißt enger.", richtig=True),
        opt("nach oben, enger", "a ist negativ, das spiegelt die Parabel nach unten.", fehlbild="qf_oeffnung_vertauscht",
            ruecksprung="b6"),
        opt("nach unten, weiter", "Der Betrag 2 ist größer als 1, das macht sie enger.", fehlbild="qf_streckfaktor_umgekehrt",
            ruecksprung="b3"),
    ], [("Wie sieht y = −0,5x² im Vergleich zur Normalparabel aus?", [
        opt("nach unten, weiter", "Genau. Minus heißt unten, 0,5 heißt weiter.", richtig=True),
        opt("nach oben, weiter", "a ist negativ, das spiegelt die Parabel nach unten.", fehlbild="qf_oeffnung_vertauscht",
            ruecksprung="b6"),
        opt("nach unten, enger", "Der Betrag 0,5 ist kleiner als 1, das macht sie weiter.", fehlbild="qf_streckfaktor_umgekehrt",
            ruecksprung="b5"),
    ])]),
])

# ---------------------------------------------------------------- V3
V = {"x_bereich": [-3, 6], "y_bereich": [-5, 7], "normalparabel": True, "scheitel_markieren": True}
SCH = "fkt_quadr_scheitel:k1"
skript(3, "fkt_quadr_parabel", "Verschieben und Scheitelpunktform", [
    beat(1, "Worum es geht", "k3", "titelkarte", {"titel": "Verschieben", "untertitel": "Die Scheitelpunktform"},
         "Jetzt verschieben wir die Parabel nach rechts, nach links, nach oben und nach unten."),
    beat(2, "Nach oben: plus e", "k3", KS, {**V, "parabel": [1, 0, 0], "parabel_ziel": [1, 0, 3], "gleichung": "y = x^2 + 3"},
         "Steht hinten plus drei, liegt jeder Punkt drei höher. Die Parabel wandert drei nach oben."),
    beat(3, "Nach rechts: x minus d", "k3", KS, {**V, "parabel": [1, 0, 0], "parabel_ziel": [1, 2, 0], "gleichung": "y = (x - 2)^2"},
         "Steht in der Klammer x minus zwei, wandert die Parabel zwei nach rechts. Das überrascht viele."),
    beat(4, "Wo wird die Klammer null?", "k3", TZ, {"terme": ["(x - 2)^2", "x - 2 = 0", "x = 2"], "hervorheben": [2]},
         "Der Trick: Frag dich, wo die Klammer null wird. Zwei minus zwei ist null. Genau bei x gleich zwei liegt jetzt der Scheitel."),
    beat(5, "Beides zusammen", "k3", KS, {**V, "parabel": [1, 0, 0], "parabel_ziel": [1, 2, -4], "gleichung": "y = (x - 2)^2 - 4"},
         "Beides geht gleichzeitig: zwei nach rechts und vier nach unten."),
    beat(6, "Die Scheitelpunktform", SCH, TZ, {"terme": ["y = (x - d)^2 + e", "S(d \\mid e)"]},
         "Allgemein heißt das Scheitelpunktform. Den Scheitel liest du direkt ab: d aus der Klammer, e von hinten."),
    beat(7, "Plus in der Klammer heißt links", SCH, TZ,
         {"terme": ["y = (x + 1)^2 - 3", "x + 1 = 0 \\;\\Rightarrow\\; x = -1", "S(-1 \\mid -3)"], "hervorheben": [2]},
         "Bei x plus eins wird die Klammer bei minus eins null. Der Scheitel hat also den x-Wert minus eins und den y-Wert minus drei."),
    beat(8, "Merksatz", SCH, "merksatz",
         {"text": "Ohne Streckfaktor (a = 1): Der Scheitel liegt dort, wo die Klammer null wird. Das Vorzeichen kehrt sich um.",
          "formel": "y = (x - d)^2 + e"},
         "Merk dir: Das Vorzeichen in der Klammer kehrt sich um, das hinten bleibt, wie es ist."),
    beat(9, "Weiter zur Aufgabe", SCH, "endkarte", {"frage": "Wo liegt der Scheitel?"}, "Jetzt bist du dran."),
], [
    check("b5", "Die Normalparabel wird verschoben zu y = (x − 3)². Wohin?", [
        opt("3 nach rechts", "Genau. Die Klammer wird bei x = 3 null.", richtig=True),
        opt("3 nach links", "Minus in der Klammer heißt rechts: Die Klammer wird bei x = 3 null.",
            fehlbild="qf_verschiebung_vorzeichen", ruecksprung="b4"),
        opt("3 nach oben", "Nach oben verschiebt nur die Zahl hinten. Die Klammer verschiebt nach rechts oder links.",
            fehlbild="qf_d_e_vertauscht", ruecksprung="b2"),
    ], [("Die Normalparabel wird verschoben zu y = (x − 5)². Wohin?", [
        opt("5 nach rechts", "Genau. Die Klammer wird bei x = 5 null.", richtig=True),
        opt("5 nach links", "Minus in der Klammer heißt rechts: Die Klammer wird bei x = 5 null.",
            fehlbild="qf_verschiebung_vorzeichen", ruecksprung="b4"),
        opt("5 nach oben", "Nach oben verschiebt nur die Zahl hinten. Die Klammer verschiebt nach rechts oder links.",
            fehlbild="qf_d_e_vertauscht", ruecksprung="b2"),
    ])]),
    check("b8", "Gib den Scheitel von y = (x + 4)² − 1 an.", [
        opt("S(−4 | −1)", "Genau. Die Klammer wird bei x = −4 null, hinten steht −1.", richtig=True),
        opt("S(4 | −1)", "Plus in der Klammer heißt: Die Klammer wird bei x = −4 null.", fehlbild="qf_verschiebung_vorzeichen",
            ruecksprung="b7"),
        opt("S(−1 | −4)", "Zuerst kommt der x-Wert aus der Klammer, dann der y-Wert von hinten.",
            fehlbild="qf_scheitel_koordinaten_vertauscht", ruecksprung="b6"),
    ], [("Gib den Scheitel von y = (x + 2)² − 5 an.", [
        opt("S(−2 | −5)", "Genau. Die Klammer wird bei x = −2 null, hinten steht −5.", richtig=True),
        opt("S(2 | −5)", "Plus in der Klammer heißt: Die Klammer wird bei x = −2 null.", fehlbild="qf_verschiebung_vorzeichen",
            ruecksprung="b7"),
        opt("S(−5 | −2)", "Zuerst kommt der x-Wert aus der Klammer, dann der y-Wert von hinten.",
            fehlbild="qf_scheitel_koordinaten_vertauscht", ruecksprung="b6"),
    ])]),
])

# ---------------------------------------------------------------- V4
skript(4, "fkt_quadr_normalform", "Quadratische Ergänzung", [
    beat(1, "Worum es geht", "k1", "titelkarte", {"titel": "Quadratische Ergänzung", "untertitel": "Von der Normalform zur Scheitelpunktform"},
         "Wie wird aus x hoch zwei plus sechs x plus fünf eine Scheitelpunktform? Zuerst gehen wir den Rückweg."),
    beat(2, "Der Rückweg: ausmultiplizieren", "k1", TZ,
         {"terme": ["(x + 3)^2 - 4", "= x^2 + 6x + 9 - 4", "= x^2 + 6x + 5"]},
         "Mit der binomischen Formel wird die Klammer x plus drei zum Quadrat zu x hoch zwei plus sechs x plus neun. Minus vier ergibt plus fünf."),
    beat(3, "Sechs x als zwei Streifen", "k2", "flaechenmodell", {"b": 6, "zeigen": "streifen", "gleichung": "x^2 + 6x"},
         "Jetzt vorwärts. Wir legen x hoch zwei als Quadrat und teilen sechs x in zwei Streifen zu je drei x."),
    beat(4, "Die fehlende Ecke", "k2", "flaechenmodell", {"b": 6, "zeigen": "ecke", "gleichung": "x^2 + 6x + 9 = (x + 3)^2"},
         "Zum vollen Quadrat fehlt nur die Ecke: drei mal drei, also neun."),
    beat(5, "Was wir dazugeben, ziehen wir ab", "k2", TZ,
         {"terme": ["x^2 + 6x + 5", "= x^2 + 6x + 9 - 9 + 5", "= (x + 3)^2 - 4"], "hervorheben": [1]},
         "Wir geben neun dazu und ziehen neun sofort wieder ab. So bleibt der Term gleich, und vorne steht ein volles Quadrat."),
    beat(6, "Merksatz", "k2", "merksatz",
         {"text": "Halbiere die Zahl vor x, quadriere sie, gib sie dazu und zieh sie gleich wieder ab.",
          "formel": "x^2 + bx = (x + \\tfrac{b}{2})^2 - (\\tfrac{b}{2})^2"},
         "Merk dir: halbieren, quadrieren, dazugeben, wieder abziehen."),
    beat(7, "Mit a: erst ausklammern", "k3", TZ,
         {"terme": ["2x^2 + 8x + 3", "= 2\\,(x^2 + 4x) + 3", "= 2\\,(x^2 + 4x + 4 - 4) + 3"]},
         "Steht vor x hoch zwei eine Zwei, klammern wir sie aus den ersten beiden Teilen aus. Ergänzt wird dann in der Klammer."),
    beat(8, "Auflösen: mal a", "k3", TZ,
         {"terme": ["= 2\\,(x^2 + 4x + 4 - 4) + 3", "= 2\\,((x + 2)^2 - 4) + 3", "= 2\\,(x + 2)^2 - 8 + 3",
                    "= 2\\,(x + 2)^2 - 5"], "hervorheben": [2]},
         "Beim Auflösen der äußeren Klammer wird die abgezogene Vier mit zwei malgenommen. Aus minus vier wird minus acht."),
    beat(9, "Weiter zur Aufgabe", "k3", "endkarte", {"frage": "Bring den Term in Scheitelpunktform."}, "Jetzt bist du dran."),
], [
    check("b2", "Multipliziere aus: (x + 2)² − 1", [
        opt("x² + 4x + 3", "Genau. x² + 4x + 4 − 1.", richtig=True),
        opt("x² + 3", "Bei dir fehlt das Mittelglied 2 · 2 · x = 4x.", fehlbild="qf_binom_mittelglied_fehlt",
            ruecksprung="b2"),
        opt("x² − 4x + 3", "Bei x + 2 ist das Mittelglied positiv: +4x.", fehlbild="qf_binom_vorzeichen", ruecksprung="b2"),
    ], [("Multipliziere aus: (x + 5)² − 2", [
        opt("x² + 10x + 23", "Genau. x² + 10x + 25 − 2.", richtig=True),
        opt("x² + 23", "Bei dir fehlt das Mittelglied 2 · 5 · x = 10x.", fehlbild="qf_binom_mittelglied_fehlt",
            ruecksprung="b2"),
        opt("x² − 10x + 23", "Bei x + 5 ist das Mittelglied positiv: +10x.", fehlbild="qf_binom_vorzeichen", ruecksprung="b2"),
    ])]),
    check("b6", "Bring x² + 8x + 10 in die Scheitelpunktform.", [
        opt("(x + 4)² − 6", "Genau. x² + 8x + 16 − 16 + 10 = (x + 4)² − 6.", richtig=True),
        opt("(x + 4)² + 10", "Die 16 hast du dazugegeben. Du musst sie auch wieder abziehen.",
            fehlbild="qf_ergaenzung_nicht_abgezogen", ruecksprung="b5"),
        opt("(x + 8)² − 54", "In die Klammer kommt die Hälfte von 8, also 4.", fehlbild="qf_ergaenzung_b_statt_halb",
            ruecksprung="b3"),
    ], [("Bring x² + 6x + 2 in die Scheitelpunktform.", [
        opt("(x + 3)² − 7", "Genau. x² + 6x + 9 − 9 + 2 = (x + 3)² − 7.", richtig=True),
        opt("(x + 3)² + 2", "Die 9 hast du dazugegeben. Du musst sie auch wieder abziehen.",
            fehlbild="qf_ergaenzung_nicht_abgezogen", ruecksprung="b5"),
        opt("(x + 6)² − 34", "In die Klammer kommt die Hälfte von 6, also 3.", fehlbild="qf_ergaenzung_b_statt_halb",
            ruecksprung="b3"),
    ])]),
    check("b8", "Bring 3x² + 6x + 1 in die Scheitelpunktform.", [
        opt("3(x + 1)² − 2", "Genau. 3 · ((x + 1)² − 1) + 1.", richtig=True),
        opt("3(x + 1)²", "Die abgezogene 1 steht in der Klammer mit dem Faktor 3: −3, nicht −1.", fehlbild="qf_ergaenzung_ohne_a",
            ruecksprung="b8"),
        opt("3(x + 1)² + 1", "Die Ergänzung musst du auch wieder abziehen.", fehlbild="qf_ergaenzung_nicht_abgezogen",
            ruecksprung="b5"),
    ], [("Bring 2x² + 12x + 5 in die Scheitelpunktform.", [
        opt("2(x + 3)² − 13", "Genau. 2 · ((x + 3)² − 9) + 5.", richtig=True),
        opt("2(x + 3)² − 4", "Die abgezogene 9 steht in der Klammer mit dem Faktor 2: −18, nicht −9.", fehlbild="qf_ergaenzung_ohne_a",
            ruecksprung="b8"),
        opt("2(x + 3)² + 5", "Die Ergänzung musst du auch wieder abziehen.", fehlbild="qf_ergaenzung_nicht_abgezogen",
            ruecksprung="b5"),
    ])]),
])

# ---------------------------------------------------------------- V5
P = {"x_bereich": [-5, 5], "y_bereich": [-6, 12], "parabel": [1, 0, 0], "schnitt_markieren": True}
skript(5, "gleichung_quadr_wurzel", "x² = c hat zwei Lösungen", [
    beat(1, "Worum es geht", "k1", "titelkarte", {"titel": "x² = c", "untertitel": "Zwei, eine oder keine Lösung"},
         "Wie viele Lösungen hat x hoch zwei gleich neun? Viele sagen sofort: drei. Schauen wir genau hin."),
    beat(2, "Die Gerade schneidet zweimal", "k1", KS, {**P, "gerade_y": 9, "gleichung": "x^2 = 9"},
         "Wir zeichnen die Normalparabel und die Gerade y gleich neun. Sie schneiden sich zweimal."),
    beat(3, "Auch (−3)² = 9", "k1", TZ,
         {"terme": ["3^2 = 9", "(-3)^2 = 9", "x = 3 \\;\\text{oder}\\; x = -3"], "hervorheben": [1]},
         "Drei mal drei ist neun. Aber auch minus drei mal minus drei ist neun. Es gibt also zwei Lösungen: drei und minus drei."),
    beat(4, "Null: genau eine Lösung", "k1", KS, {**P, "gerade_y": 0, "gleichung": "x^2 = 0"},
         "Bei x hoch zwei gleich null berührt die Gerade nur den Scheitel. Es gibt genau eine Lösung: null."),
    beat(5, "Negativ: keine Lösung", "k1", KS, {**P, "gerade_y": -4, "gleichung": "x^2 = -4"},
         "Bei minus vier liegt die Gerade unter der Parabel. Kein Quadrat ist negativ, also gibt es keine Lösung."),
    beat(6, "Erst umstellen, dann Wurzel", "k2", TZ,
         {"terme": ["2x^2 - 8 = 42", "2x^2 = 50", "x^2 = 25", "x = 5 \\;\\text{oder}\\; x = -5"]},
         "Steht mehr da, stellen wir zuerst um: plus acht, dann durch zwei. Erst bei x hoch zwei gleich fünfundzwanzig ziehen wir die Wurzel."),
    beat(7, "Mit Klammer", "k3", TZ,
         {"terme": ["(x - 1)^2 = 16", "x - 1 = 4 \\;\\text{oder}\\; x - 1 = -4", "x = 5 \\;\\text{oder}\\; x = -3"]},
         "Steht eine Klammer zum Quadrat da, gilt dasselbe. Die Klammer ist vier oder minus vier. Also ist x fünf oder minus drei."),
    beat(8, "Merksatz", "k3", "merksatz",
         {"text": "x² = c hat zwei Lösungen, wenn c positiv ist, eine bei c = 0 und keine, wenn c negativ ist.",
          "formel": "x^2 = c > 0 \\;\\Rightarrow\\; x = \\pm\\sqrt{c}"},
         "Merk dir: Steht rechts eine positive Zahl, gibt es immer zwei Lösungen, eine mit Plus und eine mit Minus."),
    beat(9, "Weiter zur Aufgabe", "k3", "endkarte", {"frage": "Wie viele Lösungen hat die Gleichung?"}, "Jetzt bist du dran."),
], [
    check("b5", "Löse x² = 49.", [
        opt("x = 7 oder x = −7", "Genau. 7² = 49 und (−7)² = 49.", richtig=True),
        opt("x = 7", "Auch (−7)² = 49. Es gibt zwei Lösungen.", fehlbild="qf_nur_positive_loesung", ruecksprung="b3"),
        opt("x = 24,5", "24,5 ist die Hälfte von 49. Gesucht ist die Zahl, die mit sich selbst 49 ergibt.",
            fehlbild="qf_wurzel_als_haelfte", ruecksprung="b3"),
    ], [("Löse x² = 64.", [
        opt("x = 8 oder x = −8", "Genau. 8² = 64 und (−8)² = 64.", richtig=True),
        opt("x = 8", "Auch (−8)² = 64. Es gibt zwei Lösungen.", fehlbild="qf_nur_positive_loesung", ruecksprung="b3"),
        opt("x = 32", "32 ist die Hälfte von 64. Gesucht ist die Zahl, die mit sich selbst 64 ergibt.",
            fehlbild="qf_wurzel_als_haelfte", ruecksprung="b3"),
    ])]),
    check("b6", "Löse 3x² − 12 = 0.", [
        opt("x = 2 oder x = −2", "Genau. 3x² = 12, x² = 4.", richtig=True),
        opt("x = 2", "Auch (−2)² = 4. Es gibt zwei Lösungen.", fehlbild="qf_nur_positive_loesung", ruecksprung="b3"),
        opt("keine Lösung", "Die −12 kommt mit + 12 auf die andere Seite: 3x² = 12.", fehlbild="qf_gegenoperation_vorzeichen", ruecksprung="b6"),
    ], [("Löse 2x² − 18 = 0.", [
        opt("x = 3 oder x = −3", "Genau. 2x² = 18, x² = 9.", richtig=True),
        opt("x = 3", "Auch (−3)² = 9. Es gibt zwei Lösungen.", fehlbild="qf_nur_positive_loesung", ruecksprung="b3"),
        opt("keine Lösung", "Die −18 kommt mit + 18 auf die andere Seite: 2x² = 18.", fehlbild="qf_gegenoperation_vorzeichen", ruecksprung="b6"),
    ])]),
    check("b7", "Löse (x − 2)² = 9.", [
        opt("x = 5 oder x = −1", "Genau. x − 2 = 3 oder x − 2 = −3.", richtig=True),
        opt("x = 5", "Die Klammer kann auch −3 sein. Dann ist x = −1.", fehlbild="qf_nur_positive_loesung", ruecksprung="b7"),
        opt("x = 1 oder x = −5", "Aus x − 2 = 3 folgt x = 5: Die 2 kommt mit Plus auf die andere Seite.",
            fehlbild="qf_gegenoperation_vorzeichen", ruecksprung="b7"),
    ], [("Löse (x − 1)² = 25.", [
        opt("x = 6 oder x = −4", "Genau. x − 1 = 5 oder x − 1 = −5.", richtig=True),
        opt("x = 6", "Die Klammer kann auch −5 sein. Dann ist x = −4.", fehlbild="qf_nur_positive_loesung", ruecksprung="b7"),
        opt("x = 4 oder x = −6", "Aus x − 1 = 5 folgt x = 6: Die 1 kommt mit Plus auf die andere Seite.",
            fehlbild="qf_gegenoperation_vorzeichen", ruecksprung="b7"),
    ])]),
])

# ---------------------------------------------------------------- V6
skript(6, "gleichung_quadr_faktor", "Das Nullprodukt", [
    beat(1, "Worum es geht", "k1", "titelkarte", {"titel": "Das Nullprodukt", "untertitel": "Wann ist ein Produkt null?"},
         "Ein Produkt entsteht, wenn man Zahlen malnimmt. Wann kommt dabei null heraus?"),
    beat(2, "Ein Faktor muss null sein", "k1", TZ,
         {"terme": ["3 \\cdot 0 = 0", "0 \\cdot 7 = 0", "u \\cdot v = 0 \\;\\Rightarrow\\; u = 0 \\;\\text{oder}\\; v = 0"],
          "hervorheben": [2]},
         "Drei mal null ist null, null mal sieben ist null. Ein Produkt ist genau dann null, wenn mindestens ein Faktor null ist."),
    beat(3, "Jeden Faktor null setzen", "k1", TZ,
         {"terme": ["(x - 3)(x + 5) = 0", "x - 3 = 0 \\;\\text{oder}\\; x + 5 = 0", "x = 3 \\;\\text{oder}\\; x = -5"]},
         "Bei x minus drei mal x plus fünf setzen wir jede Klammer einzeln null. Das ergibt drei und minus fünf."),
    beat(4, "x ausklammern", "k2", TZ, {"terme": ["x^2 - 4x = 0", "x \\cdot (x - 4) = 0"]},
         "Bei x hoch zwei minus vier x fehlt die Zahl ohne x. Dann klammern wir x aus."),
    beat(5, "Ein Faktor ist x selbst", "k2", TZ,
         {"terme": ["x \\cdot (x - 4) = 0", "x = 0 \\;\\text{oder}\\; x - 4 = 0", "x = 0 \\;\\text{oder}\\; x = 4"],
          "hervorheben": [1]},
         "Jetzt stehen zwei Faktoren da, und einer davon ist x selbst. Also ist null eine Lösung, die andere ist vier."),
    beat(6, "Nicht durch x teilen", "k2", TZ, {"terme": ["x^2 - 4x = 0", "x - 4 = 0", "x = 4"], "durchstreichen": [1]},
         "Teilt man durch x, geht die Lösung null verloren, denn x könnte ja null sein. Deshalb klammern wir aus und teilen nicht."),
    beat(7, "Merksatz", "k2", "merksatz",
         {"text": "Klammere x aus und setze jeden Faktor null. x = 0 ist dann immer eine der Lösungen.",
          "formel": "x \\cdot (x - c) = 0"},
         "Merk dir: ausklammern, jeden Faktor null setzen, die Null nicht vergessen."),
    beat(8, "Weiter zur Aufgabe", "k2", "endkarte", {"frage": "Wie heißen beide Lösungen?"}, "Jetzt bist du dran."),
], [
    check("b3", "Löse (x − 2)(x + 7) = 0.", [
        opt("x = 2 oder x = −7", "Genau. x − 2 = 0 oder x + 7 = 0.", richtig=True),
        opt("x = −2 oder x = 7", "Setz die Klammern null: x − 2 = 0 heißt x = 2.", fehlbild="qf_nullprodukt_vorzeichen",
            ruecksprung="b3"),
        opt("x = 2", "Auch die zweite Klammer kann null werden.", fehlbild="qf_nur_eine_loesung", ruecksprung="b3"),
    ], [("Löse (x − 4)(x + 1) = 0.", [
        opt("x = 4 oder x = −1", "Genau. x − 4 = 0 oder x + 1 = 0.", richtig=True),
        opt("x = −4 oder x = 1", "Setz die Klammern null: x − 4 = 0 heißt x = 4.", fehlbild="qf_nullprodukt_vorzeichen",
            ruecksprung="b3"),
        opt("x = 4", "Auch die zweite Klammer kann null werden.", fehlbild="qf_nur_eine_loesung", ruecksprung="b3"),
    ])]),
    check("b6", "Löse x² − 6x = 0.", [
        opt("x = 0 oder x = 6", "Genau. x · (x − 6) = 0.", richtig=True),
        opt("x = 6", "Der Faktor x selbst kann auch null sein: x = 0. Nicht durch x teilen.", fehlbild="qf_null_vergessen", ruecksprung="b5"),
        opt("x = 0 oder x = −6", "Aus x − 6 = 0 folgt x = 6.", fehlbild="qf_nullprodukt_vorzeichen", ruecksprung="b5"),
    ], [("Löse x² − 9x = 0.", [
        opt("x = 0 oder x = 9", "Genau. x · (x − 9) = 0.", richtig=True),
        opt("x = 9", "Der Faktor x selbst kann auch null sein: x = 0. Nicht durch x teilen.", fehlbild="qf_null_vergessen", ruecksprung="b5"),
        opt("x = 0 oder x = −9", "Aus x − 9 = 0 folgt x = 9.", fehlbild="qf_nullprodukt_vorzeichen", ruecksprung="b5"),
    ])]),
])

# ---------------------------------------------------------------- V7
AN = "gleichung_quadr_anzahl:k1"
skript(7, "gleichung_quadr_formel", "Woher die p-q-Formel kommt", [
    beat(1, "Worum es geht", "k1", "titelkarte", {"titel": "Die p-q-Formel", "untertitel": "Woher sie kommt"},
         "Die p-q-Formel löst quadratische Gleichungen in Normalform, sofern sie Lösungen haben. Aber woher kommt sie?"),
    beat(2, "Normalform: vor x² steht 1", "k1", TZ,
         {"terme": ["2x^2 + 8x - 10 = 0", "x^2 + 4x - 5 = 0", "p = 4,\\; q = -5"], "hervorheben": [2]},
         "Zuerst muss vor x hoch zwei eine Eins stehen. Wir teilen also durch zwei. Dann lesen wir mit Vorzeichen ab: p ist vier, q ist minus fünf."),
    beat(3, "Allgemein umstellen", "k2", TZ, {"terme": ["x^2 + px + q = 0", "x^2 + px = -q"]},
         "Allgemein steht da x hoch zwei plus p x plus q gleich null. Wir bringen q auf die rechte Seite."),
    beat(4, "Die Ergänzung", "k2", TZ,
         {"terme": ["x^2 + px + \\left(\\tfrac{p}{2}\\right)^2 = \\left(\\tfrac{p}{2}\\right)^2 - q",
                    "\\left(x + \\tfrac{p}{2}\\right)^2 = \\left(\\tfrac{p}{2}\\right)^2 - q"], "hervorheben": [0]},
         "Jetzt ergänzen wir wie beim Flächenmodell: die Hälfte von p, zum Quadrat, auf beiden Seiten. Links steht dann ein volles Quadrat."),
    beat(5, "Wurzel ziehen: die Formel", "k2", TZ,
         {"terme": ["x + \\tfrac{p}{2} = \\pm\\sqrt{\\left(\\tfrac{p}{2}\\right)^2 - q}",
                    "x_{1,2} = -\\tfrac{p}{2} \\pm \\sqrt{\\left(\\tfrac{p}{2}\\right)^2 - q}"], "hervorheben": [1]},
         "Wir ziehen die Wurzel, mit Plus und Minus, und bringen p halbe nach rechts. Das ist die p-q-Formel."),
    beat(6, "Einsetzen am Beispiel", "k2", TZ,
         {"terme": ["x^2 + 4x - 5 = 0", "x_{1,2} = -2 \\pm \\sqrt{4 - (-5)}", "x_{1,2} = -2 \\pm \\sqrt{9} = -2 \\pm 3", "x_1 = 1,\\; x_2 = -5"]},
         "Mit p gleich vier und q gleich minus fünf: Unter der Wurzel steht vier minus minus fünf, also neun. Das gibt minus zwei plus minus drei, also eins und minus fünf."),
    beat(7, "Was unter der Wurzel steht", AN, TZ,
         {"terme": ["D = \\left(\\tfrac{p}{2}\\right)^2 - q", "D > 0:\\ \\text{zwei}", "D = 0:\\ \\text{eine}",
                    "D < 0:\\ \\text{keine}"]},
         "Der Ausdruck unter der Wurzel entscheidet. Ist er positiv, gibt es zwei Lösungen, ist er null, eine, ist er negativ, keine."),
    beat(8, "Merksatz", AN, "merksatz",
         {"text": "Normalform herstellen, p und q mit Vorzeichen ablesen, einsetzen. Unter der Wurzel steht (p/2)² − q.",
          "formel": "x_{1,2} = -\\tfrac{p}{2} \\pm \\sqrt{\\left(\\tfrac{p}{2}\\right)^2 - q}"},
         "Merk dir: Normalform, ablesen, einsetzen. Unter der Wurzel steht p halbe zum Quadrat minus q."),
    beat(9, "Weiter zur Aufgabe", AN, "endkarte", {"frage": "Wie viele Lösungen hat die Gleichung?"}, "Jetzt bist du dran."),
], [
    check("b2", "Lies p und q ab: 3x² − 12x + 9 = 0.", [
        opt("p = −4, q = 3", "Genau. Durch 3 geteilt: x² − 4x + 3 = 0.", richtig=True),
        opt("p = −12, q = 9", "Erst durch 3 teilen, damit vor x² eine 1 steht.", fehlbild="qf_durch_a_vergessen", ruecksprung="b2"),
        opt("p = 4, q = 3", "p ist die Zahl vor x mit ihrem Vorzeichen: −4.", fehlbild="qf_p_vorzeichen", ruecksprung="b2"),
    ], [("Lies p und q ab: 2x² + 10x − 6 = 0.", [
        opt("p = 5, q = −3", "Genau. Durch 2 geteilt: x² + 5x − 3 = 0.", richtig=True),
        opt("p = 10, q = −6", "Erst durch 2 teilen, damit vor x² eine 1 steht.", fehlbild="qf_durch_a_vergessen", ruecksprung="b2"),
        opt("p = −5, q = −3", "p ist die Zahl vor x mit ihrem Vorzeichen: +5.", fehlbild="qf_p_vorzeichen", ruecksprung="b2"),
    ])]),
    check("b6", "Löse x² + 6x + 5 = 0 mit der p-q-Formel.", [
        opt("x = −1 oder x = −5", "Genau. −3 ± √(9 − 5) = −3 ± 2.", richtig=True),
        opt("keine Lösung", "Unter der Wurzel steht (p/2)² = 9, nicht p/2 = 3.", fehlbild="qf_halbes_p_nicht_quadriert",
            ruecksprung="b4"),
        opt("x = 5 oder x = 1", "Vorne steht −p/2 = −3.", fehlbild="qf_p_vorzeichen", ruecksprung="b5"),
    ], [("Löse x² + 8x + 12 = 0 mit der p-q-Formel.", [
        opt("x = −2 oder x = −6", "Genau. −4 ± √(16 − 12) = −4 ± 2.", richtig=True),
        opt("keine Lösung", "Unter der Wurzel steht (p/2)² = 16, nicht p/2 = 4.", fehlbild="qf_halbes_p_nicht_quadriert",
            ruecksprung="b4"),
        opt("x = 6 oder x = 2", "Vorne steht −p/2 = −4.", fehlbild="qf_p_vorzeichen", ruecksprung="b5"),
    ])]),
    check("b8", "Wie viele Lösungen hat x² + 2x + 5 = 0?", [
        opt("keine Lösung", "Genau. 1 − 5 = −4 ist negativ.", richtig=True),
        opt("zwei Lösungen", "(p/2)² − q = 1 − 5 = −4. Das ist negativ.", fehlbild="qf_q_vorzeichen", ruecksprung="b7"),
        opt("eine Lösung", "Eine Lösung gibt es nur, wenn unter der Wurzel genau 0 steht."),
    ], [("Wie viele Lösungen hat x² − 4x + 7 = 0?", [
        opt("keine Lösung", "Genau. 4 − 7 = −3 ist negativ.", richtig=True),
        opt("zwei Lösungen", "(p/2)² − q = 4 − 7 = −3. Das ist negativ.", fehlbild="qf_q_vorzeichen", ruecksprung="b7"),
        opt("eine Lösung", "Eine Lösung gibt es nur, wenn unter der Wurzel genau 0 steht."),
    ])]),
])

# ---------------------------------------------------------------- V8
NS = {"x_bereich": [-4, 6], "y_bereich": [-5, 6], "parabel": [1, 1, -4]}
skript(8, "fkt_quadr_nullstellen", "Nullstellen sind Schnittpunkte", [
    beat(1, "Worum es geht", "k1", "titelkarte", {"titel": "Nullstellen", "untertitel": "Wo die Parabel die x-Achse schneidet"},
         "Wo schneidet eine Parabel die x-Achse? Diese Stellen heißen Nullstellen."),
    beat(2, "Schnitt mit der x-Achse", "k1", KS, {**NS, "nullstellen_markieren": True},
         "Auf der x-Achse ist der y-Wert null. Die Nullstellen sind die x-Werte, an denen die Parabel die Achse trifft."),
    beat(3, "f(x) = 0", "k1", TZ, {"terme": ["f(x) = (x - 1)^2 - 4", "f(x) = 0", "(x - 1)^2 - 4 = 0"], "hervorheben": [1]},
         "F von x ist einfach der y-Wert. Rechnerisch setzen wir ihn gleich null und lösen die Gleichung."),
    beat(4, "Lösen wie gelernt", "k1", TZ,
         {"terme": ["(x - 1)^2 = 4", "x - 1 = 2 \\;\\text{oder}\\; x - 1 = -2", "x = 3 \\;\\text{oder}\\; x = -1"]},
         "Hier hilft das Wurzelziehen: Die Klammer ist zwei oder minus zwei. Die Nullstellen sind drei und minus eins."),
    beat(5, "Hier ist der Scheitel keine Nullstelle", "k1", KS, {**NS, "nullstellen_markieren": True, "scheitel_markieren": True},
         "Vorsicht: Der Scheitel hat den x-Wert eins und den y-Wert minus vier. Er ist der tiefste Punkt, hier aber keine Nullstelle."),
    beat(6, "Den passenden Weg wählen", "k2", TZ,
         {"terme": ["x^2 - 5x = 0 \;\\rightarrow\; x\\,(x - 5) = 0",
                    "(x - 2)^2 - 9 = 0 \\;\\rightarrow\\; \\text{Wurzel ziehen}",
                    "x^2 + 3x - 4 = 0 \\;\\rightarrow\\; p\\text{-}q\\text{-Formel}"]},
         "Welcher Weg passt? Fehlt die Zahl ohne x, klammerst du aus. Steht eine Klammer zum Quadrat da, ziehst du die Wurzel. Sonst hilft die p-q-Formel."),
    beat(7, "Merksatz", "k2", "merksatz",
         {"text": "Nullstellen: f(x) = 0 setzen und lösen. Das Ergebnis sind x-Werte. Scheitel und Nullstelle sind verschiedene Dinge.",
          "formel": "f(x) = 0"},
         "Merk dir: Nullstellen findest du mit f von x gleich null. Das Ergebnis sind x-Werte."),
    beat(8, "Weiter zur Aufgabe", "k2", "endkarte", {"frage": "Wo liegen die Nullstellen?"}, "Jetzt bist du dran."),
], [
    check("b5", "Gib die Nullstellen von f(x) = (x − 2)² − 9 an.", [
        opt("x = 5 und x = −1", "Genau. (x − 2)² = 9, also x − 2 = 3 oder −3.", richtig=True),
        opt("S(2 | −9)", "Das ist der Scheitel. Nullstellen sind die x-Werte mit f(x) = 0.", fehlbild="qf_scheitel_statt_nullstelle",
            ruecksprung="b3"),
        opt("x = 5", "x − 2 kann auch −3 sein. Dann ist x = −1.", fehlbild="qf_nur_positive_loesung", ruecksprung="b4"),
    ], [("Gib die Nullstellen von f(x) = (x + 1)² − 4 an.", [
        opt("x = 1 und x = −3", "Genau. (x + 1)² = 4, also x + 1 = 2 oder −2.", richtig=True),
        opt("S(−1 | −4)", "Das ist der Scheitel. Nullstellen sind die x-Werte mit f(x) = 0.", fehlbild="qf_scheitel_statt_nullstelle",
            ruecksprung="b3"),
        opt("x = 1", "x + 1 kann auch −2 sein. Dann ist x = −3.", fehlbild="qf_nur_positive_loesung", ruecksprung="b4"),
    ])]),
    check("b6", "Bestimme die Nullstellen von f(x) = x² − 3x.", [
        opt("x = 0 und x = 3", "Genau. x · (x − 3) = 0.", richtig=True),
        opt("x = 3", "Der Faktor x kann auch null sein: x = 0.", fehlbild="qf_null_vergessen", ruecksprung="b6"),
        opt("x = 0 und x = −3", "Aus x − 3 = 0 folgt x = 3.", fehlbild="qf_nullprodukt_vorzeichen", ruecksprung="b6"),
    ], [("Bestimme die Nullstellen von f(x) = x² − 7x.", [
        opt("x = 0 und x = 7", "Genau. x · (x − 7) = 0.", richtig=True),
        opt("x = 7", "Der Faktor x kann auch null sein: x = 0.", fehlbild="qf_null_vergessen", ruecksprung="b6"),
        opt("x = 0 und x = −7", "Aus x − 7 = 0 folgt x = 7.", fehlbild="qf_nullprodukt_vorzeichen", ruecksprung="b6"),
    ])]),
])
print("ok")
