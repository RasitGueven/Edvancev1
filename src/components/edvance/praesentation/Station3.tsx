import { useCallback, useEffect, useId, useLayoutEffect, useMemo, useRef, useState } from "react";
import { useTranslation } from "react-i18next";

import {
  legendeFuer,
  useLernwegTexte,
} from "@/components/edvance/elternbericht/lernwegTexte";
import {
  KUERZUNGEN,
  STUFE_BEREICHE,
  kuerzeLernweg,
  type ThemaVorrang,
} from "@/lib/report/elternbericht/lernweg";
import { kette } from "@/lib/report/praesentation/kette";
import type { Lernweg } from "@/types";

import { Kicker } from "./Kicker";
import { Lernkette } from "./Lernkette";
import { LernwegBuehne } from "./LernwegBuehne";
import type { StationProps } from "./stationProps";
import { useLernwegFahrt } from "./useLernwegFahrt";

/**
 * Station 03 · Lernweg (R7-9, Entscheidung 19; PS-1 Entscheidungen 10–15):
 * zuerst die Kette „Der Weg zum Thema" (Lernkette). „Ganzen Lernweg zeigen"
 * öffnet in derselben Station die volle Karte wie Seite 3 des Berichts
 * (p.lernweg) als waagrechte Bühne mit Fahrt, „Zurück zum Weg" schließt sie.
 * Ohne Kette (kein Schwerpunkt, kein Thema) steht die volle Karte wie bisher.
 */
export function Station3({ p }: StationProps): JSX.Element {
  const { t } = useTranslation("praesentation");
  const { t: tb } = useTranslation("elternbericht");
  const k = useMemo(() => kette(p), [p]);
  const [ganz, setGanz] = useState(false);
  const [zurueck, setZurueck] = useState(false);
  const titelId = useId();
  const knopf = useRef<HTMLButtonElement>(null);
  const umgeschaltet = useRef(false);

  // Nach dem Umschalten bekommt der Knopf der anderen Ansicht den Fokus.
  useEffect(() => {
    if (umgeschaltet.current) knopf.current?.focus({ preventScroll: true });
  }, [ganz]);

  const umschalten = (): void => {
    umgeschaltet.current = true;
    if (ganz) setZurueck(true);
    setGanz((g) => !g);
  };

  const zeigeKette = k && !ganz;
  return (
    <div className={zeigeKette ? "tp-szene tp-s3 tp-s3-mit-kette" : "tp-szene tp-s3"}>
      <div className="tp-s3-kopfreihe">
        <Kicker nummer={3}>{t("s3.kicker")}</Kicker>
        {k && p.lernweg && (
          <button
            ref={knopf}
            type="button"
            className="tp-s3-umschalten tp-reveal"
            data-testid={ganz ? "tp-s3-zurueck" : "tp-s3-ganz"}
            onClick={umschalten}
          >
            {t(ganz ? "s3.kette.zurueck" : "s3.kette.ganzerWeg")}
          </button>
        )}
      </div>
      {zeigeKette ? (
        <>
          <h2 id={titelId} className="tp-titel tp-reveal" data-tp-pflicht="">
            {t(k.fall === "feld" ? "s3.kette.titelFeld" : "s3.kette.titel")}
          </h2>
          <Lernkette k={k} titelId={titelId} still={zurueck} />
        </>
      ) : p.lernweg ? (
        <Weg
          voll={p.lernweg}
          thema={p.schwerpunkte.find((s) => s.feld === null) ?? null}
          titel={tb("s3.titel")}
        />
      ) : (
        <h2 className="tp-titel tp-reveal" data-tp-pflicht="">
          {tb("s3.titel")}
        </h2>
      )}
    </div>
  );
}

/**
 * Im Querformat steht der Satz einzeilig neben „Weg abspielen“; passt er nicht
 * in eine Zeile, entfällt er dort (Nachbesserung, Entscheidung 3). Gemessen im
 * Layout-Effekt: kurz zeigen, messen, wieder verbergen — ohne Flackern.
 */
function useSatzEinzeilig(): React.RefObject<HTMLParagraphElement> {
  const ref = useRef<HTMLParagraphElement>(null);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    const pruefen = (): void => {
      el.classList.remove("tp-s3-aus");
      const quer =
        typeof window.matchMedia === "function" &&
        window.matchMedia("(orientation: landscape)").matches;
      if (quer && el.scrollWidth > el.clientWidth + 1)
        el.classList.add("tp-s3-aus");
    };
    pruefen();
    void document.fonts?.ready.then(pruefen);
    const ro =
      typeof ResizeObserver === "undefined"
        ? null
        : new ResizeObserver(pruefen);
    if (el.parentElement) ro?.observe(el.parentElement);
    return () => ro?.disconnect();
  }, []);
  return ref;
}

/**
 * Im Querformat stehen Titel, Satz und „Weg abspielen“ in einer Zeile
 * (Nachbesserung, Entscheidung 3). Die Bühne zeigt den Lernweg gekürzt ab
 * Stufe 4; ragt beim Messen eine Insel auch bei der kleinsten Skala über die
 * Spur, nimmt sie die nächste Stufe (R7-12, Entscheidungen 9 und 10).
 */
function Weg({
  voll,
  thema,
  titel,
}: {
  voll: Lernweg;
  thema: ThemaVorrang;
  titel: string;
}): JSX.Element {
  const { t } = useTranslation("praesentation");
  const [stufe, setStufe] = useState(STUFE_BEREICHE);
  const lw = useMemo(
    () => kuerzeLernweg(voll, KUERZUNGEN[stufe], thema),
    [voll, stufe, thema],
  );
  const weiter = useCallback((): boolean => {
    if (stufe >= KUERZUNGEN.length - 1) return false;
    setStufe(stufe + 1);
    return true;
  }, [stufe]);
  const tx = useLernwegTexte(lw);
  const f = useLernwegFahrt(lw, weiter);
  const satz = useSatzEinzeilig();
  const quelle =
    lw.quelle === "klp"
      ? t("s3.weg.quelle.klp")
      : lw.schulname
        ? t("s3.weg.quelle.schule", { schulname: lw.schulname })
        : t("s3.weg.quelle.schuleOhneName");
  return (
    <>
      <div className="tp-s3-kopfzeile" data-stufe={stufe}>
        <h2 className="tp-titel tp-reveal" data-tp-pflicht="">
          {titel}
        </h2>
        <div className="tp-s3-unterkopf tp-reveal">
          <p ref={satz} className="tp-desc">
            {t("s3.weg.desc", { quelle })}
          </p>
          <button
            type="button"
            className="tp-s3-abspielen"
            aria-label={t("s3.weg.abspielenAria")}
            data-testid="tp-s3-abspielen"
            onClick={f.abspielen}
          >
            <svg viewBox="0 0 14 14" aria-hidden="true" focusable="false">
              <path d="M3 2 L12 7 L3 12 Z" />
            </svg>
            {t("s3.weg.abspielen")}
          </button>
        </div>
      </div>
      <ul className="tp-s3-legende tp-reveal" data-testid="tp-s3-legende">
        {legendeFuer(lw, true).map((a) => (
          <li key={a} className={`tp-s3-leg tp-s3-leg-${a}`} data-legende={a}>
            {a === "unter" && (
              <span className="tp-s3-pfeil" aria-hidden="true">
                ↳
              </span>
            )}
            {tx.legende(a)}
          </li>
        ))}
      </ul>
      <LernwegBuehne lw={lw} f={f} />
    </>
  );
}
