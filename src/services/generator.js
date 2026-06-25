import { uuid } from './storage'

function shuffle(list) {
  return [...list].sort(() => Math.random() - 0.5)
}

function effectiveRating(player) {
  return Number(player.rating || 1) + Number(player.form || 0)
}

function getPlayerGames(playerId, matches) {
  return matches.filter((m) => m.teamA.includes(playerId) || m.teamB.includes(playerId)).length
}

function pairKey(a, b) {
  return [a, b].sort().join('|')
}

function buildHistory(matches) {
  const together = new Map()
  const against = new Map()

  for (const match of matches) {
    const teams = [match.teamA, match.teamB]

    for (const team of teams) {
      for (let i = 0; i < team.length; i++) {
        for (let j = i + 1; j < team.length; j++) {
          const key = pairKey(team[i], team[j])
          together.set(key, (together.get(key) || 0) + 1)
        }
      }
    }

    for (const a of match.teamA) {
      for (const b of match.teamB) {
        const key = pairKey(a, b)
        against.set(key, (against.get(key) || 0) + 1)
      }
    }
  }

  return { together, against }
}

function teamStrength(team) {
  return team.reduce((sum, p) => sum + effectiveRating(p), 0)
}

function teamPairPenalty(team, together) {
  let penalty = 0

  for (let i = 0; i < team.length; i++) {
    for (let j = i + 1; j < team.length; j++) {
      penalty += together.get(pairKey(team[i].id, team[j].id)) || 0
    }
  }

  return penalty
}

function opponentPenalty(teamA, teamB, against) {
  let penalty = 0

  for (const a of teamA) {
    for (const b of teamB) {
      penalty += against.get(pairKey(a.id, b.id)) || 0
    }
  }

  return penalty
}

function selectPool(players, matches, needed) {
  return shuffle(players)
    .sort((a, b) => getPlayerGames(a.id, matches) - getPlayerGames(b.id, matches) || effectiveRating(b) - effectiveRating(a))
    .slice(0, needed)
}

export function createMatches({ players, matches, mode, count }) {
  const [aSize, bSize] = mode.split('v').map(Number)
  const needed = aSize + bSize
  const amount = Math.max(1, Number(count || 1))

  if (!aSize || !bSize) {
    throw new Error('Der Spielmodus ist ungültig.')
  }

  if (players.length < needed) {
    throw new Error(`Für ${mode} brauchst du mindestens ${needed} Spieler. Aktuell sind es ${players.length}.`)
  }

  const created = []
  const workingMatches = [...matches]
  const history = buildHistory(workingMatches)

  for (let round = 0; round < amount; round++) {
    const pool = selectPool(players, workingMatches, needed)

    let best = null

    for (let i = 0; i < 1500; i++) {
      const candidate = shuffle(pool)
      const teamA = candidate.slice(0, aSize)
      const teamB = candidate.slice(aSize, needed)

      const strengthDiff = Math.abs(teamStrength(teamA) - teamStrength(teamB))
      const games = [...teamA, ...teamB].map((p) => getPlayerGames(p.id, workingMatches))
      const gameSpread = Math.max(...games) - Math.min(...games)
      const togetherPenalty = teamPairPenalty(teamA, history.together) + teamPairPenalty(teamB, history.together)
      const againstPenalty = opponentPenalty(teamA, teamB, history.against)

      const score = strengthDiff * 100 + gameSpread * 60 + togetherPenalty * 18 + againstPenalty * 6 + Math.random()

      if (!best || score < best.score) {
        best = { teamA, teamB, score }
      }
    }

    const match = {
      id: uuid(),
      mode,
      teamA: best.teamA.map((p) => p.id),
      teamB: best.teamB.map((p) => p.id),
      scoreA: '',
      scoreB: '',
      createdAt: new Date().toISOString(),
    }

    created.push(match)
    workingMatches.push(match)

    for (let i = 0; i < match.teamA.length; i++) {
      for (let j = i + 1; j < match.teamA.length; j++) {
        const key = pairKey(match.teamA[i], match.teamA[j])
        history.together.set(key, (history.together.get(key) || 0) + 1)
      }
    }

    for (let i = 0; i < match.teamB.length; i++) {
      for (let j = i + 1; j < match.teamB.length; j++) {
        const key = pairKey(match.teamB[i], match.teamB[j])
        history.together.set(key, (history.together.get(key) || 0) + 1)
      }
    }

    for (const a of match.teamA) {
      for (const b of match.teamB) {
        const key = pairKey(a, b)
        history.against.set(key, (history.against.get(key) || 0) + 1)
      }
    }
  }

  return created
}

export function recalcForm(players, matches, settings) {
  for (const player of players) player.form = 0

  for (const match of matches) {
    if (match.scoreA === '' || match.scoreB === '' || match.scoreA == null || match.scoreB == null) continue

    const a = Number(match.scoreA)
    const b = Number(match.scoreB)
    if (a === b) continue

    const winners = a > b ? match.teamA : match.teamB
    const losers = a > b ? match.teamB : match.teamA

    for (const id of winners) {
      const player = players.find((p) => p.id === id)
      if (player) player.form = Number((Number(player.form || 0) + Number(settings.winForm || 0.01)).toFixed(2))
    }

    for (const id of losers) {
      const player = players.find((p) => p.id === id)
      if (player) player.form = Number((Number(player.form || 0) + Number(settings.lossForm || -0.01)).toFixed(2))
    }
  }
}
