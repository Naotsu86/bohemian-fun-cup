<template>
  <div class="card pixel-card menu-window">
    <h2>🔐 Spieler anmelden</h2>

    <div class="menu-body">
      <div class="field">
        <label>E-Mail</label>
        <input v-model="email" type="email" placeholder="name@example.de" autocomplete="email" />
      </div>

      <div class="field">
        <label>Passwort</label>
        <input v-model="password" type="password" placeholder="Passwort" autocomplete="current-password" />
      </div>

      <button class="btn primary full" @click="submit" :disabled="loading">
        {{ loading ? 'Anmelden...' : 'Anmelden' }}
      </button>

      <p v-if="error" class="error-small">{{ error }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { signIn } from '../../services/authV2'

const emit = defineEmits(['logged-in'])

const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

async function submit() {
  error.value = ''

  if (!email.value || !password.value) {
    error.value = 'Bitte E-Mail und Passwort eingeben.'
    return
  }

  loading.value = true

  try {
    await signIn(email.value.trim(), password.value)
    emit('logged-in')
  } catch (e) {
    error.value = e.message || 'Anmeldung fehlgeschlagen.'
  } finally {
    loading.value = false
  }
}
</script>
