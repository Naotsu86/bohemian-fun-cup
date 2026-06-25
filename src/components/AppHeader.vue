<template>
  <header>
    <div class="wrap">
      <div class="hero">
        <div class="ball">🏐</div>
        <div>
          <h1>Bohemian Fun Cup</h1>
          <div class="sub">Beachvolleyball · Punktewertung pro Spieler</div>
        </div>
        <div class="pill">lokal</div>
      </div>

      <nav>
        <button class="tab" :class="{ active: modelValue === 'overview' }" @click="$emit('update:modelValue', 'overview')">Übersicht</button>
        <button class="tab" :class="{ active: modelValue === 'games' }" @click="$emit('update:modelValue', 'games')">Spiele</button>
        <button class="tab" :class="{ active: modelValue === 'ranking' }" @click="$emit('update:modelValue', 'ranking')">Rangliste</button>
        <button class="tab" :class="{ active: modelValue === 'admin' }" @click="$emit('update:modelValue', 'admin')">Admin</button>
      </nav>
    </div>
  </header>
</template>

<script setup>
defineProps({
  modelValue: {
    type: String,
    required: true,
  },
})

defineEmits(['update:modelValue'])
</script>
