<template>
  <header class="pixel-header">
    <div class="wrap header-wrap">
      <img class="header-logo" :src="headerImage" alt="Bohemian Fun Cup Beachvolleyball" />
      <button class="live-badge" @click="$emit('refresh')">
        <span class="live-dot"></span>
        {{ statusText }}
      </button>
    </div>
  </header>

  <nav class="pixel-bottom-nav" aria-label="Hauptnavigation">
    <button class="pixel-tab" :class="{ active: modelValue === 'overview' }" @click="$emit('update:modelValue','overview')">
      <span class="nav-icon">🏠</span>
      <span>Übersicht</span>
    </button>

    <button class="pixel-tab" :class="{ active: modelValue === 'games' }" @click="$emit('update:modelValue','games')">
      <span class="nav-icon">🏐</span>
      <span>Spiele</span>
    </button>

    <button class="pixel-tab" :class="{ active: modelValue === 'ranking' }" @click="$emit('update:modelValue','ranking')">
      <span class="nav-icon">🏆</span>
      <span>Rangliste</span>
    </button>

    <button class="pixel-tab" :class="{ active: modelValue === 'admin' }" @click="$emit('update:modelValue','admin')">
      <span class="nav-icon">🔧</span>
      <span>Admin</span>
    </button>
  </nav>
</template>

<script setup>
defineProps({ modelValue: String, statusText: String })
defineEmits(['update:modelValue','refresh'])

const headerImage = `${import.meta.env.BASE_URL}fun-cup-header.png`
</script>
