<template>
  <div class="card pixel-card menu-window">
    <h2>🕐 Wartende Spieler</h2>

    <div class="menu-body">
      <button class="btn full" @click="load" :disabled="loading">
        {{ loading ? 'Lade...' : 'Aktualisieren' }}
      </button>

      <p v-if="players.length === 0" class="muted">
        Aktuell wartet kein Spieler auf Freigabe.
      </p>

      <article v-for="player in players" :key="player.id" class="pending-player-row">
        <div>
          <strong>{{ player.name }}</strong>
          <p class="muted">
            AKA: {{ player.aka_name || '-' }}<br>
            {{ player.email || '-' }}
          </p>
        </div>

        <button class="btn primary" @click="approve(player.id)">
          Freigeben
        </button>
      </article>

      <p v-if="message" class="muted">{{ message }}</p>
      <p v-if="error" class="error-small">{{ error }}</p>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { approvePlayer, loadPendingPlayers } from '../../services/adminApprovalService'

const players = ref([])
const loading = ref(false)
const message = ref('')
const error = ref('')

onMounted(load)

async function load() {
  loading.value = true
  error.value = ''
  message.value = ''

  try {
    players.value = await loadPendingPlayers()
  } catch (e) {
    error.value = e.message || 'Wartende Spieler konnten nicht geladen werden.'
  } finally {
    loading.value = false
  }
}

async function approve(playerId) {
  error.value = ''
  message.value = ''

  try {
    await approvePlayer(playerId)
    message.value = 'Spieler wurde freigegeben.'
    await load()
  } catch (e) {
    error.value = e.message || 'Freigabe fehlgeschlagen.'
  }
}
</script>
