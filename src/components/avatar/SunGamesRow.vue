<template>
  <div class="sun-games-row">
    <div class="sun-icon-box">
      <img class="sun-icon" :src="iconSrc" alt="" />
    </div>

    <div class="sun-content">
      <div class="sun-head">
        <div>
          <div class="sun-name">SONNENSPIELE</div>
          <div class="sun-hint">Automatisch gezählte Spiele auf der Sonnenseite</div>
        </div>
        <div class="sun-level">LV {{ level }}</div>
      </div>

      <div class="sun-value-row">
        <strong>{{ safeValue }}</strong>
        <span>Nächstes Level: {{ nextLevelAt }}</span>
      </div>

      <div class="pixel-progress">
        <div class="pixel-progress-fill" :style="{ width: percent + '%' }"></div>
      </div>

      <div class="sun-progress-text">
        {{ pointsInLevel }} / 50 Sonnenspiele in LV {{ level }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  value: { type: Number, default: 0 }
})

const iconSrc = `${import.meta.env.BASE_URL}stat-icons/sonnenspiele.png`
const safeValue = computed(() => Math.max(0, Number(props.value || 0)))
const level = computed(() => Math.floor(safeValue.value / 50) + 1)
const pointsInLevel = computed(() => safeValue.value % 50)
const nextLevelAt = computed(() => level.value * 50)
const percent = computed(() => Math.round((pointsInLevel.value / 50) * 100))
</script>

<style scoped>
.sun-games-row{
  display:grid;
  grid-template-columns:76px 1fr;
  gap:10px;
  align-items:center;
  width:100%;
  border:3px solid #d29b32;
  background:#fff7d8;
  padding:8px;
  margin:8px 0 14px;
  box-sizing:border-box;
}
.sun-icon-box{
  width:66px;height:66px;border:3px solid #d29b32;background:#fff1ae;
  display:grid;place-items:center;box-sizing:border-box;
}
.sun-icon{width:54px;height:54px;object-fit:contain;image-rendering:pixelated}
.sun-content{min-width:0;display:grid;gap:7px}
.sun-head,.sun-value-row{display:flex;justify-content:space-between;align-items:center;gap:10px}
.sun-name,.sun-level{
  font-family:var(--font-pixel,'Silkscreen',monospace);
  letter-spacing:2px;color:#8a4a08;font-weight:900
}
.sun-name{font-size:13px}
.sun-level{border:2px solid #8a6330;background:#fff4d2;padding:3px 6px;white-space:nowrap}
.sun-hint,.sun-value-row span,.sun-progress-text{color:#5f6f86;font-size:10px;font-weight:800}
.sun-value-row strong{
  font-family:var(--font-pixel,'Silkscreen',monospace);
  font-size:22px;color:#2b2115
}
.pixel-progress{
  height:20px;border:3px solid #2b2115;overflow:hidden;image-rendering:pixelated;
  background:
    repeating-linear-gradient(90deg,rgba(43,33,21,.20) 0 2px,transparent 2px 18px),
    linear-gradient(#f8edc8 0 42%,#ead79f 42% 60%,#c9a96a 60% 100%);
}
.pixel-progress-fill{
  height:100%;
  background:linear-gradient(#ffe36e 0 42%,#f7b718 42% 60%,#d87800 60%);
  box-shadow:inset 0 3px 0 rgba(255,255,255,.55),inset 0 -4px 0 rgba(0,0,0,.18);
}
.sun-progress-text{text-align:right}
@media(max-width:760px){
  .sun-games-row{grid-template-columns:64px 1fr}
  .sun-icon-box{width:56px;height:56px}
  .sun-icon{width:46px;height:46px}
  .sun-name{font-size:11px}
  .sun-level{font-size:10px}
}
</style>
