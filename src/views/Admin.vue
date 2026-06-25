<template>
  <section>
    <div v-if="!adminUnlocked" class="card">
      <h2>Adminbereich</h2>
      <p class="muted">Hier werden Spieler gepflegt, Spiele ausgewürfelt und Ergebnisse eingetragen.</p>
      <button class="btn primary" @click="$emit('login')">Admin-PIN eingeben</button>
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
              <input v-model.number="state.settings.count" type="number" min="1" max="99" />
            </div>
          </div>
          <button class="btn primary full" @click="$emit('create-matches')">Spiele erstellen</button>
          <p v-if="message" class="hint">{{ message }}</p>
        </div>
      </div>

      <div class="card">
        <h2>Spielerliste</h2>
        <p v-if="state.players.length === 0" class="muted">Noch keine Spieler angelegt.</p>
        <div v-for="player in state.players" :key="player.id" class="player playerrow">
          <div>
            <label>Name</label>
            <input v-model="player.name" />
          </div>
          <div>
            <label>Stärke</label>
            <select v-model.number="player.rating">
              <option v-for="n in 12" :key="n" :value="n">{{ n }}</option>
            </select>
            <div class="muted small">Turnierform intern: {{ Number(player.form || 0).toFixed(2) }}</div>
          </div>
          <button class="btn danger" @click="$emit('delete-player', player.id)">Löschen</button>
        </div>
      </div>

      <div class="card">
        <h2>Ergebnisse eintragen</h2>
        <p v-if="state.matches.length === 0" class="muted">Noch keine Spiele angelegt.</p>
        <MatchCard
          v-for="match in state.matches"
          :key="match.id"
          :match="match"
          :number="matchNumber(match)"
          :editable="true"
          :name-of="nameOf"
          @delete="$emit('delete-match', match.id)"
          @score="$emit('score', $event)"
        />
      </div>

      <div class="grid">
        <div class="card">
          <h2>Turnierdaten</h2>
          <div class="actions">
            <button class="btn" @click="$emit('export-json')">JSON exportieren</button>
            <label class="btn file-btn">
              JSON importieren
              <input type="file" accept="application/json" @change="$emit('import-json', $event)" />
            </label>
            <button class="btn danger" @click="$emit('clear-all')">Alles löschen</button>
          </div>
        </div>

        <div class="card">
          <h2>Regeltext</h2>
          <textarea v-model="state.rules"></textarea>
        </div>
      </div>

      <button class="btn danger lock" @click="$emit('logout')">Admin sperren</button>
    </template>
  </section>
</template>

<script setup>
import { ref } from 'vue'
import MatchCard from '../components/MatchCard.vue'
import { uuid } from '../services/storage'

const props = defineProps({
  state: Object,
  adminUnlocked: Boolean,
  message: String,
  matchNumber: Function,
  nameOf: Function,
})

const emit = defineEmits([
  'login',
  'logout',
  'create-matches',
  'delete-player',
  'delete-match',
  'score',
  'export-json',
  'import-json',
  'clear-all',
])

const newName = ref('')
const newRating = ref(6)

function addPlayer() {
  const name = newName.value.trim()
  if (!name) return

  props.state.players.push({
    id: uuid(),
    name,
    rating: Number(newRating.value),
    form: 0,
  })

  newName.value = ''
  newRating.value = 6
}
</script>
