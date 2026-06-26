<template>
  <header class="pixel-header">
    <div class="header-stage">
      <picture>
        <source media="(max-width: 760px)" :srcset="mobileHeader" />
        <img class="header-logo" :src="desktopHeader" alt="Bohemian Fun Cup Beachvolleyball" />
      </picture>

      <button class="live-badge" @click="$emit('refresh')">
        <span class="live-dot"></span>
        {{ statusText }}
      </button>

      <div class="pixel-wave wave-a"></div>
      <div class="pixel-wave wave-b"></div>
      <div class="floating-ball">🏐</div>
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

const desktopHeader = `${import.meta.env.BASE_URL}fun-cup-header-desktop.png`
const mobileHeader = `${import.meta.env.BASE_URL}fun-cup-header-mobile.png`
</script>
