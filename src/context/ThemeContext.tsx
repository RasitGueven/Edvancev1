import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import { THEMES, type Theme, type ThemeColors } from '@/types'

const STORAGE_KEY = 'edvance:theme'
const DEFAULT_THEME: Theme = 'edvance'

export const THEME_PREVIEW: Record<Theme, ThemeColors> = {
  edvance: { primary: '#4567C6', light: '#F8F5EE', dark: '#102038' },
  ocean: { primary: '#0E7490', light: '#67E8F9', dark: '#164E63' },
  forest: { primary: '#166534', light: '#86EFAC', dark: '#14532D' },
  sunset: { primary: '#C2410C', light: '#FDBA74', dark: '#7C2D12' },
}

type ThemeContextValue = {
  theme: Theme
  setTheme: (theme: Theme) => void
}

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined)

function readStoredTheme(): Theme {
  if (typeof window === 'undefined') return DEFAULT_THEME
  const stored = window.localStorage.getItem(STORAGE_KEY)
  return (THEMES as readonly string[]).includes(stored ?? '') ? (stored as Theme) : DEFAULT_THEME
}

function applyTheme(theme: Theme): void {
  if (typeof document === 'undefined') return
  if (theme === DEFAULT_THEME) {
    document.documentElement.removeAttribute('data-theme')
  } else {
    document.documentElement.setAttribute('data-theme', theme)
  }
}

export function ThemeProvider({ children }: { children: ReactNode }): JSX.Element {
  const [theme, setThemeState] = useState<Theme>(() => readStoredTheme())

  useEffect(() => {
    applyTheme(theme)
    window.localStorage.setItem(STORAGE_KEY, theme)
  }, [theme])

  const setTheme = (next: Theme): void => setThemeState(next)

  return <ThemeContext.Provider value={{ theme, setTheme }}>{children}</ThemeContext.Provider>
}

export function useThemeContext(): ThemeContextValue {
  const ctx = useContext(ThemeContext)
  if (!ctx) throw new Error('useThemeContext must be used within a ThemeProvider')
  return ctx
}

export { THEMES }
export type { Theme }
