// Slots W2: Die Termin-Seite ist im Slot-Panel aufgegangen (panel/). Diese Datei hält nur den Import der
// Kind-Seite (kind/KindKarten.tsx, Paket W3) stabil, damit W2 und W3 nicht dieselbe Zeile ändern.
// Nach dem Merge von W3 den Import dort auf '../panel/TerminKarten' umstellen und diese Datei löschen.
export { ZustandBadge } from '../panel/TerminKarten'
