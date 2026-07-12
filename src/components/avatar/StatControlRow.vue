<template>
  <div class="stat-control-row" :class="'bar-' + color">
    <div class="stat-icon-box">
      <img class="stat-icon" :src="iconSrc" alt="" />
    </div>

    <div class="stat-content">
      <div class="stat-name">{{ label }}</div>

      <div class="stat-control">
        <button
          class="pixel-step-btn"
          type="button"
          :disabled="!canRemove"
          @click="$emit('remove')"
        >
          −
        </button>

        <div class="stat-value-box">
          <span class="stat-total">{{ total }}</span>
          <span v-if="pending" class="stat-pending">+{{ pending }}</span>
        </div>

        <button
          class="pixel-step-btn"
          type="button"
          :disabled="!canAdd"
          @click="$emit('add')"
        >
          +
        </button>
      </div>

      <div class="pixel-progress">
        <div class="pixel-progress-fill" :style="{ width: percent + '%' }"></div>
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
  canAdd: { type: Boolean, default: false },
  canRemove: { type: Boolean, default: false }
})

defineEmits(['add', 'remove'])

const base = import.meta.env.BASE_URL
const iconSrc = computed(() => `${base}stat-icons/${props.icon}.png`)
const total = computed(() => Number(props.value || 0) + Number(props.pending || 0))
const percent = computed(() => Math.max(0, Math.min(100, total.value)))
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

.stat-name{
  font-family:var(--font-pixel, 'Silkscreen', monospace);
  letter-spacing:2px;
  text-transform:uppercase;
  text-align:center;
  color:#7c2d12;
  font-size:13px;
  font-weight:900;
}

.stat-control{
  display:grid;
  grid-template-columns:42px 1fr 42px;
  gap:8px;
  align-items:center;
}

.pixel-step-btn{
  height:36px;
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

.stat-value-box{
  min-height:36px;
  border:3px solid #b99b69;
  background:#fffdf6;
  display:flex;
  align-items:center;
  justify-content:center;
  gap:6px;
  font-weight:950;
  box-sizing:border-box;
}

.stat-total{
  font-size:24px;
}

.stat-pending{
  color:#15803d;
  font-size:13px;
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
}
</style>
