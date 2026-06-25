<template>
  <AppHeader v-model="tab" />

  <main class="wrap">
    <Overview
      v-if="tab === 'overview'"
      :ranking="ranking"
      :open-matches="openMatches"
      :rules="state.rules"
      :match-number="matchNumber"
      :name-of="nameOf"
    />

    <Games
      v-if="tab === 'games'"
      :matches="state.matches"
      :match-number="matchNumber"
      :name-of="nameOf"
    />

    <Ranking v-if="tab === 'ranking'" :ranking="ranking" />

    <Admin
      v-if="tab === 'admin'"
      :state="state"
      :admin-unlocked="adminUnlocked"
      :message="adminMessage"
      :match-number="matchNumber"
      :name-of="nameOf"
      @login="login"
      @logout="logout"
      @create-matches="handleCreateMatches"
      @delete-player="deletePlayer"
      @delete-match="deleteMatch"
      @score="setScore"
      @export-json="exportJson"
      @import-json="importJson"
      @clear-all="clearAll"
    />
  </main>
</template>

<script setup>
import { computed, reactive, ref, watch } from 'vue'
import AppHeader from './components/AppHeader.vue'
import Overview from './views/Overview.vue'
import Games from './views/Games.vue'
import Ranking from './views/Ranking.vue'
import Admin from './views/Admin.vue'
import { ADMIN_SESSION_KEY, STORAGE_KEY, loadState, saveState } from './services/storage'
import { buildRanking, getOpenMatches } from './services/ranking'
import { createMatches, recalcForm } from './services/generator'

const tab = ref('overview')
const adminUnlocked = ref(sessionStorage.getItem(ADMIN_SESSION_KEY) === '1')
const adminMessage = ref('')

const state = reactive(loadState())

watch(
  state,
  () => {
    saveState(state)
  },
  { deep: true },
)

const ranking = computed(() => buildRanking(state.players, state.matches))
const openMatches = computed(() => getOpenMatches(state.matches))

function login() {
  const pin = prompt('Admin-PIN eingeben')
  if (pin === String(state.settings.adminPin || '2026')) {
    adminUnlocked.value = true
    sessionStorage.setItem(ADMIN_SESSION_KEY, '1')
  } else {
    alert('PIN ist falsch.')
  }
}

function logout() {
  adminUnlocked.value = false
  sessionStorage.removeItem(ADMIN_SESSION_KEY)
  tab.value = 'overview'
}

function nameOf(id) {
  return state.players.find((p) => p.id === id)?.name || '?'
}

function matchNumber(match) {
  return state.matches.findIndex((m) => m.id === match.id) + 1
}

function handleCreateMatches() {
  adminMessage.value = ''

  try {
    const created = createMatches({
      players: state.players,
      matches: state.matches,
      mode: state.settings.mode,
      count: state.settings.count,
    })

    state.matches.push(...created)
    adminMessage.value = `${created.length} Spiel${created.length === 1 ? '' : 'e'} erstellt.`
  } catch (error) {
    adminMessage.value = error.message || 'Die Spiele konnten nicht erstellt werden.'
  }
}

function deletePlayer(id) {
  state.players = state.players.filter((p) => p.id !== id)
  state.matches = state.matches.filter((m) => ![...m.teamA, ...m.teamB].includes(id))
  recalcForm(state.players, state.matches, state.settings)
}

function deleteMatch(id) {
  state.matches = state.matches.filter((m) => m.id !== id)
  recalcForm(state.players, state.matches, state.settings)
}

function setScore({ id, side, value }) {
  const match = state.matches.find((m) => m.id === id)
  if (!match) return

  match[side] = value
  recalcForm(state.players, state.matches, state.settings)
}

function exportJson() {
  const blob = new Blob([JSON.stringify(state, null, 2)], { type: 'application/json' })
  const link = document.createElement('a')
  link.href = URL.createObjectURL(blob)
  link.download = 'bohemian-fun-cup.json'
  link.click()
  URL.revokeObjectURL(link.href)
}

function importJson(event) {
  const file = event.target.files?.[0]
  if (!file) return

  const reader = new FileReader()
  reader.onload = () => {
    try {
      const imported = JSON.parse(reader.result)
      Object.assign(state, imported)
      recalcForm(state.players, state.matches, state.settings)
      adminMessage.value = 'JSON wurde importiert.'
    } catch {
      alert('Die JSON-Datei konnte nicht gelesen werden.')
    }
  }

  reader.readAsText(file)
}

function clearAll() {
  if (!confirm('Wirklich alles löschen?')) return
  localStorage.removeItem(STORAGE_KEY)
  location.reload()
}
</script>
