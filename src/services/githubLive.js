function toBase64Utf8(value) {
  return btoa(unescape(encodeURIComponent(value)))
}

export function createPublicLiveData(state) {
  return {
    version: Date.now(),
    publishedAt: new Date().toISOString(),
    players: state.players.map((p) => ({ id: p.id, name: p.name })),
    matches: state.matches.map((m) => ({
      id: m.id,
      mode: m.mode,
      teamA: m.teamA,
      teamB: m.teamB,
      scoreA: m.scoreA,
      scoreB: m.scoreB,
      createdAt: m.createdAt || null,
    })),
    rules: state.rules,
  }
}

export async function fetchLiveJson({ basePath = '/bohemian-fun-cup/' } = {}) {
  const url = `${basePath.replace(/\/$/, '')}/data/live.json?t=${Date.now()}`
  const response = await fetch(url, { cache: 'no-store' })
  if (!response.ok) throw new Error('Live-Daten konnten nicht geladen werden.')
  return response.json()
}

export async function publishLiveJson({ owner, repo, branch, path, token, liveData }) {
  if (!owner || !repo || !branch || !path) throw new Error('GitHub-Einstellungen sind unvollständig.')
  if (!token) throw new Error('GitHub Token fehlt.')

  const apiUrl = `https://api.github.com/repos/${owner}/${repo}/contents/${path}`

  let sha = null
  const current = await fetch(`${apiUrl}?ref=${encodeURIComponent(branch)}`, {
    headers: {
      Accept: 'application/vnd.github+json',
      Authorization: `Bearer ${token}`,
      'X-GitHub-Api-Version': '2022-11-28',
    },
  })

  if (current.ok) {
    const json = await current.json()
    sha = json.sha
  } else if (current.status !== 404) {
    throw new Error('Aktuelle Live-Datei konnte nicht geprüft werden.')
  }

  const body = {
    message: 'Update Bohemian Fun Cup live data',
    content: toBase64Utf8(JSON.stringify(liveData, null, 2)),
    branch,
  }

  if (sha) body.sha = sha

  const response = await fetch(apiUrl, {
    method: 'PUT',
    headers: {
      Accept: 'application/vnd.github+json',
      Authorization: `Bearer ${token}`,
      'X-GitHub-Api-Version': '2022-11-28',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({}))
    throw new Error(error.message || 'Live-Daten konnten nicht veröffentlicht werden.')
  }

  return response.json()
}
