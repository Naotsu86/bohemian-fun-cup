import { gamesPlayed } from './ranking'
const shuffle = (list) => [...list].sort(() => Math.random() - 0.5)
const pairKey = (a,b) => [a,b].sort().join('|')
const effective = (p) => Number(p.strength || 1) + Number(p.form || 0)
function history(matches){
  const together = new Map(), against = new Map()
  for (const m of matches) {
    for (const team of [m.team_a || [], m.team_b || []]) for (let i=0;i<team.length;i++) for (let j=i+1;j<team.length;j++) together.set(pairKey(team[i],team[j]), (together.get(pairKey(team[i],team[j]))||0)+1)
    for (const a of m.team_a || []) for (const b of m.team_b || []) against.set(pairKey(a,b), (against.get(pairKey(a,b))||0)+1)
  }
  return { together, against }
}
function pairPenalty(team, together){ let p=0; for(let i=0;i<team.length;i++) for(let j=i+1;j<team.length;j++) p += together.get(pairKey(team[i].id, team[j].id)) || 0; return p }
function opponentPenalty(a,b,against){ let p=0; for(const x of a) for(const y of b) p += against.get(pairKey(x.id,y.id)) || 0; return p }
export function createNextMatch({ players, matches, mode }) {
  const active = players.filter(p => p.active !== false)
  const [sizeA, sizeB] = String(mode).split('v').map(Number)
  const needed = sizeA + sizeB
  if (!sizeA || !sizeB) throw new Error('Der Spielmodus ist ungültig.')
  if (active.length < needed) throw new Error(`Für ${mode} brauchst du mindestens ${needed} aktive Spieler. Aktuell sind es ${active.length}.`)
  const pool = shuffle(active).sort((a,b) => gamesPlayed(a.id,matches)-gamesPlayed(b.id,matches) || effective(b)-effective(a)).slice(0, needed)
  const h = history(matches)
  let best = null
  for (let i=0;i<2500;i++) {
    const c = shuffle(pool), teamA = c.slice(0,sizeA), teamB = c.slice(sizeA,needed)
    const strengthDiff = Math.abs(teamA.reduce((s,p)=>s+effective(p),0) - teamB.reduce((s,p)=>s+effective(p),0))
    const played = [...teamA,...teamB].map(p => gamesPlayed(p.id,matches))
    const gameSpread = Math.max(...played) - Math.min(...played)
    const score = strengthDiff*100 + gameSpread*75 + (pairPenalty(teamA,h.together)+pairPenalty(teamB,h.together))*25 + opponentPenalty(teamA,teamB,h.against)*8 + Math.random()
    if (!best || score < best.score) best = {teamA, teamB, score}
  }
  return { mode, team_a: best.teamA.map(p=>p.id), team_b: best.teamB.map(p=>p.id), score_a:null, score_b:null }
}
export function recalcForm(players, matches) {
  const form = Object.fromEntries(players.map(p => [p.id, 0]))
  for (const m of matches) {
    if (m.score_a === null || m.score_b === null || m.score_a === '' || m.score_b === '') continue
    const a = Number(m.score_a), b = Number(m.score_b); if (a === b) continue
    const winners = a > b ? m.team_a : m.team_b, losers = a > b ? m.team_b : m.team_a
    for (const id of winners || []) form[id] = Number(((form[id] || 0) + 0.01).toFixed(2))
    for (const id of losers || []) form[id] = Number(((form[id] || 0) - 0.01).toFixed(2))
  }
  return form
}
