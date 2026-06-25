
<template>
  <header>
    <div class="wrap">
      <div class="title">
        <div class="ball">🏐</div>
        <div>
          <h1>Bohemian Fun Cup</h1>
          <div class="sub">Beachvolleyball · Punktewertung pro Spieler</div>
        </div>
        <div class="pill">lokal</div>
      </div>
      <nav>
        <button class="tab" :class="{ active: tab === 'overview' }" @click="tab = 'overview'">Übersicht</button>
        <button class="tab" :class="{ active: tab === 'games' }" @click="tab = 'games'">Spiele</button>
        <button class="tab" :class="{ active: tab === 'ranking' }" @click="tab = 'ranking'">Rangliste</button>
        <button class="tab" :class="{ active: tab === 'admin' }" @click="tab = 'admin'">Admin</button>
      </nav>
    </div>
  </header>

  <main class="wrap">
    <section v-if="tab === 'overview'">
      <div class="card">
        <h2>Top 3</h2>
        <RankingTable :rows="ranking.slice(0, 3)" />
      </div>
      <div class="card">
        <h2>Offene Spiele</h2>
        <p v-if="openMatches.length === 0" class="muted">Aktuell sind keine offenen Spiele vorhanden.</p>
        <MatchCard v-for="m in openMatches" :key="m.id" :match="m" :number="matchNumber(m)" :editable="false" :name-of="nameOf" />
      </div>
      <div class="card">
        <h2>Regeln</h2>
        <p class="rules-text">{{ state.rules }}</p>
      </div>
    </section>

    <section v-if="tab === 'games'">
      <div class="card">
        <h2>Spielplan & Ergebnisse <span class="badge readonly">nur Anzeige</span></h2>
        <p v-if="state.matches.length === 0" class="muted">Noch keine Spiele angelegt.</p>
        <MatchCard v-for="m in state.matches" :key="m.id" :match="m" :number="matchNumber(m)" :editable="false" :name-of="nameOf" />
      </div>
    </section>

    <section v-if="tab === 'ranking'">
      <div class="card">
        <h2>Rangliste</h2>
        <RankingTable :rows="ranking" />
      </div>
    </section>

    <section v-if="tab === 'admin'">
      <div v-if="!adminUnlocked" class="card">
        <h2>Adminbereich</h2>
        <p class="muted">Hier werden Spieler gepflegt, Spiele ausgewürfelt und Ergebnisse eingetragen.</p>
        <button class="btn primary" @click="login">Admin-PIN eingeben</button>
      </div>

      <template v-else>
        <div class="grid">
          <div class="card">
            <h2>Spieler eintragen</h2>
            <div class="row">
              <div class="field">
                <label>Name</label>
                <input v-model="newName" placeholder="z. B. Alex" />
              </div>
              <div class="field">
                <label>Stärke 1-12</label>
                <select v-model.number="newRating">
                  <option v-for="n in 12" :key="n" :value="n">{{ n }}</option>
                </select>
              </div>
            </div>
            <button class="btn primary full" @click="addPlayer">Spieler hinzufügen</button>
          </div>

          <div class="card">
            <h2>Spiele auswürfeln</h2>
            <div class="row">
              <div class="field">
                <label>Modus</label>
                <select v-model="state.settings.mode">
                  <option value="2v2">2 gegen 2</option>
                  <option value="2v3">2 gegen 3</option>
                  <option value="3v3">3 gegen 3</option>
                  <option value="3v4">3 gegen 4</option>
                  <option value="4v4">4 gegen 4</option>
                </select>
              </div>
              <div class="field">
                <label>Anzahl Spiele</label>
                <input type="number" min="1" v-model.number="state.settings.count" />
              </div>
            </div>
            <button class="btn primary full" @click="addMatches">Spiele erstellen</button>
          </div>
        </div>

        <div class="card">
          <h2>Spielerliste</h2>
          <div v-for="p in state.players" :key="p.id" class="player playerrow">
            <div>
              <label>Name</label>
              <input v-model="p.name" />
            </div>
            <div>
              <label>Stärke</label>
              <select v-model.number="p.rating">
                <option v-for="n in 12" :key="n" :value="n">{{ n }}</option>
              </select>
              <div class="muted small">Turnierform intern: {{ Number(p.form || 0).toFixed(2) }}</div>
            </div>
            <button class="btn danger" @click="deletePlayer(p.id)">Löschen</button>
          </div>
        </div>

        <div class="card">
          <h2>Ergebnisse eintragen</h2>
          <p v-if="state.matches.length === 0" class="muted">Noch keine Spiele angelegt.</p>
          <MatchCard
            v-for="m in state.matches"
            :key="m.id"
            :match="m"
            :number="matchNumber(m)"
            :editable="true"
            :name-of="nameOf"
            @delete="deleteMatch(m.id)"
            @score="setScore"
          />
        </div>

        <div class="grid">
          <div class="card">
            <h2>Turnierdaten</h2>
            <div class="actions">
              <button class="btn" @click="exportJson">JSON exportieren</button>
              <label class="btn file-btn">JSON importieren<input type="file" accept="application/json" @change="importJson" /></label>
              <button class="btn danger" @click="clearAll">Alles löschen</button>
            </div>
          </div>
          <div class="card">
            <h2>Regeltext</h2>
            <textarea v-model="state.rules"></textarea>
          </div>
        </div>

        <button class="btn danger lock" @click="logout">Admin sperren</button>
      </template>
    </section>
  </main>
</template>

<script setup>
import { computed, reactive, ref, watch } from 'vue'

const STORE = 'bohemian-fun-cup-v1'
const ADMIN_PIN = '2026'

const tab = ref('overview')
const adminUnlocked = ref(sessionStorage.getItem('bfc-admin') === '1')
const newName = ref('')
const newRating = ref(6)

const uid = () => (crypto.randomUUID ? crypto.randomUUID() : Math.random().toString(36).slice(2))

function initialState() {
  return {
    players: [
      { id: uid(), name: 'Alex', rating: 8, form: 0 },
      { id: uid(), name: 'Max', rating: 7, form: 0 },
      { id: uid(), name: 'Olga', rating: 7, form: 0 },
      { id: uid(), name: 'Antonia', rating: 5, form: 0 },
      { id: uid(), name: 'Ben', rating: 11, form: 0 },
      { id: uid(), name: 'Lisa', rating: 7, form: 0 },
      { id: uid(), name: 'Tom', rating: 5, form: 0 },
      { id: uid(), name: 'Mia', rating: 9, form: 0 },
    ],
    matches: [],
    rules:
      'Gespielt wird bis 21 Punkte. Die erzielten Teampunkte werden jedem Spieler des jeweiligen Teams gutgeschrieben. Beispiel: 21:12 bedeutet 21 Punkte für alle Spieler des einen Teams und 12 Punkte für alle Spieler des anderen Teams.',
    settings: { mode: '4v4', count: 1 },
  }
}

const saved = localStorage.getItem(STORE)
const state = reactive(saved ? JSON.parse(saved) : initialState())

watch(state, save, { deep: true })

const openMatches = computed(() => state.matches.filter((m) => m.scoreA === '' || m.scoreB === '' || m.scoreA == null || m.scoreB == null))

const ranking = computed(() => {
  const map = Object.fromEntries(state.players.map((p) => [p.id, { id: p.id, name: p.name, points: 0, games: 0, wins: 0 }]))
  for (const m of state.matches) {
    if (m.scoreA === '' || m.scoreB === '' || m.scoreA == null || m.scoreB == null) continue
    const a = Number(m.scoreA)
    const b = Number(m.scoreB)
    for (const id of m.teamA) {
      if (!map[id]) continue
      map[id].points += a
      map[id].games++
      if (a > b) map[id].wins++
    }
    for (const id of m.teamB) {
      if (!map[id]) continue
      map[id].points += b
      map[id].games++
      if (b > a) map[id].wins++
    }
  }
  return Object.values(map).sort((a, b) => b.points - a.points || b.wins - a.wins || a.name.localeCompare(b.name))
})

function save() {
  localStorage.setItem(STORE, JSON.stringify(state))
}

function login() {
  if (prompt('Admin-PIN eingeben') === ADMIN_PIN) {
    adminUnlocked.value = true
    sessionStorage.setItem('bfc-admin', '1')
  } else {
    alert('PIN ist falsch.')
  }
}

function logout() {
  adminUnlocked.value = false
  sessionStorage.removeItem('bfc-admin')
  tab.value = 'overview'
}

function nameOf(id) {
  return state.players.find((p) => p.id === id)?.name || '?'
}

function player(id) {
  return state.players.find((p) => p.id === id)
}

function effective(p) {
  return Number(p.rating) + Number(p.form || 0)
}

function addPlayer() {
  const name = newName.value.trim()
  if (!name) return
  state.players.push({ id: uid(), name, rating: Number(newRating.value), form: 0 })
  newName.value = ''
  newRating.value = 6
}

function deletePlayer(id) {
  state.players = state.players.filter((p) => p.id !== id)
  state.matches = state.matches.filter((m) => ![...m.teamA, ...m.teamB].includes(id))
  recalcForm()
}

function deleteMatch(id) {
  state.matches = state.matches.filter((m) => m.id !== id)
  recalcForm()
}

function setScore({ id, side, value }) {
  const m = state.matches.find((x) => x.id === id)
  if (!m) return
  m[side] = value
  recalcForm()
}

function gamesPlayed(id) {
  return ranking.value.find((r) => r.id === id)?.games || 0
}

function shuffle(list) {
  return [...list].sort(() => Math.random() - 0.5)
}

function addMatches() {
  const [aSize, bSize] = state.settings.mode.split('v').map(Number)
  const needed = aSize + bSize
  const count = Number(state.settings.count || 1)

  if (state.players.length < needed) {
    alert('Nicht genug Spieler für diesen Modus.')
    return
  }

  for (let i = 0; i < count; i++) {
    const teams = makeTeams(aSize, bSize)
    state.matches.push({
      id: uid(),
      mode: state.settings.mode,
      teamA: teams.teamA.map((p) => p.id),
      teamB: teams.teamB.map((p) => p.id),
      scoreA: '',
      scoreB: '',
    })
  }
}

function makeTeams(aSize, bSize) {
  const needed = aSize + bSize
  const pool = shuffle(state.players)
    .sort((a, b) => gamesPlayed(a.id) - gamesPlayed(b.id) || effective(b) - effective(a))
    .slice(0, needed)

  let best = null
  for (let i = 0; i < 700; i++) {
    const c = shuffle(pool)
    const teamA = c.slice(0, aSize)
    const teamB = c.slice(aSize)
    const diff = Math.abs(teamA.reduce((s, p) => s + effective(p), 0) - teamB.reduce((s, p) => s + effective(p), 0))
    const repeatPenalty = state.matches.reduce((sum, m) => sum + [...teamA, ...teamB].filter((p) => [...m.teamA, ...m.teamB].includes(p.id)).length, 0)
    const score = diff * 10 + repeatPenalty
    if (!best || score < best.score) best = { teamA, teamB, score }
  }
  return best
}

function recalcForm() {
  state.players.forEach((p) => (p.form = 0))
  for (const m of state.matches) {
    if (m.scoreA === '' || m.scoreB === '' || m.scoreA == null || m.scoreB == null) continue
    const a = Number(m.scoreA)
    const b = Number(m.scoreB)
    if (a === b) continue
    const winners = a > b ? m.teamA : m.teamB
    const losers = a > b ? m.teamB : m.teamA
    winners.forEach((id) => {
      const p = player(id)
      if (p) p.form = Number((Number(p.form || 0) + 0.01).toFixed(2))
    })
    losers.forEach((id) => {
      const p = player(id)
      if (p) p.form = Number((Number(p.form || 0) - 0.01).toFixed(2))
    })
  }
}

function matchNumber(match) {
  return state.matches.findIndex((m) => m.id === match.id) + 1
}

function clearAll() {
  if (!confirm('Wirklich alles löschen?')) return
  localStorage.removeItem(STORE)
  location.reload()
}

function exportJson() {
  const blob = new Blob([JSON.stringify(state, null, 2)], { type: 'application/json' })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = 'bohemian-fun-cup.json'
  a.click()
  URL.revokeObjectURL(a.href)
}

function importJson(event) {
  const file = event.target.files?.[0]
  if (!file) return
  const reader = new FileReader()
  reader.onload = () => {
    try {
      const imported = JSON.parse(reader.result)
      Object.assign(state, imported)
      recalcForm()
    } catch {
      alert('Die JSON-Datei konnte nicht gelesen werden.')
    }
  }
  reader.readAsText(file)
}

const RankingTable = {
  props: ['rows'],
  template: `
    <table>
      <thead><tr><th>Platz</th><th>Spieler</th><th>Punkte</th><th>Spiele</th><th>Siege</th></tr></thead>
      <tbody>
        <tr v-for="(row, index) in rows" :key="row.id">
          <td>{{ index + 1 }}</td>
          <td><b>{{ row.name }}</b></td>
          <td>{{ row.points }}</td>
          <td>{{ row.games }}</td>
          <td>{{ row.wins }}</td>
        </tr>
      </tbody>
    </table>
  `,
}

const MatchCard = {
  props: ['match', 'number', 'editable', 'nameOf'],
  emits: ['delete', 'score'],
  template: `
    <div class="match">
      <div class="match-head">
        <span class="badge">Spiel {{ number }} · {{ match.mode }}</span>
        <button v-if="editable" class="btn danger" @click="$emit('delete')">Löschen</button>
      </div>
      <div class="teams">
        <div class="team"><b>Team A</b><div v-for="id in match.teamA" :key="id">{{ nameOf(id) }}</div></div>
        <div class="team"><b>Team B</b><div v-for="id in match.teamB" :key="id">{{ nameOf(id) }}</div></div>
      </div>
      <div class="score">
        <input v-if="editable" type="number" min="0" max="99" :value="match.scoreA" placeholder="A" @change="$emit('score', { id: match.id, side: 'scoreA', value: $event.target.value })" />
        <div v-else class="scorebox">{{ match.scoreA !== '' ? match.scoreA : '–' }}</div>
        <div class="colon">:</div>
        <input v-if="editable" type="number" min="0" max="99" :value="match.scoreB" placeholder="B" @change="$emit('score', { id: match.id, side: 'scoreB', value: $event.target.value })" />
        <div v-else class="scorebox">{{ match.scoreB !== '' ? match.scoreB : '–' }}</div>
      </div>
    </div>
  `,
}
</script>

<style>
:root { --blue:#2563eb; --bg:#f4f6f8; --card:#fff; --border:#dbe1ea; --muted:#64748b; --text:#0f172a; --red:#fee2e2; --redText:#dc2626; }
*{box-sizing:border-box}
body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;background:var(--bg);color:var(--text)}
header{position:sticky;top:0;z-index:5;background:rgba(244,246,248,.94);backdrop-filter:blur(8px);border-bottom:1px solid var(--border)}
.wrap{max-width:1080px;margin:auto;padding:14px}.title{display:flex;align-items:center;gap:10px}.ball{font-size:28px}
h1{font-size:24px;margin:0}.sub{color:var(--muted);font-size:13px;margin-top:2px}.pill{margin-left:auto;background:#dbeafe;color:#1d4ed8;padding:7px 12px;border-radius:99px;font-weight:800;font-size:12px}
nav{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;margin-top:12px}
button,input,select,textarea{font:inherit}.tab,.btn{border:1px solid var(--border);background:#fff;border-radius:14px;padding:13px 14px;font-weight:800;cursor:pointer}
.tab.active,.btn.primary{background:var(--blue);color:white;border-color:var(--blue)}.btn.danger{background:var(--red);color:var(--redText);border-color:var(--red)}.full{width:100%;margin-top:10px}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}.card{background:var(--card);border-radius:18px;padding:16px;border:1px solid #e5eaf1;box-shadow:0 8px 24px rgba(15,23,42,.05);margin-bottom:14px}
h2{font-size:18px;margin:0 0 14px}.row{display:flex;gap:8px;align-items:end}.field{flex:1}label{display:block;color:var(--muted);font-weight:800;font-size:12px;margin:0 0 6px}
input,select,textarea{width:100%;border:1px solid var(--border);border-radius:13px;padding:12px;background:white}textarea{min-height:120px}
.player,.match{border:1px solid var(--border);border-radius:16px;padding:12px;margin-bottom:10px}.playerrow{display:grid;grid-template-columns:1fr 140px 92px;gap:8px;align-items:end}
.badge{display:inline-block;background:#dbeafe;color:#1d4ed8;padding:7px 10px;border-radius:999px;font-weight:900;font-size:13px;margin-bottom:10px}.readonly{background:#e0f2fe;color:#0369a1}
.teams{display:grid;grid-template-columns:1fr 1fr;gap:12px}.team{background:#f8fafc;border-radius:14px;padding:12px}.team b{display:block;margin-bottom:6px}.muted{color:var(--muted)}.small{font-size:12px;margin-top:5px}
.score{display:grid;grid-template-columns:1fr 24px 1fr;gap:8px;align-items:center;margin-top:12px}.colon{text-align:center;font-weight:900}.scorebox{min-height:48px;border:1px solid var(--border);border-radius:13px;background:#f8fafc;display:flex;align-items:center;justify-content:center;font-weight:900;font-size:18px}
.match-head{display:flex;justify-content:space-between;gap:8px;align-items:start}table{width:100%;border-collapse:collapse}th,td{text-align:left;padding:10px;border-bottom:1px solid #e5eaf1}th{font-size:12px;color:var(--muted)}
.actions{display:flex;flex-wrap:wrap;gap:8px}.file-btn{display:inline-block}.file-btn input{display:none}.lock{position:fixed;right:12px;bottom:12px}.rules-text{white-space:pre-line}
@media(max-width:760px){.grid,.teams{grid-template-columns:1fr}.playerrow{grid-template-columns:1fr}.row{display:block}.row>*{margin-bottom:8px}nav{grid-template-columns:1fr 1fr}.wrap{padding:10px}}
</style>
