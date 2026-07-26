<template>
  <div class="card-stat-row" :class="'bar-' + color">
<div class="card-stat-head">
  <div class="card-stat-title">
    <img class="card-stat-icon" :src="iconSrc" alt="" />
    <span>{{ label }}</span>
  </div>

  <div class="card-stat-values">
    <strong>{{ value }}</strong>
    <span>LV {{ statLevel }}</span>
  </div>
</div>

    <div class="pixel-progress">
      <div class="pixel-progress-fill" :style="{ width: percent + '%' }"></div>
    </div>
    <div class="card-stat-progress-text">
  {{ pointsInLevel }} / 100 Punkte in LV {{ statLevel }}
</div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  icon: { type: String, required: true },
  label: { type: String, required: true },
  color: { type: String, default: 'green' },
  value: { type: Number, default: 0 }
})

const base = import.meta.env.BASE_URL
const iconSrc = computed(() => `${base}stat-icons/${props.icon}.png`)
const statLevel = computed(() =>
  Math.floor(Math.max(0, Number(props.value || 0)) / 100) + 1
)

const pointsInLevel = computed(() =>
  Math.max(0, Number(props.value || 0)) % 100
)

const percent = computed(() =>
  Math.max(0, Math.min(100, pointsInLevel.value))
)
</script>

<style scoped>
.card-stat-row{
  border:3px solid #d2b887;
  background:#fffaf0;
  padding:8px;
  box-sizing:border-box;
}

.card-stat-head{
  display:flex;
  justify-content:space-between;
  gap:8px;
  align-items:center;
  font-family:var(--font-pixel, 'Silkscreen', monospace);
  letter-spacing:2px;
  text-transform:uppercase;
  font-size:12px;
  margin-bottom:6px;
}

.card-stat-title{
  display:flex;
  align-items:center;
  gap:8px;
}

.card-stat-icon{
  width:34px;
  height:34px;
  object-fit:contain;
  image-rendering:pixelated;
}
.card-stat-values{
  display:flex;
  align-items:center;
  gap:10px;
}

.card-stat-values span{
  border:2px solid #8a6330;
  background:#fff4d2;
  padding:3px 6px;
  white-space:nowrap;
}

.card-stat-progress-text{
  margin-top:4px;
  text-align:right;
  font-size:10px;
  color:#5f6f86;
}
.pixel-progress{
  height:20px;
  border:3px solid #2b2115;
  overflow:hidden;
  image-rendering:pixelated;
  background:
    repeating-linear-gradient(90deg, rgba(43,33,21,.20) 0 2px, transparent 2px 18px),
    linear-gradient(#f8edc8 0 42%, #ead79f 42% 60%, #c9a96a 60% 100%);
}

.pixel-progress-fill{
  height:100%;
  box-shadow:inset 0 3px 0 rgba(255,255,255,.45), inset 0 -4px 0 rgba(0,0,0,.18);
}

.bar-red .pixel-progress-fill{
  background:linear-gradient(#ff6b6b 0 42%, #ef4444 42% 60%, #b91c1c 60%);
}

.bar-yellow .pixel-progress-fill{
  background:linear-gradient(#fde047 0 42%, #facc15 42% 60%, #ca8a04 60%);
}

.bar-orange .pixel-progress-fill{
  background:linear-gradient(#fb923c 0 42%, #f97316 42% 60%, #c2410c 60%);
}

.bar-blue .pixel-progress-fill{
  background:linear-gradient(#60a5fa 0 42%, #3b82f6 42% 60%, #1d4ed8 60%);
}

.bar-green .pixel-progress-fill{
  background:linear-gradient(#86efac 0 42%, #22c55e 42% 60%, #15803d 60%);
}
</style>
