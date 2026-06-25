export function isFinished(match) {
  return match.scoreA !== '' && match.scoreB !== '' && match.scoreA != null && match.scoreB != null
}

export function getOpenMatches(matches) {
  return matches.filter((m) => !isFinished(m))
}

export function buildRanking(players, matches) {
  const result = Object.fromEntries(
    players.map((p) => [
      p.id,
      { id: p.id, name: p.name, points: 0, games: 0, wins: 0, losses: 0, diff: 0, avg: 0 },
    ]),
  )

  for (const match of matches) {
    if (!isFinished(match)) continue

    const a = Number(match.scoreA)
    const b = Number(match.scoreB)

    for (const id of match.teamA) {
      if (!result[id]) continue
      result[id].points += a
      result[id].diff += a - b
      result[id].games += 1
      if (a > b) result[id].wins += 1
      if (a < b) result[id].losses += 1
    }

    for (const id of match.teamB) {
      if (!result[id]) continue
      result[id].points += b
      result[id].diff += b - a
      result[id].games += 1
      if (b > a) result[id].wins += 1
      if (b < a) result[id].losses += 1
    }
  }

  return Object.values(result)
    .map((row) => ({ ...row, avg: row.games ? Number((row.points / row.games).toFixed(2)) : 0 }))
    .sort((a, b) => b.points - a.points || b.wins - a.wins || b.diff - a.diff || a.name.localeCompare(b.name))
}
