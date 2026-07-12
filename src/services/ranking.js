export function isFinished(match) {
  return (
    match.score_a !== null &&
    match.score_b !== null &&
    match.score_a !== '' &&
    match.score_b !== ''
  )
}

export function getOpenMatches(matches) {
  return matches.filter(match => !isFinished(match))
}

export function buildRanking(players, matches) {
  const rows = Object.fromEntries(
    players.map(player => [
      player.id,
      {
        id: player.id,
        name: player.name,
        active: player.active !== false,
        points: 0,
        games: 0,
        wins: 0,
        diff: 0,
        avg: 0,
        pause_points: 0,
        body_color: player.body_color,
        belly_color: player.belly_color,
        head_item: player.head_item,
        shorts_item: player.shorts_item,
        accessory_item: player.accessory_item
      }
    ])
  )

  for (const match of matches) {
    if (!isFinished(match)) continue

    const scoreA = Number(match.score_a)
    const scoreB = Number(match.score_b)
    const loserPoints = Math.min(scoreA, scoreB)

    for (const id of match.team_a || []) {
      if (!rows[id]) continue

      rows[id].points += scoreA
      rows[id].games += 1
      rows[id].diff += scoreA - scoreB

      if (scoreA > scoreB) rows[id].wins += 1
    }

    for (const id of match.team_b || []) {
      if (!rows[id]) continue

      rows[id].points += scoreB
      rows[id].games += 1
      rows[id].diff += scoreB - scoreA

      if (scoreB > scoreA) rows[id].wins += 1
    }

    // Pausierende Spieler erhalten die Punkte des Verliererteams.
    // Der Einsatz zählt nicht als gespieltes Spiel, damit sie beim
    // nächsten Generatorlauf bevorzugt aufgestellt werden.
    for (const id of match.bench_players || []) {
      if (!rows[id]) continue

      rows[id].points += loserPoints
      rows[id].pause_points += loserPoints
    }
  }

  return Object.values(rows)
    .map(row => ({
      ...row,
      avg: row.games ? Number((row.points / row.games).toFixed(2)) : 0
    }))
    .sort(
      (a, b) =>
        b.points - a.points ||
        b.wins - a.wins ||
        b.diff - a.diff ||
        a.name.localeCompare(b.name)
    )
}

export function gamesPlayed(id, matches) {
  return matches.filter(
    match =>
      (match.team_a || []).includes(id) ||
      (match.team_b || []).includes(id)
  ).length
}
