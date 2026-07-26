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

function rankingSort(a, b) {
  return (
    b.points - a.points ||
    b.wins - a.wins ||
    b.diff - a.diff ||
    a.name.localeCompare(b.name)
  )
}

function winRate(wins, games) {
  if (!games) return 0
  return Number(((wins / games) * 100).toFixed(1))
}

export function buildRanking(players) {
  const rows = players.map(player => {
    const points = Number(player.score_total || 0)
    const games = Number(player.score_games || 0)
    const wins = Number(player.score_wins || 0)
    const diff = Number(player.score_diff || 0)

    return {
      id: player.id,
      name: player.name,
      active: player.active !== false,
      points,
      games,
      wins,
      diff,
      win_rate: winRate(wins, games),

      previous_points: Number(player.previous_score_total || 0),
      previous_games: Number(player.previous_score_games || 0),
      previous_wins: Number(player.previous_score_wins || 0),
      previous_diff: Number(player.previous_score_diff || 0),
      has_rank_history: player.has_rank_history === true,

      rank_change: 0,
      previous_rank: null,
      current_rank: null,

      pause_points: Number(player.score_pause_points || 0),
      absence_points: Number(player.score_absence_points || 0),

      body_color: player.body_color,
      belly_color: player.belly_color,
      head_item: player.head_item,
      top_item: player.top_item,
      bottom_item: player.bottom_item,
      shorts_item: player.shorts_item,
      accessory_item: player.accessory_item,

      selected_title_id: player.selected_title_id,
      selected_title_name: player.selected_title_name,
      selected_title_description: player.selected_title_description,

      selected_special_attack_id: player.selected_special_attack_id,
      selected_special_attack_name: player.selected_special_attack_name,
      selected_special_attack_description: player.selected_special_attack_description,

      xp_total: Number(player.xp_total || points),
      calculated_level: Number(player.calculated_level || 1),
      current_level_xp: Number(player.current_level_xp || 0),
      next_level_xp: Number(player.next_level_xp || 25),

      stat_teamgeist: Number(player.stat_teamgeist || 0),
      stat_geschwindigkeit: Number(player.stat_geschwindigkeit || 0),
      stat_kraft: Number(player.stat_kraft || 0),
      stat_technik: Number(player.stat_technik || 0),
      stat_ehrgeiz: Number(player.stat_ehrgeiz || 0)
    }
  })
  const maxGames = rows.reduce(
  (maximum, row) => Math.max(maximum, row.games),
  0
)

rows.forEach(row => {
  row.average_points = maxGames
    ? Number((row.points / maxGames).toFixed(1))
    : 0
})

  const currentRows = [...rows].sort(rankingSort)

  const previousRows = rows
    .map(row => ({
      id: row.id,
      name: row.name,
      points: row.previous_points,
      games: row.previous_games,
      wins: row.previous_wins,
      diff: row.previous_diff
    }))
    .sort(rankingSort)

  const previousRankById = Object.fromEntries(
    previousRows.map((row, index) => [row.id, index + 1])
  )

  return currentRows.map((row, index) => {
    const currentRank = index + 1
    const previousRank = previousRankById[row.id] || currentRank

    return {
      ...row,
      current_rank: currentRank,
      previous_rank: previousRank,

      // Positiv = nach oben gestiegen, negativ = Plätze verloren.
      rank_change: row.has_rank_history
        ? previousRank - currentRank
        : 0
    }
  })
}

export function gamesPlayed(id, matches) {
  return matches.filter(
    match =>
      (match.team_a || []).includes(id) ||
      (match.team_b || []).includes(id)
  ).length
}
