<template>
  <div class="avatar-picker-row">
    <div class="avatar-picker-title">{{ title }}</div>

    <div class="avatar-picker-controls">
      <button class="avatar-arrow" type="button" @click="$emit('previous')">◀</button>

      <div class="avatar-picker-value">
        <span
          v-if="swatch"
          class="avatar-swatch"
          :style="{ background: swatch }"
        ></span>
        {{ label }}
      </div>

      <button class="avatar-arrow" type="button" @click="$emit('next')">▶</button>
    </div>
  </div>
</template>

<script setup>
defineProps({
  title: String,
  label: String,
  swatch: {
    type: String,
    default: ''
  }
})

defineEmits(['previous', 'next'])
</script>

<style scoped>
.avatar-picker-row{
  border:3px solid #c5a66f;
  background:#fff4d2;
  padding:7px;
  margin-bottom:7px;
}

.avatar-picker-title{
  font-family:var(--font-pixel, 'Silkscreen', monospace);
  letter-spacing:.08em;
  font-size:12px;
  margin-bottom:6px;
  color:#2b2115;
}

.avatar-picker-controls{
  display:grid;
  grid-template-columns:34px 1fr 34px;
  gap:6px;
  align-items:center;
}

.avatar-arrow{
  min-height:32px;
  border:3px solid #8a6330;
  background:#ffe2a8;
  color:#2b2115;
  font-weight:900;
  cursor:pointer;
  box-shadow:2px 2px 0 rgba(0,0,0,.18);
}

.avatar-picker-value{
  min-height:32px;
  display:flex;
  gap:7px;
  justify-content:center;
  align-items:center;
  border:3px solid #b89354;
  background:#fffdf6;
  font-weight:800;
  text-align:center;
  padding:0 6px;
}

.avatar-swatch{
  width:17px;
  height:17px;
  border:2px solid #2b2115;
  box-shadow:1px 1px 0 rgba(0,0,0,.22);
}
</style>
