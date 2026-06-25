export function isFinished(match) {
  return match.score_a !== null && match.score_b !== null && match.score_a !== '' && match.score_b !== ''
}

export function getOpenMatches(matches) {
  return matches.filter((m) => !isFinished(m))
}

export function buildRanking(players, matches) {
  const rows = Object.fromEntries(players.map((p) => [p.id, {
    id: p.id, name: p.name, points: 0, games: 0, wins: 0, diff: 0, avg: 0
  }]))

  for (const m of matches) {
    if (!isFinished(m)) continue
    const a = Number(m.score_a)
    const b = Number(m.score_b)

    for (const id of m.team_a || []) {
      if (!rows[id]) continue
      rows[id].points += a
      rows[id].games += 1
      rows[id].diff += a - b
      if (a > b) rows[id].wins += 1
    }

    for (const id of m.team_b || []) {
      if (!rows[id]) continue
      rows[id].points += b
      rows[id].games += 1
      rows[id].diff += b - a
      if (b > a) rows[id].wins += 1
    }
  }

  return Object.values(rows)
    .map((r) => ({ ...r, avg: r.games ? Number((r.points / r.games).toFixed(2)) : 0 }))
    .sort((a, b) => b.points - a.points || b.wins - a.wins || b.diff - a.diff || a.name.localeCompare(b.name))
}

export function gamesPlayed(id, matches) {
  return matches.filter((m) => (m.team_a || []).includes(id) || (m.team_b || []).includes(id)).length
}
