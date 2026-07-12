<template>
  <AppHeader
    v-model="tab"
    :status-text="statusText"
    :is-admin="isAdmin"
    @refresh="loadData"
  />

  <main class="wrap main-content">
    <p v-if="error" class="error-box">{{ error }}</p>

    <Overview
      v-if="tab === 'overview'"
      :ranking="ranking"
      :open-matches="openMatches"
      :rules="rules"
      :match-number="matchNumber"
      :name-of="nameOf"
    />

    <Games
      v-if="tab === 'games'"
      :matches="matches"
      :match-number="matchNumber"
      :name-of="nameOf"
    />

    <Ranking
      v-if="tab === 'ranking'"
      :ranking="ranking"
    />

    <Profile
      v-if="tab === 'account' && !isAdmin"
      @auth-changed="handleAuthChanged"
    />

    <Admin
      v-if="tab === 'account' && isAdmin"
      :admin-unlocked="isAdmin"
      :user-email="userEmail"
      :players="players"
      :matches="matches"
      :rules="rules"
      :message="message"
      :match-number="matchNumber"
      :name-of="nameOf"
      @login="handleLogin"
      @logout="handleLogout"
      @refresh="loadData"
      @approve-player="handleApprovePlayer"
      @add-player="handleAddPlayer"
      @update-player="handleUpdatePlayer"
      @delete-player="handleDeletePlayer"
      @create-match="handleCreateMatch"
      @delete-match="handleDeleteMatch"
      @score="handleScore"
      @update-rules="handleRules"
    />
  </main>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { supabase } from './api/supabase'

import AppHeader from './components/AppHeader.vue'
import Overview from './views/Overview.vue'
import Games from './views/Games.vue'
import Ranking from './views/Ranking.vue'
import Admin from './views/Admin.vue'
import Profile from './views/Profile.vue'

import { getSession, loginWithPassword, logout } from './services/auth'
import { approvePlayer } from './services/adminApprovalService'
import { buildRanking, getOpenMatches } from './services/ranking'
import { createNextMatch } from './services/generator'
import {
  addPlayer,
  deleteMatch,
  deletePlayer,
  insertMatch,
  loadAll,
  updateForms,
  updateMatch,
  updatePlayer,
  updateSettings
} from './services/data'

const tab = ref('overview')
const session = ref(null)
const isAdmin = ref(false)
const players = ref([])
const matches = ref([])
const settings = ref({})
const loading = ref(false)
const error = ref('')
const message = ref('')

let channel = null
let timer = null

const userEmail = computed(() => session.value?.user?.email || '')
const ranking = computed(() => buildRanking(players.value, matches.value))
const openMatches = computed(() => getOpenMatches(matches.value))
const rules = computed(() => settings.value.rules || 'Noch keine Regeln eingetragen.')
const statusText = computed(() => loading.value ? 'lädt...' : 'live')

onMounted(async () => {
  await loadSession()
  await checkAdmin()
  await loadData()
  subscribe()

  timer = setInterval(loadData, 5000)

  supabase.auth.onAuthStateChange(async (_event, newSession) => {
    session.value = newSession
    await checkAdmin()
  })
})

onUnmounted(() => {
  if (channel) supabase.removeChannel(channel)
  if (timer) clearInterval(timer)
})

async function run(fn) {
  error.value = ''
  try {
    await fn()
  } catch (e) {
    error.value = e.message || 'Fehler'
  }
}

async function loadSession() {
  await run(async () => {
    session.value = await getSession()
  })
}

async function checkAdmin() {
  if (!session.value?.user) {
    isAdmin.value = false
    return
  }

  try {
    const { data, error: adminError } = await supabase.rpc('is_admin')

    if (adminError) {
      isAdmin.value = false
      return
    }

    isAdmin.value = !!data
  } catch {
    isAdmin.value = false
  }
}

async function handleAuthChanged() {
  await loadSession()
  await checkAdmin()
  await loadData()
}

async function loadData() {
  loading.value = true

  try {
    const d = await loadAll()
    players.value = d.players
    matches.value = d.matches
    settings.value = d.settings
  } catch (e) {
    error.value = e.message || 'Daten konnten nicht geladen werden.'
  } finally {
    loading.value = false
  }
}

function subscribe() {
  channel = supabase
    .channel('bfc-live')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'players' }, loadData)
    .on('postgres_changes', { event: '*', schema: 'public', table: 'matches' }, loadData)
    .on('postgres_changes', { event: '*', schema: 'public', table: 'settings' }, loadData)
    .subscribe()
}

async function handleLogin({ email, password }) {
  await run(async () => {
    session.value = await loginWithPassword(email, password)
    await checkAdmin()
    await loadData()
  })
}

async function handleLogout() {
  await run(async () => {
    await logout()
    session.value = null
    isAdmin.value = false
    tab.value = 'overview'
  })
}

function nameOf(id) {
  return players.value.find(p => p.id === id)?.name || '?'
}

function matchNumber(m) {
  return matches.value.findIndex(x => x.id === m.id) + 1
}

async function handleApprovePlayer(playerId) {
  await run(async () => {
    await approvePlayer(playerId)
    message.value = 'Spieler wurde erfolgreich freigegeben.'
    await loadData()
  })
}

async function handleAddPlayer(p) {
  await run(async () => {
    await addPlayer(p)
    await loadData()
  })
}

async function handleUpdatePlayer(id, patch) {
  await run(async () => {
    await updatePlayer(id, patch)
    await loadData()
  })
}

async function handleDeletePlayer(id) {
  if (!confirm('Besser ist meistens: Spieler auf inaktiv setzen. Trotzdem löschen?')) return

  await run(async () => {
    await deletePlayer(id)
    await loadData()
  })
}

async function handleCreateMatch(mode) {
  await run(async () => {
    const m = createNextMatch(players.value, matches.value, mode)
    await insertMatch(m)
    message.value = 'Nächstes Spiel wurde erzeugt.'
    await loadData()
  })
}

async function handleDeleteMatch(id) {
  await run(async () => {
    await deleteMatch(id)
    await loadData()
    await updateForms(players.value, matches.value)
    await loadData()
  })
}

async function handleScore(payload) {
  await run(async () => {
    if ('score_a' in payload || 'score_b' in payload) {
      await updateMatch(payload.id, {
        score_a: payload.score_a,
        score_b: payload.score_b
      })
    } else {
      await updateMatch(payload.id, { [payload.side]: payload.value })
    }

    await loadData()
    await updateForms(players.value, matches.value)
    await loadData()
  })
}

async function handleRules(rules) {
  await run(async () => {
    await updateSettings({ ...settings.value, rules })
    await loadData()
  })
}
</script>
