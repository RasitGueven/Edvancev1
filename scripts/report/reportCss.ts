// Eltern-Report — das Stylesheet der HTML-Entwürfe (R4).
//
// Der Entwurfsstand des Elternbereichs: hell und flach, kein Glass. Das ist die
// Parent-Sprache, nicht die Schüler-Sprache — Gradients, Glass und Bounce
// bleiben im Schüler-Surface (CLAUDE §11, Hard Limits).
//
// Gegenüber dem Stand vor R4 sind die Diagramm-Klassen entfallen
// (.charts/.chartcard/.legend). Begründung steht in reportHtml.ts. Dazugekommen
// sind der Untertitel der Ebenenzeile, der Kommentar unter der Ebenenspur, der
// Rückbezug im Schluss und die Kontaktzeile.

export const REPORT_CSS = `
:root{
  --primary:#334D7A; --primary-hover:#253D6A; --primary-light:#EEF2F8;
  --app-bg:#F7F7F5; --surface:#FFFFFF; --subtle:#EFEFED; --border:#E8E8E5;
  --t1:#1A1A18; --t2:#4A4A47; --t3:#888884;
  --gap:#C03030; --gap-bg:#FADEDC;
  --str:#3AAF6A; --str-bg:#EAF7EF;
  --gold:#C49A2A;
  --r-sm:6px; --r-md:10px; --r-lg:14px; --r-xl:20px;
  --sh-xs:0 1px 3px rgba(51,77,122,.06);
  --sh-md:0 4px 12px rgba(51,77,122,.10);
}
*{box-sizing:border-box}
body{margin:0;background:var(--app-bg);color:var(--t1);
  font-family:'Schibsted Grotesk',system-ui,sans-serif;font-size:16px;line-height:1.6;
  padding:28px 16px 80px}
h1,h2,h3,h4{font-family:'Fraunces',Georgia,serif;margin:0;font-weight:600}
p{margin:0}

.wrap{max-width:900px;margin:0 auto}
.note{background:#fff;border:1px solid var(--border);border-left:3px solid var(--primary);
  border-radius:var(--r-md);padding:14px 18px;margin-bottom:26px;font-size:14px;color:var(--t2)}
.note b{color:var(--t1)}
.note code{font-size:12.5px}

.sheet{background:var(--surface);border:1px solid var(--border);border-radius:var(--r-lg);
  padding:44px 48px 52px;margin-bottom:40px;box-shadow:var(--sh-xs)}

.eyebrow{font-size:11px;letter-spacing:.15em;text-transform:uppercase;font-weight:600;color:var(--t3)}
header{border-bottom:1px solid var(--border);padding-bottom:20px;margin-bottom:32px}
header h1{font-size:34px;line-height:1.15;margin:8px 0 14px}
.meta{display:flex;flex-wrap:wrap;gap:4px 28px;font-size:14px;color:var(--t2)}
.meta b{color:var(--t1);font-weight:600}

section{margin-bottom:34px}
.step{display:flex;align-items:baseline;gap:10px;margin-bottom:12px}
.step-n{font-family:'Fraunces',serif;font-size:13px;font-weight:600;color:var(--gold);
  letter-spacing:.04em;flex:none}
.step h3{font-size:20px}
.sub{font-size:14px;color:var(--t3);margin-bottom:14px}

.lead-copy{font-size:17px;line-height:1.7;color:var(--t1)}
.lead-copy .em{background:linear-gradient(transparent 62%, #F3E7C8 62%);font-weight:500}

/* Suche / Abstieg */
.descent{background:var(--primary-light);border-radius:var(--r-lg);padding:22px 24px}
.layers{display:flex;flex-direction:column;gap:6px;margin-top:16px}

/* Zwei Zeilen statt einer: oben die Spur, darunter die Bereiche, die auf
   dieser Ebene tatsaechlich liegen. "Zwei Ebenen tiefer" allein sagt nichts. */
.layer{background:#fff;border-radius:var(--r-md);padding:9px 14px}
.layer .row{display:grid;grid-template-columns:118px 1fr auto;align-items:center;gap:14px;
  font-size:14px}
.layer .lv{font-size:12px;color:var(--t3);letter-spacing:.04em}
.layer .track{height:8px;border-radius:99px;background:var(--subtle);overflow:hidden;display:flex}
.layer .ok{background:var(--str)}
.layer .no{background:var(--gap)}
.layer .cnt{font-size:13px;color:var(--t2);font-variant-numeric:tabular-nums;white-space:nowrap}
.layer .was{margin:5px 0 0 132px;font-size:12.5px;line-height:1.5;color:var(--t2)}

/* Der Kommentar unter der Spur — Einbruch und tragende Sohle. */
.descent-note{margin-top:16px;padding-top:14px;border-top:1px solid rgba(51,77,122,.12);
  display:flex;flex-direction:column;gap:6px;font-size:14.5px;line-height:1.6;color:var(--t2)}
.descent-note b{color:var(--t1);font-weight:600}

/* Profil ueber die Themenfamilien — das Bild, auf das der Coach zeigt. */
.profil{background:#fff;border:1px solid var(--border);border-radius:var(--r-lg);
  padding:18px 20px 14px;margin-bottom:16px;
  display:grid;grid-template-columns:260px 1fr;gap:22px;align-items:center}
.profil h4{font-size:15px;margin-bottom:4px}
.profil .cap{font-size:13px;color:var(--t3);line-height:1.55}
/* Legende: die beiden Linien beim Namen nennen. Ohne sie ist die aeussere
   Flaeche nur eine blasse Kontur ohne Bedeutung. */
.profil .legende{list-style:none;margin:10px 0;padding:0;
  display:flex;flex-direction:column;gap:6px;font-size:12.5px;color:var(--t2)}
.profil .legende li{display:flex;align-items:center;gap:8px;line-height:1.45}
.profil .legende b{color:var(--t1);font-weight:600}
.profil .legende span{flex:none;width:26px;height:0;border-top-width:2px}
.profil .l-aussen{border-top-style:dashed;border-top-color:rgba(51,77,122,.45)}
.profil .l-innen{border-top-style:solid;border-top-color:var(--primary)}

.profil .nenner{margin-top:12px;padding-top:10px;border-top:1px solid var(--subtle);
  font-size:11.5px;line-height:1.7;color:var(--t3)}
/* Ohne Deckel fuellt das SVG auf schmalen Schirmen die ganze Breite und
   ueberragt alles andere — das Profil ist ein Beleg, kein Plakat. */
.profil svg{display:block;max-width:280px;margin:0 auto}

/* Befund */
.two{display:grid;grid-template-columns:1fr 1fr;gap:16px;align-items:start}
.box{border-radius:var(--r-lg);padding:20px 22px}
.box.good{background:var(--str-bg)}
.box.bad{background:var(--gap-bg)}
.box h4{font-size:15px;margin-bottom:10px}
.box.good h4{color:#1F6E42}
.box.bad h4{color:#8C2323}
.box ul{margin:0;padding-left:18px;font-size:15px;color:var(--t2);line-height:1.75}
.tiefe{margin-top:12px;font-size:13px;color:var(--t2);border-top:1px solid rgba(0,0,0,.07);padding-top:10px}

/* Muster */
.muster{list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:10px}
.muster li{background:var(--app-bg);border-left:3px solid var(--primary);border-radius:var(--r-md);
  padding:16px 18px;font-size:16px;line-height:1.65}

/* Fazit + Empfehlung */
.close{background:var(--primary);color:#fff;border-radius:var(--r-lg);padding:28px 30px;margin-top:6px}
.close h3{color:#fff;font-size:20px;margin-bottom:12px}
.close p{font-size:16.5px;line-height:1.7;color:rgba(255,255,255,.93)}

/* Der Aufgriff der Eltern-Einschaetzung. Abgesetzt, weil er eine Frage
   beantwortet, die die Eltern gestellt haben — nicht eine, die wir stellen. */
.rueck{margin-top:20px;padding-top:18px;border-top:1px solid rgba(255,255,255,.22);
  display:flex;flex-direction:column;gap:10px}
.rueck .rb{display:flex;gap:12px;align-items:flex-start;font-size:15.5px;line-height:1.6;
  color:rgba(255,255,255,.92)}
.rueck .mark{flex:none;width:22px;height:22px;border-radius:99px;display:grid;place-items:center;
  font-size:12px;font-weight:700;margin-top:2px}
.rueck .mark.ok{background:rgba(58,175,106,.9);color:#0B2E1A}
.rueck .mark.hit{background:rgba(232,213,163,.9);color:#4A3708}
/* Weder Befund noch Entlastung: die Analyse gibt dazu nichts her. Bewusst
   farblos — jede Farbe waere hier eine Wertung, die niemand belegt hat. */
.rueck .mark.off{background:rgba(255,255,255,.28);color:rgba(255,255,255,.92)}

.paket{margin-top:22px;padding-top:20px;border-top:1px solid rgba(255,255,255,.22);
  display:flex;flex-wrap:wrap;gap:18px;align-items:flex-start;justify-content:space-between}
.paket .name{font-family:'Fraunces',serif;font-size:22px;font-weight:600;color:#E8D5A3}
.paket .freq{font-size:13px;color:rgba(255,255,255,.7);margin-top:2px}
.paket .why{flex:1;min-width:280px;font-size:15px;line-height:1.65;color:rgba(255,255,255,.9)}
.paket .off{font-size:13px;color:rgba(255,255,255,.62);margin-top:10px}

details.deep{border:1px solid var(--border);border-radius:var(--r-lg);background:#fff}
details.deep summary{cursor:pointer;padding:16px 20px;font-weight:600;font-size:15px;list-style:none;
  display:flex;justify-content:space-between;align-items:center}
details.deep summary::-webkit-details-marker{display:none}
details.deep summary::after{content:"▾";color:var(--t3);font-size:13px}
details.deep[open] summary::after{content:"▴"}
details.deep .body{padding:0 20px 20px;font-size:15px;color:var(--t2);line-height:1.7}
details.deep .stufe{margin-top:14px}
details.deep .stufe .lv{font-size:11px;letter-spacing:.12em;text-transform:uppercase;
  font-weight:600;color:var(--t3)}
details.deep .stufe ul{padding-left:18px;margin:4px 0 0}

/* Ansprechpartner */
.kontakt{margin-top:34px;padding-top:18px;border-top:1px solid var(--border);
  font-size:13.5px;line-height:1.6;color:var(--t2)}
.kontakt b{color:var(--t1);font-weight:600}
.kontakt a{color:var(--primary)}

@media(max-width:760px){
  .two{grid-template-columns:1fr}
  .profil{grid-template-columns:1fr}
  .sheet{padding:28px 22px 34px}
  .layer .row{grid-template-columns:96px 1fr auto;gap:10px}
  .layer .was{margin-left:0}
}
@media print{
  body{background:#fff;padding:0}
  .note{display:none}
  .sheet{border:0;box-shadow:none;padding:0}
  details.deep[open] .body,details.deep .body{display:block !important}
  @page{size:A4;margin:15mm}
}
`
