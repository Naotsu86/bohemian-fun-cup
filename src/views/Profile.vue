<template>
  <section class="screen">
    <PlayerLoginPanel v-if="!profile" @logged-in="loadProfile" />

    <div v-else class="card pixel-card menu-window">
      <h2>👤 Spielerprofil</h2>

      <div class="menu-body">
        <p><strong>{{ profile.display_name || profile.players?.name }}</strong></p>

        <div class="field">
          <label>Körperfarbe</label>
          <select v-model="draft.avatar_body">
            <option value="black">Schwarz</option>
            <option value="gray">Grau</option>
            <option value="blue">Blau</option>
            <option value="purple">Lila</option>
          </select>
        </div>

        <div class="field">
          <label>Bauchfarbe</label>
          <select v-model="draft.avatar_belly">
            <option value="white">Weiß</option>
            <option value="cream">Creme</option>
            <option value="pink">Rosa</option>
            <option value="mint">Mint</option>
          </select>
        </div>

        <div class="field">
          <label>Bio</label>
          <textarea v-model="draft.bio" rows="3" placeholder="Kurzer Text zu deinem Pinguin"></textarea>
        </div>

        <button class="btn primary full" @click="save" :disabled="saving">
          {{ saving ? 'Speichern...' : 'Avatar speichern' }}
        </button>

        <button class="btn full" @click="logout">
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
import { getMyProfile, updateMyAvatar } from '../services/playerProfileService'
import { signOut } from '../services/authV2'

const profile = ref(null)
const draft = ref({})
const saving = ref(false)
const message = ref('')

onMounted(loadProfile)

async function loadProfile() {
  try {
    profile.value = await getMyProfile()
    if (profile.value) {
      draft.value = {
        avatar_body: profile.value.avatar_body,
        avatar_belly: profile.value.avatar_belly,
        head_item: profile.value.head_item,
        face_item: profile.value.face_item,
        body_item: profile.value.body_item,
        back_item: profile.value.back_item,
        bio: profile.value.bio || ''
      }
    }
  } catch (e) {
    console.warn(e)
  }
}

async function save() {
  if (!profile.value) return

  saving.value = true
  message.value = ''

  try {
    profile.value = await updateMyAvatar(profile.value.id, draft.value)
    message.value = 'Gespeichert.'
  } catch (e) {
    message.value = e.message || 'Speichern fehlgeschlagen.'
  } finally {
    saving.value = false
  }
}

async function logout() {
  await signOut()
  profile.value = null
  draft.value = {}
}
</script>
