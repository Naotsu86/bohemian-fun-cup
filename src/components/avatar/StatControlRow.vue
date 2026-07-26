<template>
  <div class="stat-control-row" :class="'bar-' + color">
    <div class="stat-icon-box">
      <img class="stat-icon" :src="iconSrc" alt="" />
    </div>

    <div class="stat-content">
      <div class="stat-head">
        <div class="stat-name">{{ label }}</div>
        <div class="stat-level">LV {{ statLevel }}</div>
      </div>

      <div class="stat-control">
        <button
          class="pixel-step-btn"
          type="button"
          :disabled="pending <= 0"
          @click="changePending(-1)"
        >
          −
        </button>

        <div class="stat-input-wrap">
          <label>PUNKTE HINZUFÜGEN</label>
          <input
            class="stat-input"
            type="text"
            inputmode="numeric"
            pattern="[0-9]*"
            :value="pending"
            @input="onInput"
            @focus="$event.target.select()"
          >
        </div>

        <button
          class="pixel-step-btn"
          type="button"
          :disabled="pending >= maxPending"
          @click="changePending(1)"
        >
          +
        </button>
      </div>

      <div class="stat-summary">
        <span>Gesamt: <strong>{{ total }}</strong></span>
        <span>Nächstes Level: <strong>{{ nextLevelAt }}</strong></span>
      </div>

      <div class="pixel-progress">
        <div class="pixel-progress-fill" :style="{ width: levelPercent + '%' }"></div>
      </div>

      <div class="level-progress-text">
        {{ pointsInLevel }} / 100 Punkte in LV {{ statLevel }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  icon: { type: String, required: true },
  label: { type: String, required: true },
  color: { type: String, default: 'green' },
  value: { type: Number, default: 0 },
  pending: { type: Number, default: 0 },
  maxPending: { type: Number, default: 0 }
})

const emit = defineEmits(['update:pending'])

const base = import.meta.env.BASE_URL
const iconSrc = computed(() => `${base}stat-icons/${props.icon}.png`)

const total = computed(() =>
  Math.max(0, Number(props.value || 0) + Number(props.pending || 0))
)

const statLevel = computed(() =>
  Math.floor(total.value / 100) + 1
)

const pointsInLevel = computed(() =>
  total.value % 100
)

const levelPercent = computed(() =>
  Math.max(0, Math.min(100, pointsInLevel.value))
)

const nextLevelAt = computed(() =>
  statLevel.value * 100
)

function clampPending(value) {
  const number = Math.floor(Number(value || 0))

  if (!Number.isFinite(number)) return 0

  return Math.max(
    0,
    Math.min(number, Number(props.maxPending || 0))
  )
}

function onInput(event) {
  const digits = String(event.target.value || '').replace(/\D/g, '')
  const nextValue = clampPending(digits === '' ? 0 : digits)

  event.target.value = String(nextValue)
  emit('update:pending', nextValue)
}

function changePending(change) {
  emit(
    'update:pending',
    clampPending(Number(props.pending || 0) + change)
  )
}
</script>

<style scoped>
.stat-control-row{
  display:grid;
  grid-template-columns:76px 1fr;
  gap:10px;
  align-items:center;
  width:100%;
  border:3px solid #c5a66f;
  background:#fffaf0;
  padding:8px;
  margin-top:8px;
  box-sizing:border-box;
}

.stat-icon-box{
  width:66px;
  height:66px;
  border:3px solid #c5a66f;
  background:#fff4d2;
  display:grid;
  place-items:center;
  box-sizing:border-box;
}

.stat-icon{
  width:54px;
  height:54px;
  object-fit:contain;
  image-rendering:pixelated;
}

.stat-content{
  min-width:0;
  display:grid;
  gap:7px;
}

.stat-head{
  display:flex;
  justify-content:space-between;
  align-items:center;
  gap:8px;
}

.stat-name,
.stat-level{
  font-family:var(--font-pixel, 'Silkscreen', monospace);
  letter-spacing:2px;
  text-transform:uppercase;
  color:#7c2d12;
  font-size:13px;
  font-weight:900;
}

.stat-level{
  border:2px solid #8a6330;
  background:#fff4d2;
  padding:3px 6px;
  white-space:nowrap;
}

.stat-control{
  display:grid;
  grid-template-columns:42px minmax(120px, 1fr) 42px;
  gap:8px;
  align-items:end;
}

.pixel-step-btn{
  height:42px;
  border:3px solid #8a6330;
  background:#fffdf6;
  color:#b91c1c;
  font-family:var(--font-pixel, 'Silkscreen', monospace);
  font-weight:950;
  font-size:22px;
  line-height:1;
  cursor:pointer;
  box-shadow:2px 2px 0 rgba(0,0,0,.18);
}

.pixel-step-btn:disabled{
  opacity:.35;
  cursor:not-allowed;
  box-shadow:none;
}

.stat-input-wrap{
  min-width:0;
}

.stat-input-wrap label{
  display:block;
  margin-bottom:3px;
  color:#5f6f86;
  font-size:9px;
  font-weight:900;
  text-align:center;
}

.stat-input{
  width:100%;
  height:42px;
  border:3px solid #b99b69;
  background:#fffdf6;
  box-sizing:border-box;
  text-align:center;
  font-family:var(--font-pixel, 'Silkscreen', monospace);
  font-size:20px;
  font-weight:950;
  appearance:textfield;
}

.stat-input::-webkit-outer-spin-button,
.stat-input::-webkit-inner-spin-button{
  appearance:none;
  margin:0;
}

.stat-summary{
  display:flex;
  justify-content:space-between;
  gap:10px;
  flex-wrap:wrap;
  color:#5f6f86;
  font-size:11px;
}

.stat-summary strong{
  color:#2b2115;
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
  box-shadow:
    inset 0 3px 0 rgba(255,255,255,.45),
    inset 0 -4px 0 rgba(0,0,0,.18);
}

.level-progress-text{
  color:#5f6f86;
  font-size:10px;
  font-weight:800;
  text-align:right;
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

@media(max-width:760px){
  .stat-control-row{
    grid-template-columns:64px 1fr;
  }

  .stat-icon-box{
    width:56px;
    height:56px;
  }

  .stat-icon{
    width:46px;
    height:46px;
  }

  .stat-head{
    align-items:flex-start;
  }

  .stat-name{
    font-size:11px;
  }

  .stat-level{
    font-size:10px;
  }

  .stat-control{
    grid-template-columns:38px minmax(90px, 1fr) 38px;
  }
}
</style>
