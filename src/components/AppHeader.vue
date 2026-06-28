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
    </div>
  </header>

  <nav class="pixel-bottom-nav" aria-label="Hauptnavigation">
    <button class="pixel-tab" :class="{ active: modelValue === 'overview' }" @click="$emit('update:modelValue','overview')">
      <img class="nav-icon-img" :src="icons.home" alt="" />
      <span>Übersicht</span>
    </button>

    <button class="pixel-tab" :class="{ active: modelValue === 'games' }" @click="$emit('update:modelValue','games')">
      <img class="nav-icon-img" :src="icons.games" alt="" />
      <span>Spiele</span>
    </button>

    <button class="pixel-tab" :class="{ active: modelValue === 'ranking' }" @click="$emit('update:modelValue','ranking')">
      <img class="nav-icon-img" :src="icons.ranking" alt="" />
      <span>Rangliste</span>
    </button>

    <button class="pixel-tab" :class="{ active: modelValue === 'profile' }" @click="$emit('update:modelValue','profile')">
      <img class="nav-icon-img" :src="icons.profile" alt="" />
      <span>Profil</span>
    </button>

    <button class="pixel-tab" :class="{ active: modelValue === 'admin' }" @click="$emit('update:modelValue','admin')">
      <img class="nav-icon-img" :src="icons.admin" alt="" />
      <span>Admin</span>
    </button>
  </nav>
</template>

<script setup>
defineProps({ modelValue: String, statusText: String })
defineEmits(['update:modelValue','refresh'])

const base = import.meta.env.BASE_URL

const desktopHeader = `${base}fun-cup-header-desktop.png`
const mobileHeader = `${base}fun-cup-header-mobile.png`

const icons = {
  home: `${base}nav-icons/home.png`,
  games: `${base}nav-icons/games.png`,
  ranking: `${base}nav-icons/ranking.png`,
  profile: `${base}icons/admin-key.png`,
  admin: `${base}icons/admin-key.png`,
}
</script>
