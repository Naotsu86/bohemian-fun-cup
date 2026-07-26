<template>
  <section class="screen admin-screen">
    <AdminLogin
      v-if="!adminUnlocked"
      @login="$emit('login', $event)"
    />

    <template v-else>
      <div class="card pixel-card menu-window">
        <h2>
          <span class="headline-icon">🔧</span>
          Adminbereich
        </h2>

        <div class="menu-body session-card">
          <p class="muted">
            Angemeldet als {{ userEmail }}
          </p>

          <button
            class="btn danger"
            @click="$emit('logout')"
          >
            Abmelden
          </button>
        </div>
      </div>

      <div
        v-if="activePanel === 'menu'"
        class="admin-tile-grid"
      >
        <button
          class="admin-tile pixel-card"
          @click="activePanel = 'players'"
        >
          <span class="tile-icon">👥</span>
          <strong>Spielerverwaltung</strong>
          <small>
            Freigeben, anlegen und Spielerliste bearbeiten
          </small>

          <em v-if="pendingPlayers.length">
            {{ pendingPlayers.length }} wartet
          </em>
        </button>

        <button
          class="admin-tile pixel-card"
          @click="activePanel = 'games'"
        >
          <span class="tile-icon">🏐</span>
          <strong>Spiele</strong>
          <small>
            Neue Spiele erzeugen und Ergebnisse eintragen
          </small>
        </button>

        <button
          class="admin-tile pixel-card"
          @click="activePanel = 'catalog'"
        >
          <span class="tile-icon">🏷️</span>
          <strong>Titel / Special</strong>
          <small>
            Titel, Bedingungen und Spezialattacken pflegen
          </small>
        </button>
      </div>

      <template v-else>
        <button
          class="btn full back-btn"
          @click="activePanel = 'menu'"
        >
          ← Zurück zur Admin-Übersicht
        </button>

        <template v-if="activePanel === 'players'">
          <div class="card pixel-card menu-window">
            <h2>🕘 Wartende Spieler</h2>

            <div class="menu-body">
              <button
                class="btn full"
                @click="$emit('refresh')"
              >
                Aktualisieren
              </button>

              <p
                v-if="pendingPlayers.length === 0"
                class="muted"
              >
                Aktuell wartet kein Spieler auf Freigabe.
              </p>

              <div class="pending-list">
                <div
                  v-for="player in pendingPlayers"
                  :key="player.id"
                  class="pending-row"
                >
                  <div>
                    <strong>{{ player.name }}</strong>

                    <div class="muted small">
                      {{ player.email || '-' }}
                    </div>

                    <div class="muted small">
                      Status: wartet auf Freigabe
                    </div>
                  </div>

                  <button
                    class="btn primary"
                    :disabled="approvingId === player.id"
                    @click="approve(player.id)"
                  >
                    {{
                      approvingId === player.id
                        ? 'WIRD FREIGEGEBEN...'
                        : 'FREIGEBEN'
                    }}
                  </button>
                </div>
              </div>

              <p
                v-if="message"
                class="hint"
              >
                {{ message }}
              </p>
            </div>
          </div>

          <div class="card pixel-card menu-window">
            <h2>Spieler manuell anlegen</h2>

            <div class="menu-body">
              <p class="muted">
                Normalerweise registrieren sich Spieler selbst.
                Hier kannst du bei Bedarf trotzdem Spieler ohne
                Login anlegen.
              </p>

              <div class="row">
                <div class="field">
                  <label>Name</label>
                  <input
                    v-model="newName"
                    placeholder="z. B. Alex"
                  >
                </div>

                <div class="field">
                  <label>Stärke 1-12</label>

                  <select v-model.number="newStrength">
                    <option
                      v-for="n in 12"
                      :key="n"
                      :value="n"
                    >
                      {{ n }}
                    </option>
                  </select>
                </div>
              </div>

              <button
                class="btn primary full"
                @click="add"
              >
                Spieler hinzufügen
              </button>
            </div>
          </div>

          <div class="card pixel-card menu-window">
            <h2>Spielerliste</h2>

            <div class="menu-body">
              <p
                v-if="players.length === 0"
                class="muted"
              >
                Noch keine Spieler angelegt.
              </p>

              <div class="admin-player-list">
                <div
                  v-for="player in players"
                  :key="player.id"
                  class="player playerrow"
                >
                  <div>
                    <label>Name</label>

                    <input
                      :value="player.name"
                      @change="
                        $emit(
                          'update-player',
                          player.id,
                          { name: $event.target.value }
                        )
                      "
                    >

                    <div
                      v-if="player.email"
                      class="muted small"
                    >
                      {{ player.email }}
                    </div>

                    <div class="muted small">
                      Status:
                      {{
                        player.approved
                          ? 'Freigegeben'
                          : 'Wartet'
                      }}
                    </div>
                  </div>

                  <div>
                    <label>Stärke</label>

                    <select
                      :value="player.strength"
                      @change="
                        $emit(
                          'update-player',
                          player.id,
                          {
                            strength:
                              Number($event.target.value)
                          }
                        )
                      "
                    >
                      <option
                        v-for="n in 12"
                        :key="n"
                        :value="n"
                      >
                        {{ n }}
                      </option>
                    </select>

                    <div class="muted small">
                      Form:
                      {{ Number(player.form || 0).toFixed(2) }}
                    </div>
                  </div>

                  <div class="player-actions">
                    <button
                      class="btn"
                      :class="{
                        inactive: player.active === false
                      }"
                      @click="
                        $emit(
                          'update-player',
                          player.id,
                          {
                            active:
                              player.active === false
                          }
                        )
                      "
                    >
                      {{
                        player.active === false
                          ? 'Inaktiv'
                          : 'Aktiv'
                      }}
                    </button>

                    <button
                      v-if="!player.approved"
                      class="btn primary"
                      :disabled="approvingId === player.id"
                      @click="approve(player.id)"
                    >
                      {{
                        approvingId === player.id
                          ? 'WIRD FREIGEGEBEN...'
                          : 'FREIGEBEN'
                      }}
                    </button>

                    <button
                      class="btn danger"
                      @click="
                        $emit(
                          'delete-player',
                          player.id
                        )
                      "
                    >
                      Löschen
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <AdminStatPointGrant
            :players="players"
            @updated="$emit('refresh')"
          />
        </template>

        <template v-if="activePanel === 'games'">
          <div class="card pixel-card menu-window">
            <h2>Nächstes Spiel</h2>

            <div class="menu-body">
              <p class="muted">
                Normale Spiele und einfache Entscheidungsspiele
                mit genau zwei punktgleichen Spielern werden hier erzeugt.
              </p>

              <div class="field">
                <label>Modus</label>

                <select v-model="mode">
                  <option value="2v2">2 gegen 2</option>
                  <option value="2v3">2 gegen 3</option>
                  <option value="3v3">3 gegen 3</option>
                  <option value="3v4">3 gegen 4</option>
                  <option value="4v4">4 gegen 4</option>

                  <optgroup
                    v-if="twoPlayerTiebreaks.length"
                    label="Entscheidungsspiele"
                  >
                    <option
                      v-for="group in twoPlayerTiebreaks"
                      :key="group.key"
                      :value="group.modeValue"
                    >
                      Entscheidung um Platz {{ group.place }}:
                      {{ group.players[0].name }} gegen
                      {{ group.players[1].name }}
                    </option>
                  </optgroup>
                </select>
              </div>

              <button
                class="btn primary full"
                @click="createSelectedMatch"
              >
                Spiel erzeugen
              </button>

              <p v-if="message" class="hint">
                {{ message }}
              </p>
            </div>
          </div>

          <div
            v-if="multiPlayerTiebreaks.length"
            class="card pixel-card menu-window"
          >
            <h2>⚔️ Entscheidungsrunden</h2>

            <div class="menu-body">
              <p class="muted">
                Bei drei oder mehr punktgleichen Spielern wird
                eine Jeder-gegen-jeden-Runde benötigt.
              </p>

              <div class="tiebreak-group-list">
                <article
                  v-for="group in multiPlayerTiebreaks"
                  :key="group.key"
                  class="tiebreak-group"
                >
                  <div class="tiebreak-group-head">
                    <div>
                      <strong>
                        Plätze {{ group.place }}–{{ group.endPlace }}
                      </strong>
                      <small>
                        {{ formatPoints(group.points) }} Punkte
                      </small>
                    </div>

                    <span class="tiebreak-count">
                      {{ group.players.length }} Spieler
                    </span>
                  </div>

                  <div class="tiebreak-player-list">
                    <span
                      v-for="player in group.players"
                      :key="player.id"
                    >
                      {{ player.name }}
                    </span>
                  </div>

                  <div class="tiebreak-pairing-list">
                    <div
                      v-for="pairing in group.pairings"
                      :key="pairing.key"
                      class="tiebreak-pairing"
                    >
                      <span>{{ pairing.playerA.name }}</span>
                      <strong>VS</strong>
                      <span>{{ pairing.playerB.name }}</span>
                    </div>
                  </div>

                  <button
                    class="btn primary full"
                    @click="
                      $emit('create-tiebreak-round', {
                        place: group.place,
                        points: group.points,
                        playerIds: group.players.map(player => player.id)
                      })
                    "
                  >
                    Jeder-gegen-jeden-Runde erzeugen
                  </button>
                </article>
              </div>
            </div>
          </div>

          <div
            v-if="
              !twoPlayerTiebreaks.length &&
              !multiPlayerTiebreaks.length
            "
            class="card pixel-card menu-window"
          >
            <h2>⚔️ Entscheidungsspiele</h2>

            <div class="menu-body">
              <p class="muted">
                Aktuell gibt es keine punktgleichen Spieler,
                für die ein Entscheidungsspiel benötigt wird.
              </p>
            </div>
          </div>

          <div class="card pixel-card menu-window">
            <h2>Ergebnisse eintragen</h2>

            <div class="menu-body">
              <p
                v-if="matches.length === 0"
                class="muted"
              >
                Noch keine Spiele angelegt.
              </p>

              <MatchCard
                v-for="match in sortedMatches"
                :key="match.id"
                :match="match"
                :number="matchNumber(match)"
                :editable="true"
                :name-of="nameOf"
                @delete="$emit('delete-match', $event)"
                @score="$emit('score', $event)"
              />
            </div>
          </div>
        </template>

        <AdminRpgCatalogManager
          v-if="activePanel === 'catalog'"
        />
      </template>
    </template>
  </section>
</template>

<script setup>
import { computed, ref } from 'vue'
import AdminLogin from '../components/AdminLogin.vue'
import MatchCard from '../components/MatchCard.vue'
import AdminRpgCatalogManager from '../components/admin/AdminRpgCatalogManager.vue'
import AdminStatPointGrant from '../components/admin/AdminStatPointGrant.vue'

const props = defineProps({
  adminUnlocked: Boolean,
  userEmail: String,
  players: {
    type: Array,
    default: () => []
  },
  matches: {
    type: Array,
    default: () => []
  },
  tiebreakGroups: {
    type: Array,
    default: () => []
  },
  rules: String,
  message: String,
  matchNumber: Function,
  nameOf: Function
})

const emit = defineEmits([
  'login',
  'logout',
  'refresh',
  'approve-player',
  'add-player',
  'update-player',
  'delete-player',
  'create-match',
  'create-tiebreak-match',
  'create-tiebreak-round',
  'delete-match',
  'score',
  'update-rules'
])

const activePanel = ref('menu')
const newName = ref('')
const newStrength = ref(6)
const mode = ref('4v4')
const approvingId = ref(null)

const pendingPlayers = computed(() =>
  (props.players || []).filter(
    player =>
      player.approved === false ||
      player.approved === null ||
      player.approved === undefined
  )
)

const twoPlayerTiebreaks = computed(() =>
  (props.tiebreakGroups || [])
    .filter(group => group.players.length === 2)
    .map(group => ({
      ...group,
      modeValue:
        `tiebreak:${group.players[0].id}:` +
        group.players[1].id
    }))
)

const multiPlayerTiebreaks = computed(() =>
  (props.tiebreakGroups || [])
    .filter(group => group.players.length >= 3)
    .map(group => ({
      ...group,
      pairings: buildPairings(group.players)
    }))
)

const sortedMatches = computed(() => {
  return [...(props.matches || [])].sort((a, b) => {
    const aFinished =
      a.score_a !== null &&
      a.score_b !== null &&
      a.score_a !== '' &&
      a.score_b !== ''

    const bFinished =
      b.score_a !== null &&
      b.score_b !== null &&
      b.score_a !== '' &&
      b.score_b !== ''

    if (aFinished !== bFinished) {
      return aFinished ? 1 : -1
    }

    return props.matchNumber(b) - props.matchNumber(a)
  })
})

function add() {
  const name = newName.value.trim()

  if (!name) return

  emit('add-player', {
    name,
    strength: Number(newStrength.value)
  })

  newName.value = ''
  newStrength.value = 6
}

function approve(playerId) {
  approvingId.value = playerId
  emit('approve-player', playerId)

  window.setTimeout(() => {
    approvingId.value = null
  }, 2500)
}

function createSelectedMatch() {
  const selectedMode = String(mode.value)

  if (!selectedMode.startsWith('tiebreak:')) {
    emit('create-match', selectedMode)
    return
  }

  const [, playerAId, playerBId] =
    selectedMode.split(':')

  emit('create-tiebreak-match', {
    playerAId,
    playerBId
  })
}

function buildPairings(players) {
  const pairings = []

  for (let i = 0; i < players.length; i += 1) {
    for (let j = i + 1; j < players.length; j += 1) {
      pairings.push({
        key: `${players[i].id}|${players[j].id}`,
        playerA: players[i],
        playerB: players[j]
      })
    }
  }

  return pairings
}

function formatPoints(value) {
  return Number(value || 0)
    .toFixed(2)
    .replace('.', ',')
    .replace(',00', '')
}
</script>

<style scoped>
.admin-tile-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
}

.admin-tile {
  display: flex;
  flex-direction: column;
  gap: 8px;
  min-height: 170px;
  padding: 18px;
  border: 4px solid #2b2115;
  background: #fff4d2;
  text-align: left;
  cursor: pointer;
  box-shadow: 5px 5px 0 rgba(0, 0, 0, 0.22);
}

.admin-tile:hover {
  transform: translate(-1px, -1px);
}

.tile-icon {
  font-size: 34px;
}

.admin-tile strong {
  font-family: var(--font-pixel, "Silkscreen", monospace);
  font-size: 18px;
  letter-spacing: 2px;
}

.admin-tile small {
  color: #5f6f86;
  font-size: 14px;
}

.admin-tile em {
  display: inline-block;
  margin-top: auto;
  color: #991b1b;
  font-style: normal;
  font-weight: 900;
}

.back-btn {
  margin-bottom: 12px;
}

.pending-list {
  display: grid;
  gap: 10px;
  margin-top: 12px;
}

.pending-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  padding: 10px;
  border: 3px solid #c5a66f;
  background: #fffdf6;
}

.tiebreak-group-list {
  display: grid;
  gap: 14px;
}

.tiebreak-group {
  padding: 12px;
  border: 3px solid #b89354;
  background: #fffdf6;
}

.tiebreak-group-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  margin-bottom: 10px;
}

.tiebreak-group-head strong {
  display: block;
  font-family: var(--font-pixel, "Silkscreen", monospace);
  letter-spacing: 1px;
}

.tiebreak-group-head small {
  display: block;
  margin-top: 4px;
  color: #5f6f86;
}

.tiebreak-count {
  padding: 5px 8px;
  border: 2px solid #8a6330;
  background: #fff4d2;
  font-weight: 900;
}

.tiebreak-player-list {
  display: flex;
  flex-wrap: wrap;
  gap: 7px;
  margin-bottom: 10px;
}

.tiebreak-player-list span {
  padding: 5px 8px;
  border: 2px solid #c5a66f;
  background: #fff4d2;
  font-weight: 800;
}

.tiebreak-pairing-list {
  display: grid;
  gap: 6px;
  margin-bottom: 12px;
}

.tiebreak-pairing {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto minmax(0, 1fr);
  gap: 10px;
  align-items: center;
  padding: 7px 9px;
  border: 2px solid #d1b682;
  background: #fff9e8;
}

.tiebreak-pairing span:last-child {
  text-align: right;
}

.tiebreak-pairing strong {
  color: #7f1d1d;
}

@media (max-width: 850px) {
  .admin-tile-grid {
    grid-template-columns: 1fr;
  }

  .admin-tile {
    min-height: 130px;
  }

  .pending-row {
    flex-direction: column;
    align-items: stretch;
  }
}

@media (max-width: 650px) {
  .tiebreak-group-head {
    align-items: stretch;
    flex-direction: column;
  }

  .tiebreak-count {
    align-self: flex-start;
  }

  .tiebreak-pairing {
    grid-template-columns: 1fr;
    text-align: center;
  }

  .tiebreak-pairing span:last-child {
    text-align: center;
  }
}
</style>