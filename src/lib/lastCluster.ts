const KEY = 'edvance_last_cluster'

export type LastCluster = { id: string; name: string }

export function saveLastCluster(id: string, name: string): void {
  try {
    localStorage.setItem(KEY, JSON.stringify({ id, name }))
  } catch {
    // localStorage may be unavailable in private mode
  }
}

export function getLastCluster(): LastCluster | null {
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) return null
    return JSON.parse(raw) as LastCluster
  } catch {
    return null
  }
}
