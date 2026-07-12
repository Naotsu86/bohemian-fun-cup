<template>
  <div class="player-card-backdrop" @click.self="$emit('close')">
    <article class="player-card-modal pixel-card">
      <button class="player-card-close" type="button" @click="$emit('close')" aria-label="Schließen">
        ×
      </button>

      <h2>SPIELERKARTE</h2>

      <div class="player-card-main">
        <div class="player-card-avatar-box">
          <AvatarPreview :avatar="card" />
        </div>

        <div class="player-card-info">
          <div class="card-label">TITLE</div>
          <div class="player-card-title">{{ card.selected_title_name || 'Kein Titel' }}</div>

          <div class="card-label">NAME</div>
          <div class="player-card-name">{{ card.name || card.real_name || '-' }}</div>

          <div class="special-box">
            <div class="card-label">SPECIAL</div>
            <strong>{{ card.selected_special_attack_name || 'Keine' }}</strong>
            <small v-if="card.selected_special_attack_description">
              {{ card.selected_special_attack_description }}
            </small>
          </div>

          <div class="level-box">
            <div class="level-head">
              <strong>LEVEL {{ level }}</strong>
              <span>{{ xpTotal }} XP</span>
            </div>
            <div class="xp-bar">
              <div class="xp-fill" :style="{ width: xpPercent + '%' }"></div>
            </div>
            <small>{{ xpTotal }} / {{ nextLevelXp }} XP</small>
          </div>
        </div>
      </div>

      <p v-if="loading" class="muted">Spielerkarte wird geladen...</p>
      <p v-if="loadError" class="card-error">{{ loadError }}</p>

      <div class="stat-list">
        <PlayerCardStatRow icon="teamgeist" label="TEAMGEIST" color="red" :value="Number(card.stat_teamgeist || 0)" />
        <PlayerCardStatRow icon="speed" label="SPEED" color="yellow" :value="Number(card.stat_geschwindigkeit || 0)" />
        <PlayerCardStatRow icon="kraft" label="KRAFT" color="orange" :value="Number(card.stat_kraft || 0)" />
        <PlayerCardStatRow icon="technik" label="TECHNIK" color="blue" :value="Number(card.stat_technik || 0)" />
        <PlayerCardStatRow icon="ehrgeiz" label="EHRGEIZ" color="red" :value="Number(card.stat_ehrgeiz || 0)" />
      </div>
    </article>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import AvatarPreview from './avatar/AvatarPreview.vue'
import PlayerCardStatRow from './PlayerCardStatRow.vue'
import { supabase } from '../api/supabase'

const props = defineProps({
  player: {
    type: Object,
    required: true
  }
})

defineEmits(['close'])

const card = ref(normalizeCard(props.player))
const loading = ref(false)
const loadError = ref('')

watch(() => props.player, async player => {
  card.value = normalizeCard(player)
  await loadFreshCard()
})

onMounted(loadFreshCard)

const xpTotal = computed(() => Number(card.value.xp_total || 0))
const level = computed(() => Number(card.value.calculated_level || card.value.level || levelFromXp(xpTotal.value)))
const currentLevelXp = computed(() => Number(card.value.current_level_xp || xpForLevel(level.value)))
const nextLevelXp = computed(() => Number(card.value.next_level_xp || xpForLevel(level.value + 1)))

const xpPercent = computed(() => {
  const range = Math.max(nextLevelXp.value - currentLevelXp.value, 1)
  return Math.max(0, Math.min(100, Math.round(((xpTotal.value - currentLevelXp.value) / range) * 100)))
})

function normalizeCard(row) {
  return {
    ...row,
    xp_total: Number(row?.xp_total || 0),
    calculated_level: Number(row?.calculated_level || row?.level || 1),
    current_level_xp: Number(row?.current_level_xp || 0),
    next_level_xp: Number(row?.next_level_xp || 25),
    stat_teamgeist: Number(row?.stat_teamgeist || 0),
    stat_geschwindigkeit: Number(row?.stat_geschwindigkeit || 0),
    stat_kraft: Number(row?.stat_kraft || 0),
    stat_technik: Number(row?.stat_technik || 0),
    stat_ehrgeiz: Number(row?.stat_ehrgeiz || 0),
    body_color: row?.body_color || row?.avatar_body || 'black',
    head_item: row?.head_item || 'none',
    top_item: row?.top_item || 'none',
    bottom_item: row?.bottom_item || row?.shorts_item || 'none',
    shorts_item: row?.bottom_item || row?.shorts_item || 'none',
    accessory_item: row?.accessory_item || 'none'
  }
}

async function loadFreshCard() {
  const playerId = props.player?.id || props.player?.player_id
  if (!playerId) return

  loading.value = true
  loadError.value = ''

  try {
    const { data, error } = await supabase.rpc('get_player_cards')

    if (error) throw error

    const fresh = (data || []).find(row => row.player_id === playerId)

    if (fresh) {
      card.value = normalizeCard({
        ...props.player,
        ...fresh,
        id: props.player.id,
        name: props.player.name || fresh.real_name
      })
    }
  } catch (error) {
    loadError.value = error.message || 'Spielerkarte konnte nicht geladen werden.'
  } finally {
    loading.value = false
  }
}

function xpForLevel(targetLevel) {
  let needed = 0
  for (let current = 1; current < targetLevel; current += 1) needed += current * 15 + 10
  return needed
}

function levelFromXp(totalXp) {
  let lvl = 1
  while (totalXp >= xpForLevel(lvl + 1) && lvl < 99) lvl += 1
  return lvl
}
</script>

<style scoped>
.player-card-backdrop{
  position:fixed;
  inset:0;
  z-index:1000;
  display:grid;
  place-items:center;
  padding:16px;
  background:rgba(15,23,42,.58);
}

.player-card-modal{
  position:relative;
  width:min(720px, 96vw);
  max-height:92vh;
  overflow:auto;
  border:5px solid #2b2115;
  background:#fff4d2;
  padding:16px;
  box-shadow:8px 8px 0 rgba(0,0,0,.28);
}

.player-card-close{
  position:absolute;
  top:8px;
  right:8px;
  width:38px;
  height:38px;
  border:4px solid #2b2115;
  background:#fffdf6;
  color:#7f1d1d;
  font-family:var(--font-pixel, 'Silkscreen', monospace);
  font-size:22px;
  font-weight:950;
  line-height:1;
  display:grid;
  place-items:center;
  cursor:pointer;
  box-shadow:3px 3px 0 rgba(0,0,0,.25);
}

.player-card-close:hover{
  background:#fee2e2;
}

.player-card-modal h2{
  padding-right:46px;
}

.player-card-main{
  display:grid;
  grid-template-columns:260px 1fr;
  gap:16px;
  align-items:start;
}

.player-card-avatar-box{
  border:4px solid #2b2115;
  background:#fffdf6;
  padding:8px;
}

.card-label,
.level-head strong{
  font-family:var(--font-pixel, 'Silkscreen', monospace);
  letter-spacing:2px;
  text-transform:uppercase;
}

.card-label{
  font-size:11px;
  color:#5f6f86;
  margin-top:8px;
}

.player-card-title{
  font-family:var(--font-pixel, 'Silkscreen', monospace);
  font-size:20px;
  color:#7c2d12;
  font-weight:900;
  margin-bottom:8px;
  letter-spacing:2px;
  text-transform:uppercase;
}

.player-card-name{
  font-size:28px;
  font-weight:950;
  margin-bottom:14px;
}

.special-box,
.level-box{
  border:3px solid #b89354;
  background:#fffdf6;
  padding:10px;
  margin-top:10px;
}

.special-box small{
  display:block;
  margin-top:5px;
  color:#5f6f86;
}

.level-head{
  display:flex;
  justify-content:space-between;
  gap:8px;
  align-items:center;
  margin-bottom:6px;
}

.xp-bar{
  height:20px;
  border:3px solid #2b2115;
  background:
    repeating-linear-gradient(90deg, rgba(43,33,21,.20) 0 2px, transparent 2px 18px),
    linear-gradient(#f8edc8 0 42%, #ead79f 42% 60%, #c9a96a 60% 100%);
  overflow:hidden;
  image-rendering:pixelated;
}

.xp-fill{
  height:100%;
  background:linear-gradient(#6ee036 0 42%, #32b42e 42% 60%, #15803d 60%);
  box-shadow:inset 0 3px 0 rgba(255,255,255,.45), inset 0 -4px 0 rgba(0,0,0,.18);
}

.stat-list{
  margin-top:16px;
  display:grid;
  gap:8px;
}

.card-error{
  background:#fee2e2;
  border:3px solid #7f1d1d;
  color:#991b1b;
  padding:8px;
  font-weight:800;
}

@media(max-width:760px){
  .player-card-main{
    grid-template-columns:1fr;
  }

  .player-card-avatar-box{
    max-width:260px;
    margin:auto;
  }
}
</style>
