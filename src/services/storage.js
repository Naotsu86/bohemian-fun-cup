export const STORAGE_KEY = 'bohemian-fun-cup-v3'
export const ADMIN_SESSION_KEY = 'bfc-admin-unlocked'
export const GITHUB_TOKEN_KEY = 'bfc-github-token'

export function uuid() {
  return crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${Math.random().toString(36).slice(2)}`
}

export function defaultState() {
  return {
    players: [],
    matches: [],
    rules:
      'Gespielt wird bis 21 Punkte. Die erzielten Teampunkte werden jedem Spieler des jeweiligen Teams gutgeschrieben. Beispiel: 21:12 bedeutet 21 Punkte für alle Spieler des einen Teams und 12 Punkte für alle Spieler des anderen Teams. Bei Punktegleichstand auf den ersten drei Plätzen kann ein kurzes Entscheidungsspiel gespielt werden.',
    settings: {
      mode: '4v4',
      count: 1,
      adminPin: '2026',
      winForm: 0.01,
      lossForm: -0.01,
      githubOwner: 'Naotsu86',
      githubRepo: 'bohemian-fun-cup',
      githubBranch: 'main',
      livePath: 'public/data/live.json',
      autoRefreshSeconds: 30
    },
    live: {
      lastLoadedAt: null,
      lastPublishedAt: null,
      message: ''
    }
  }
}

export function loadState() {
  try {
    const saved = localStorage.getItem(STORAGE_KEY)
    if (!saved) return defaultState()

    const parsed = JSON.parse(saved)
    const base = defaultState()

    return {
      ...base,
      ...parsed,
      players: Array.isArray(parsed.players) ? parsed.players : [],
      matches: Array.isArray(parsed.matches) ? parsed.matches : [],
      settings: { ...base.settings, ...(parsed.settings || {}) },
      live: { ...base.live, ...(parsed.live || {}) }
    }
  } catch {
    return defaultState()
  }
}

export function saveState(state) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state))
}
