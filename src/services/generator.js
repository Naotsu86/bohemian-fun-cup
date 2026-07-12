import { gamesPlayed } from './ranking'

function shuffle(list) {
  return [...list].sort(() => Math.random() - 0.5)
}

function pairKey(a, b) {
  return [a, b].sort().join('|')
}

function strength(player) {
  return Number(player.strength || 1) + Number(player.form || 0)
}

function hasPlayed(match, playerId) {
  return (match.team_a || []).includes(playerId) || (match.team_b || []).includes(playerId)
}

function wasBenched(match, playerId) {
  return (match.bench_players || []).includes(playerId)
}

function lastMatchParticipation(playerId, matches) {
  for (let index = matches.length - 1; index >= 0; index -= 1) {
    const match = matches[index]

    if (hasPlayed(match, playerId)) return 'played'
    if (wasBenched(match, playerId)) return 'bench'
  }

  return 'none'
}

function benchCount(playerId, matches) {
  return matches.filter(match => wasBenched(match, playerId)).length
}

function history(matches) {
  const together = new Map()
  const against = new Map()

  for (const match of matches) {
    const teamA = match.team_a || []
    const teamB = match.team_b || []

    for (const team of [teamA, teamB]) {
      for (let i = 0; i < team.length; i += 1) {
        for (let j = i + 1; j < team.length; j += 1) {
          const key = pairKey(team[i], team[j])
          together.set(key, (together.get(key) || 0) + 1)
        }
      }
    }

    for (const playerA of teamA) {
      for (const playerB of teamB) {
        const key = pairKey(playerA, playerB)
        against.set(key, (against.get(key) || 0) + 1)
      }
    }
  }

  return { together, against }
}

function teamSum(team) {
  return team.reduce((sum, player) => sum + strength(player), 0)
}

function teamPenalty(team, matchHistory) {
  let penalty = 0

  for (let i = 0; i < team.length; i += 1) {
    for (let j = i + 1; j < team.length; j += 1) {
      penalty += matchHistory.together.get(pairKey(team[i].id, team[j].id)) || 0
    }
  }

  return penalty
}

function opponentPenalty(teamA, teamB, matchHistory) {
  let penalty = 0

  for (const playerA of teamA) {
    for (const playerB of teamB) {
      penalty += matchHistory.against.get(pairKey(playerA.id, playerB.id)) || 0
    }
  }

  return penalty
}

/**
 * Wählt die Spieler fair aus:
 * 1. Wer im vorherigen Match pausierte, wird stark bevorzugt.
 * 2. Wer bisher weniger echte Spiele hat, wird bevorzugt.
 * 3. Bei Gleichstand pausiert, wer bisher seltener pausierte.
 */
function selectPlayers(activePlayers, matches, needed) {
  const sorted = shuffle(activePlayers).sort((a, b) => {
    const lastA = lastMatchParticipation(a.id, matches)
    const lastB = lastMatchParticipation(b.id, matches)

    const lastBenchPriorityA = lastA === 'bench' ? 0 : 1
    const lastBenchPriorityB = lastB === 'bench' ? 0 : 1

    if (lastBenchPriorityA !== lastBenchPriorityB) {
      return lastBenchPriorityA - lastBenchPriorityB
    }

    const gamesA = gamesPlayed(a.id, matches)
    const gamesB = gamesPlayed(b.id, matches)

    if (gamesA !== gamesB) {
      return gamesA - gamesB
    }

    const benchesA = benchCount(a.id, matches)
    const benchesB = benchCount(b.id, matches)

    if (benchesA !== benchesB) {
      return benchesA - benchesB
    }

    return strength(b) - strength(a)
  })

  return {
    selected: sorted.slice(0, needed),
    benched: sorted.slice(needed)
  }
}

export function createNextMatch(players, matches, mode) {
  const [sizeA, sizeB] = String(mode).split('v').map(Number)
  const needed = sizeA + sizeB

  if (!sizeA || !sizeB) {
    throw new Error('Ungültiger Spielmodus.')
  }

  if (sizeA > 4 || sizeB > 4) {
    throw new Error('Es wird maximal 4 gegen 4 gespielt.')
  }

  const activePlayers = players.filter(player =>
    player.active !== false && player.approved !== false
  )

  if (activePlayers.length < needed) {
    throw new Error(
      `Für ${mode} brauchst du ${needed} aktive Spieler. Aktuell: ${activePlayers.length}.`
    )
  }

  const { selected, benched } = selectPlayers(activePlayers, matches, needed)
  const matchHistory = history(matches)

  let best = null

  for (let attempt = 0; attempt < 3000; attempt += 1) {
    const candidates = shuffle(selected)
    const teamA = candidates.slice(0, sizeA)
    const teamB = candidates.slice(sizeA, needed)
    const gameCounts = [...teamA, ...teamB].map(player =>
      gamesPlayed(player.id, matches)
    )

    const score =
      Math.abs(teamSum(teamA) - teamSum(teamB)) * 100 +
      (Math.max(...gameCounts) - Math.min(...gameCounts)) * 80 +
      (teamPenalty(teamA, matchHistory) + teamPenalty(teamB, matchHistory)) * 30 +
      opponentPenalty(teamA, teamB, matchHistory) * 8 +
      Math.random()

    if (!best || score < best.score) {
      best = { teamA, teamB, score }
    }
  }

  return {
    mode,
    team_a: best.teamA.map(player => player.id),
    team_b: best.teamB.map(player => player.id),
    bench_players: benched.map(player => player.id),
    score_a: null,
    score_b: null
  }
}

export function calculateForm(players, matches) {
  const form = Object.fromEntries(players.map(player => [player.id, 0]))

  for (const match of matches) {
    if (
      match.score_a === null ||
      match.score_b === null ||
      match.score_a === '' ||
      match.score_b === ''
    ) {
      continue
    }

    const scoreA = Number(match.score_a)
    const scoreB = Number(match.score_b)

    if (scoreA === scoreB) continue

    const winners = scoreA > scoreB ? match.team_a : match.team_b
    const losers = scoreA > scoreB ? match.team_b : match.team_a

    for (const id of winners || []) {
      form[id] = Number(((form[id] || 0) + 0.01).toFixed(2))
    }

    for (const id of losers || []) {
      form[id] = Number(((form[id] || 0) - 0.01).toFixed(2))
    }
  }

  return form
}
