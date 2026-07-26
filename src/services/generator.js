import { gamesPlayed } from './ranking'
import { calculatePlayerEffects } from '../utils/playerEffectEngine'

function shuffle(list) {
  return [...list].sort(() => Math.random() - 0.5)
}

function pairKey(a, b) {
  return [a, b].sort().join('|')
}

function strength(player) {
  return calculatePlayerEffects(player).effectiveStrength
}

function teamBChance(player) {
  const chance = Number(
    calculatePlayerEffects(player).rules.teamBChance
  )

  if (!Number.isFinite(chance)) return 0.5

  return Math.min(1, Math.max(0, chance))
}

function hasPlayed(match, playerId) {
  return (
    (match.team_a || []).includes(playerId) ||
    (match.team_b || []).includes(playerId)
  )
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
  return matches.filter(match =>
    wasBenched(match, playerId)
  ).length
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

          together.set(
            key,
            (together.get(key) || 0) + 1
          )
        }
      }
    }

    for (const playerA of teamA) {
      for (const playerB of teamB) {
        const key = pairKey(playerA, playerB)

        against.set(
          key,
          (against.get(key) || 0) + 1
        )
      }
    }
  }

  return { together, against }
}

function teamSum(team) {
  return team.reduce(
    (sum, player) => sum + strength(player),
    0
  )
}

function teamPenalty(team, matchHistory) {
  let penalty = 0

  for (let i = 0; i < team.length; i += 1) {
    for (let j = i + 1; j < team.length; j += 1) {
      penalty +=
        matchHistory.together.get(
          pairKey(team[i].id, team[j].id)
        ) || 0
    }
  }

  return penalty
}

function opponentPenalty(teamA, teamB, matchHistory) {
  let penalty = 0

  for (const playerA of teamA) {
    for (const playerB of teamB) {
      penalty +=
        matchHistory.against.get(
          pairKey(playerA.id, playerB.id)
        ) || 0
    }
  }

  return penalty
}

/**
 * Für jeden ausgewählten Spieler wird einmal pro neuem Spiel
 * ausgelost, ob er nach seiner persönlichen Wahrscheinlichkeit
 * eher Team B zugeordnet werden soll.
 *
 * Beispiele:
 * - normaler Spieler: 50 %
 * - Sonnenanbeter: 25 %
 * - Sonnenchampion: 10 %
 */
function createSidePreferences(players) {
  return new Map(
    players.map(player => [
      player.id,
      Math.random() < teamBChance(player)
    ])
  )
}

/**
 * Bestraft eine Teamaufteilung, wenn sie nicht zu den zuvor
 * ausgelosten Seitenwünschen passt.
 *
 * Die Teamstärke bleibt trotzdem wichtiger als diese Präferenz.
 */
function sidePreferencePenalty(
  teamA,
  teamB,
  sidePreferences
) {
  let penalty = 0

  for (const player of teamA) {
    const prefersTeamB =
      sidePreferences.get(player.id) === true

    if (prefersTeamB) {
      penalty += 1
    }
  }

  for (const player of teamB) {
    const prefersTeamB =
      sidePreferences.get(player.id) === true

    if (!prefersTeamB) {
      penalty += 1
    }
  }

  return penalty
}

/**
 * Wählt die Spieler fair aus:
 *
 * 1. Wer im vorherigen Match pausierte, wird stark bevorzugt.
 * 2. Wer bisher weniger echte Spiele hat, wird bevorzugt.
 * 3. Bei Gleichstand pausiert, wer bisher seltener pausierte.
 */
function selectPlayers(activePlayers, matches, needed) {
  const sorted = shuffle(activePlayers).sort((a, b) => {
    const lastA = lastMatchParticipation(a.id, matches)
    const lastB = lastMatchParticipation(b.id, matches)

    const lastBenchPriorityA =
      lastA === 'bench' ? 0 : 1

    const lastBenchPriorityB =
      lastB === 'bench' ? 0 : 1

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
  const [sizeA, sizeB] = String(mode)
    .split('v')
    .map(Number)

  const needed = sizeA + sizeB

  if (!sizeA || !sizeB) {
    throw new Error('Ungültiger Spielmodus.')
  }

  if (sizeA > 4 || sizeB > 4) {
    throw new Error(
      'Es wird maximal 4 gegen 4 gespielt.'
    )
  }

  const eligiblePlayers = players.filter(
    player => player.approved !== false
  )

  const activePlayers = eligiblePlayers.filter(
    player => player.active !== false
  )

  // Snapshot der aktuell abwesenden/inaktiven Spieler.
  // Nur diese erhalten für dieses neu erzeugte Spiel später
  // die Punktzahl des Verliererteams.
  const absentPlayers = eligiblePlayers.filter(
    player => player.active === false
  )

  if (activePlayers.length < needed) {
    throw new Error(
      `Für ${mode} brauchst du ${needed} aktive Spieler. ` +
      `Aktuell: ${activePlayers.length}.`
    )
  }

  const { selected, benched } = selectPlayers(
    activePlayers,
    matches,
    needed
  )

  const matchHistory = history(matches)

  /*
   * Diese Auslosung erfolgt nur einmal pro Spielgenerierung.
   * Dadurch können die 3000 Versuche die Präferenzen
   * berücksichtigen, ohne bei jedem Versuch neu zu würfeln.
   */
  const sidePreferences =
    createSidePreferences(selected)

  let best = null

  for (let attempt = 0; attempt < 3000; attempt += 1) {
    const candidates = shuffle(selected)

    const teamA = candidates.slice(0, sizeA)
    const teamB = candidates.slice(sizeA, needed)

    const gameCounts = [...teamA, ...teamB].map(
      player => gamesPlayed(player.id, matches)
    )

    const strengthDifference =
      Math.abs(
        teamSum(teamA) - teamSum(teamB)
      ) * 100

    const gameCountDifference =
      (
        Math.max(...gameCounts) -
        Math.min(...gameCounts)
      ) * 80

    const sameTeamPenalty =
      (
        teamPenalty(teamA, matchHistory) +
        teamPenalty(teamB, matchHistory)
      ) * 30

    const repeatedOpponentPenalty =
      opponentPenalty(
        teamA,
        teamB,
        matchHistory
      ) * 8

    /*
     * 12 Punkte pro nicht erfüllter Seitenpräferenz.
     *
     * Dadurch wird die Wahrscheinlichkeit berücksichtigt,
     * ohne den Ausgleich der Teamstärken zu überstimmen.
     */
    const rpgSidePenalty =
      sidePreferencePenalty(
        teamA,
        teamB,
        sidePreferences
      ) * 12

    const score =
      strengthDifference +
      gameCountDifference +
      sameTeamPenalty +
      repeatedOpponentPenalty +
      rpgSidePenalty +
      Math.random()

    if (!best || score < best.score) {
      best = {
        teamA,
        teamB,
        score
      }
    }
  }

  if (!best) {
    throw new Error(
      'Mit den aktuellen Regeln konnten keine gültigen Teams gebildet werden.'
    )
  }

  return {
    mode,
    team_a: best.teamA.map(player => player.id),
    team_b: best.teamB.map(player => player.id),
    bench_players: benched.map(player => player.id),
    absent_players: absentPlayers.map(
      player => player.id
    ),
    score_a: null,
    score_b: null
  }
}
export function createTiebreakMatch(
  players,
  matches,
  playerAId,
  playerBId
) {
  if (!playerAId || !playerBId) {
    throw new Error(
      'Für das Entscheidungsspiel müssen zwei Spieler ausgewählt werden.'
    )
  }

  if (playerAId === playerBId) {
    throw new Error(
      'Ein Spieler kann nicht gegen sich selbst antreten.'
    )
  }

  const eligiblePlayers = players.filter(
    player =>
      player.approved !== false &&
      player.active !== false
  )

  const playerA = eligiblePlayers.find(
    player => player.id === playerAId
  )

  const playerB = eligiblePlayers.find(
    player => player.id === playerBId
  )

  if (!playerA || !playerB) {
    throw new Error(
      'Mindestens einer der ausgewählten Spieler ist nicht aktiv oder nicht freigegeben.'
    )
  }

  const possibleTeammates = eligiblePlayers.filter(
    player =>
      player.id !== playerAId &&
      player.id !== playerBId
  )

  if (possibleTeammates.length < 2) {
    throw new Error(
      'Für ein Entscheidungsspiel werden mindestens vier aktive Spieler benötigt.'
    )
  }

  const {
  selected: selectedTeammates
} = selectPlayers(
  possibleTeammates,
  matches,
  2
)

  const matchHistory = history(matches)

  const teammateOne = selectedTeammates[0]
  const teammateTwo = selectedTeammates[1]

  const variants = [
    {
      teamA: [playerA, teammateOne],
      teamB: [playerB, teammateTwo]
    },
    {
      teamA: [playerA, teammateTwo],
      teamB: [playerB, teammateOne]
    }
  ]

  let best = null

  for (const variant of variants) {
    const score =
      Math.abs(
        teamSum(variant.teamA) -
        teamSum(variant.teamB)
      ) * 100 +
      (
        teamPenalty(
          variant.teamA,
          matchHistory
        ) +
        teamPenalty(
          variant.teamB,
          matchHistory
        )
      ) * 30 +
      opponentPenalty(
        variant.teamA,
        variant.teamB,
        matchHistory
      ) * 8

    if (!best || score < best.score) {
      best = {
        ...variant,
        score
      }
    }
  }

  return {
    /*
     * Vorläufig besondere Modusbezeichnung.
     * Damit können wir das Spiel später von normalen
     * 2-gegen-2-Spielen unterscheiden.
     */
    mode: 'tiebreak-2v2',

    team_a: best.teamA.map(
      player => player.id
    ),

    team_b: best.teamB.map(
      player => player.id
    ),

    bench_players: [],

    absent_players: [],

    score_a: null,
    score_b: null
  }
}

export function createRoundRobinTiebreakMatches(
  players,
  matches,
  playerIds
) {
  const uniquePlayerIds = [
    ...new Set((playerIds || []).filter(Boolean))
  ]

  if (uniquePlayerIds.length < 3) {
    throw new Error(
      'Für eine Entscheidungsrunde werden mindestens drei Spieler benötigt.'
    )
  }

  const roundMatches = []
  const generatedMatches = [...matches]

  for (let i = 0; i < uniquePlayerIds.length; i += 1) {
    for (let j = i + 1; j < uniquePlayerIds.length; j += 1) {
      const match = createTiebreakMatch(
        players,
        generatedMatches,
        uniquePlayerIds[i],
        uniquePlayerIds[j]
      )

      roundMatches.push(match)
      generatedMatches.push(match)
    }
  }

  return roundMatches
}

export function calculateForm(players, matches) {
  const form = Object.fromEntries(
    players.map(player => [player.id, 0])
  )

  for (const match of matches) {
    if (match.mode === 'tiebreak-2v2') {
      continue
    }

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

    const winners =
      scoreA > scoreB
        ? match.team_a
        : match.team_b

    const losers =
      scoreA > scoreB
        ? match.team_b
        : match.team_a

    for (const id of winners || []) {
      form[id] = Number(
        ((form[id] || 0) + 0.01).toFixed(2)
      )
    }

    for (const id of losers || []) {
      form[id] = Number(
        ((form[id] || 0) - 0.01).toFixed(2)
      )
    }
  }

  return form
}