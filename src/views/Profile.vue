<template>
  <section class="screen">
    <PlayerLoginPanel v-if="!user" @logged-in="loadProfile" />

    <div v-else class="card pixel-card menu-window">
      <h2>👤 Mein Profil</h2>

      <div class="menu-body">
        <p><strong>E-Mail:</strong><br>{{ user.email }}</p>

        <template v-if="loadingProfile">
          <p class="muted">Profil wird geladen...</p>
        </template>

        <template v-else-if="profile">
          <p><strong>Status:</strong><br>Spieler</p>
          <p><strong>Spielername:</strong><br>{{ profile.display_name || profile.players?.name || 'Noch nicht gesetzt' }}</p>

          <div class="profile-preview">
            <div class="penguin-placeholder">🐧</div>
            <div>
              <p><strong>Avatar</strong></p>
              <p class="muted">
                Körper: {{ profile.avatar_body }}<br>
                Bauch: {{ profile.avatar_belly }}
              </p>
            </div>
          </div>

          <button class="btn primary full" disabled>
            Avatar bearbeiten kommt als Nächstes
          </button>
        </template>

        <template v-else>
          <p class="error-small">
            Für diesen Login wurde noch kein Spielerprofil gefunden.
          </p>
        </template>

        <button class="btn full" @click="logoutUser">
          Abmelden
        </button>

        <p v-if="message" class="muted">{{ message }}</p>
      </div>
    </div>
  </section>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import PlayerLoginPanel from '../components/auth/PlayerLoginPanel.vue'
import { getCurrentUser, signOut } from '../services/authV2'
import { getMyProfile } from '../services/playerProfileService'

const user = ref(null)
const profile = ref(null)
const loadingProfile = ref(false)
const message = ref('')

onMounted(loadProfile)

async function loadProfile() {
  message.value = ''

  try {
    user.value = await getCurrentUser()

    if (!user.value) return

    loadingProfile.value = true
    profile.value = await getMyProfile()
  } catch (error) {
    message.value = error.message || 'Profil konnte nicht geladen werden.'
  } finally {
    loadingProfile.value = false
  }
}

async function logoutUser() {
  await signOut()
  user.value = null
  profile.value = null
  message.value = 'Abgemeldet.'
}
</script>
