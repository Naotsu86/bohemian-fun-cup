<template>
  <div class="card pixel-card menu-window admin-point-grant">
    <h2>🧪 Testpunkte vergeben</h2>

    <div class="menu-body">
      <p class="muted">
        Vergibt ausschließlich frei verteilbare Eigenschaftspunkte.
        Ranglistenpunkte, Siege und Spielergebnisse werden nicht verändert.
      </p>

      <div class="point-grid">
        <div class="field">
          <label>Spieler</label>
          <select v-model="playerId">
            <option value="">Spieler auswählen</option>
            <option
              v-for="player in players"
              :key="player.id"
              :value="player.id"
            >
              {{ player.name }} · frei:
              {{ Number(player.stat_points_available || 0) }}
            </option>
          </select>
        </div>

        <div class="field">
          <label>Punkte hinzufügen</label>
          <input
            v-model.number="points"
            type="number"
            min="1"
            step="1"
            inputmode="numeric"
          >
        </div>
      </div>

      <button
        class="btn primary full"
        :disabled="saving || !playerId || points <= 0"
        @click="save"
      >
        {{ saving ? 'WIRD VERGEBEN...' : 'TESTPUNKTE VERGEBEN' }}
      </button>

      <p v-if="message" class="success-small">{{ message }}</p>
      <p v-if="error" class="error-small">{{ error }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { grantAdminStatPoints } from '../../services/adminStatPointService'

defineProps({
  players: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits(['updated'])

const playerId = ref('')
const points = ref(100)
const saving = ref(false)
const message = ref('')
const error = ref('')

async function save() {
  saving.value = true
  message.value = ''
  error.value = ''

  try {
    await grantAdminStatPoints(playerId.value, points.value)
    message.value = `${Number(points.value)} Testpunkte wurden vergeben.`
    emit('updated')
  } catch (e) {
    error.value = e.message || 'Testpunkte konnten nicht vergeben werden.'
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.point-grid{
  display:grid;
  grid-template-columns:2fr 1fr;
  gap:10px;
  margin-bottom:10px;
}

.success-small{
  margin-top:10px;
  color:#237a2c;
  font-weight:900;
}

@media(max-width:700px){
  .point-grid{
    grid-template-columns:1fr;
  }
}
</style>
