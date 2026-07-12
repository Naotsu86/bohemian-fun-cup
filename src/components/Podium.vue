<template>
  <div class="podium">
    <article
      v-for="(row, index) in topRows"
      :key="row.id"
      class="podium-card podium-card-with-avatar"
      :class="'place-' + (index + 1)"
    >
      <button
        class="podium-avatar-button"
        type="button"
        title="Spielerkarte öffnen"
        @click="$emit('select-player', row)"
      >
        <AvatarPreview :avatar="row" compact />
      </button>

      <button
        class="podium-content podium-content-button"
        type="button"
        title="Spielerkarte öffnen"
        @click="$emit('select-player', row)"
      >
        <div class="podium-title">{{ row.selected_title_name || 'Kein Titel' }}</div>
        <div class="podium-name">{{ row.name }}</div>
        <div class="podium-points">{{ row.points }} Punkte</div>
        <div class="podium-meta">{{ row.games }} Spiele · {{ row.wins }} Siege</div>
      </button>

      <img class="place-badge" :src="badge(index)" :alt="`${index + 1}. Platz`" />
    </article>
  </div>
</template>

<script setup>
import AvatarPreview from './avatar/AvatarPreview.vue'

defineProps({ topRows: Array })
defineEmits(['select-player'])

const base = import.meta.env.BASE_URL

function badge(index) {
  if (index === 0) return `${base}badges/first.png`
  if (index === 1) return `${base}badges/second.png`
  return `${base}badges/third.png`
}
</script>

<style scoped>
.podium-card-with-avatar{
  grid-template-columns: 56px 1fr 24px !important;
}

.podium-avatar-button{
  width:52px;
  height:52px;
  border:3px solid var(--pixel-border, #2b2115);
  background:linear-gradient(#7bd3ff 0 55%, #e7b861 55%);
  overflow:hidden;
  flex:0 0 auto;
  padding:0;
  cursor:pointer;
}

.podium-content{
  text-align:left;
}

.podium-content-button{
  border:0;
  background:transparent;
  padding:0;
  font:inherit;
  color:inherit;
  cursor:pointer;
}

.podium-title{
  font-size:11px;
  color:#7c2d12;
  font-weight:900;
  margin-bottom:2px;
}

@media(max-width:760px){
  .podium-card-with-avatar{
    grid-template-columns: 44px 1fr 20px !important;
  }

  .podium-avatar-button{
    width:40px;
    height:40px;
  }
}
</style>
