import { createContext, useContext } from 'react'

/**
 * Sagt einer Seite, ob sie in der Hülle steht. Seiten, die eine Rolle mit und
 * eine ohne Hülle teilen (Schülerakte: Admin und Coach), bauen außerhalb der
 * Hülle ihren bisherigen Rahmen selbst.
 */
export const ShellContext = createContext(false)

export function useImShell(): boolean {
  return useContext(ShellContext)
}
