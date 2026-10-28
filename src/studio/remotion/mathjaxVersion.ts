// mathjax-full/js/components/version.js liest seine Version per eval('require') aus package.json, wenn
// PACKAGE_VERSION fehlt — im Browser (Remotion-Bundle, Vite) gibt es kein require. Deshalb vor dem ersten
// MathJax-Import setzen (formel.tsx importiert diese Datei zuerst).
;(globalThis as { PACKAGE_VERSION?: string }).PACKAGE_VERSION ??= '3.2.1'
export {}
