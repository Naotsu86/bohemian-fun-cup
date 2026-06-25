export function isFinished(match) {
  return match.score_a !== null && match.score_b !== null && match.score_a !== '' && match.score_b !== ''
}
export function getOpenMatches(matches) { return matches.filter((match) => !isFinished(match)) }
export function gamesPlayed(playerId, matches) {
  return matches.filter((m) => (m.team_a || []).includes(playerId) || (m.team_b || []).includes(playerId)).length
}
export function buildRanking(players, matches) {
  const result = Object.fromEntries(players.map((p) => [p.id, { id:p.id, name:p.name, points:0, games:0, wins:0, losses:0, diff:0, avg:0 }]))
  for (const m of matches) {
    if (!isFinished(m)) continue
    const a = Number(m.score_a), b = Number(m.score_b)
    for (const id of m.team_a || []) if (result[id]) { result[id].points += a; result[id].games++; result[id].diff += a-b; if (a>b) result[id].wins++; if (a<b) result[id].losses++ }
    for (const id of m.team_b || []) if (result[id]) { result[id].points += b; result[id].games++; result[id].diff += b-a; if (b>a) result[id].wins++; if (b<a) result[id].losses++ }
  }
  return Object.values(result).map(r => ({...r, avg: r.games ? Number((r.points/r.games).toFixed(2)) : 0}))
    .sort((a,b) => b.points-a.points || b.wins-a.wins || b.diff-a.diff || a.name.localeCompare(b.name))
}
