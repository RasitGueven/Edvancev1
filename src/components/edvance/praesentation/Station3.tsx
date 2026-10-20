import { useLayoutEffect, useRef } from "react";
import { useTranslation } from "react-i18next";

import {
  legendeFuer,
  useLernwegTexte,
} from "@/components/edvance/elternbericht/lernwegTexte";
import type { Lernweg } from "@/types";

import { Kicker } from "./Kicker";
import { LernwegBuehne } from "./LernwegBuehne";
import type { StationProps } from "./stationProps";
import { useLernwegFahrt } from "./useLernwegFahrt";

/**
 * Station 03 · Lernweg (R7-9, Entscheidung 19): derselbe Lernweg wie Seite 3
 * des Berichts (p.lernweg), als waagrechte Bühne, die sich beim ersten
 * Betreten Bereich für Bereich aufbaut. Kopf und Legende wie im Prototyp
 * Version 7; die Legende mit denselben Texten wie der Druck.
 */
export function Station3({ p }: StationProps): JSX.Element {
  const { t } = useTranslation("praesentation");
  const { t: tb } = useTranslation("elternbericht");
  return (
    <div className="tp-szene tp-s3">
      <Kicker nummer={3}>{t("s3.kicker")}</Kicker>
      {p.lernweg ? (
        <Weg lw={p.lernweg} titel={tb("s3.titel")} />
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

/** Im Querformat stehen Titel, Satz und „Weg abspielen“ in einer Zeile (Nachbesserung, Entscheidung 3). */
function Weg({ lw, titel }: { lw: Lernweg; titel: string }): JSX.Element {
  const { t } = useTranslation("praesentation");
  const tx = useLernwegTexte(lw);
  const f = useLernwegFahrt(lw);
  const satz = useSatzEinzeilig();
  const quelle =
    lw.quelle === "klp"
      ? t("s3.weg.quelle.klp")
      : lw.schulname
        ? t("s3.weg.quelle.schule", { schulname: lw.schulname })
        : t("s3.weg.quelle.schuleOhneName");
  return (
    <>
      <div className="tp-s3-kopfzeile">
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
