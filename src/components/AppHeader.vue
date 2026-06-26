<template>
  <header class="app-header">
    <div class="wrap header-wrap">
      <img class="header-logo" src="/bohemian-fun-cup/fun-cup-header.png" alt="Bohemian Fun Cup Beachvolleyball" />
      <button class="live-pill" @click="$emit('refresh')">{{ statusText }}</button>
    </div>
  </header>

  <nav class="bottom-nav" aria-label="Hauptnavigation">
    <button class="bottom-tab" :class="{ active: modelValue === 'overview' }" @click="$emit('update:modelValue','overview')">
      <span class="nav-icon">⌂</span><span>Übersicht</span>
    </button>
    <button class="bottom-tab" :class="{ active: modelValue === 'games' }" @click="$emit('update:modelValue','games')">
      <span class="nav-icon">▦</span><span>Spiele</span>
    </button>
    <button class="bottom-tab" :class="{ active: modelValue === 'ranking' }" @click="$emit('update:modelValue','ranking')">
      <span class="nav-icon">🏆</span><span>Rangliste</span>
    </button>
    <button class="bottom-tab" :class="{ active: modelValue === 'admin' }" @click="$emit('update:modelValue','admin')">
      <span class="nav-icon">♜</span><span>Admin</span>
    </button>
  </nav>
</template>
<script setup>
defineProps({ modelValue: String, statusText: String })
defineEmits(['update:modelValue','refresh'])
</script>
