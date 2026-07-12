<template>
  <section class="screen">
    <PlayerRegisterPanel
      v-if="mode === 'register' && !user"
      @show-login="mode = 'login'"
      @registered="mode = 'login'"
    />

    <PlayerLoginPanel
      v-else-if="!user"
      @logged-in="loadProfile"
    />

    <div v-else class="card pixel-card menu-window">
      <h2>👤 Mein Profil</h2>

      <div class="menu-body">
        <p><strong>E-Mail:</strong><br>{{ user.email }}</p>

        <template v-if="loadingProfile">
          <p class="muted">Profil wird geladen...</p>
        </template>

        <template v-else-if="profile">
          <p>
            <strong>Status:</strong><br>
            <span v-if="profile.players?.approved">Freigegeben</span>
            <span v-else>Wartet auf Admin-Freigabe</span>
          </p>

          <AvatarEditor
            v-if="profile.players?.approved"
            :profile="profile"
            :saving="saving"
            :message="saveMessage"
            :error="saveError"
            @save="saveProfile"
          />

          <template v-else>
            <p><strong>Name:</strong><br>{{ profile.players?.name || profile.display_name }}</p>
            <p class="muted">Profilbearbeitung ist erst nach Admin-Freigabe möglich.</p>
          </template>
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

    <div v-if="!user && mode === 'login'" class="card pixel-card menu-window">
      <div class="menu-body">
        <button class="btn full" @click="mode = 'register'">
          Noch kein Konto? Registrieren
        </button>
      </div>
    </div>
  </section>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import PlayerLoginPanel from '../components/auth/PlayerLoginPanel.vue'
import PlayerRegisterPanel from '../components/auth/PlayerRegisterPanel.vue'
import AvatarEditor from '../components/avatar/AvatarEditor.vue'
import { getCurrentUser, signOut } from '../services/authV2'
import { allocateMyStatPoints, getMyProfile, updateMyAvatar } from '../services/playerProfileService'

const emit = defineEmits(['auth-changed'])

const mode = ref('login')
const user = ref(null)
const profile = ref(null)
const loadingProfile = ref(false)
const message = ref('')
const saving = ref(false)
const saveMessage = ref('')
const saveError = ref('')

onMounted(loadProfile)

async function loadProfile() {
  message.value = ''

  try {
    user.value = await getCurrentUser()

    if (!user.value) return

    loadingProfile.value = true
    profile.value = await getMyProfile()
    emit('auth-changed')
  } catch (error) {
    message.value = error.message || 'Profil konnte nicht geladen werden.'
  } finally {
    loadingProfile.value = false
  }
}

async function saveProfile(payload) {
  if (!profile.value) return

  saving.value = true
  saveMessage.value = ''
  saveError.value = ''

  try {
    await updateMyAvatar(profile.value.id, payload.profileChoices)

    const points = payload.statPoints || {}
    const spend =
      Number(points.teamgeist || 0) +
      Number(points.geschwindigkeit || 0) +
      Number(points.kraft || 0) +
      Number(points.technik || 0) +
      Number(points.ehrgeiz || 0)

    if (spend > 0) {
      await allocateMyStatPoints(points)
    }

    profile.value = await getMyProfile()
    saveMessage.value = 'Profil gespeichert.'
  } catch (e) {
    saveError.value = e.message || 'Profil konnte nicht gespeichert werden.'
  } finally {
    saving.value = false
  }
}

async function logoutUser() {
  await signOut()
  user.value = null
  profile.value = null
  message.value = 'Abgemeldet.'
  emit('auth-changed')
}
</script>
