<template>
  <div class="card pixel-card menu-window">
    <h2>📝 Registrieren</h2>

    <div class="menu-body">
      <p class="muted">
        Registriere dich mit deiner E-Mail. Danach muss ein Admin dich freigeben.
      </p>

      <div class="field">
        <label>Vorname</label>
        <input v-model="name" type="text" placeholder="Alex" autocomplete="given-name" />
      </div>

      <div class="field">
        <label>E-Mail</label>
        <input v-model="email" type="email" placeholder="name@example.de" autocomplete="email" />
      </div>

      <div class="field">
        <label>Passwort</label>
        <input v-model="password" type="password" placeholder="Mindestens 6 Zeichen" autocomplete="new-password" />
      </div>

      <button class="btn primary full" @click="submit" :disabled="loading">
        {{ loading ? 'Registrieren...' : 'Registrieren' }}
      </button>

      <button class="btn full" @click="$emit('show-login')">
        Zur Anmeldung
      </button>

      <p v-if="message" class="muted">{{ message }}</p>
      <p v-if="error" class="error-small">{{ error }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { registerPlayer } from '../../services/registerService'

const emit = defineEmits(['registered', 'show-login'])

const name = ref('')
const akaName = ref('')
const email = ref('')
const password = ref('')
const loading = ref(false)
const message = ref('')
const error = ref('')

async function submit() {
  error.value = ''
  message.value = ''
  loading.value = true

  try {
    await registerPlayer({
      email: email.value,
      password: password.value,
      name: name.value,
      akaName: akaName.value
    })

    message.value = 'Registrierung angelegt. Bitte bestätige ggf. deine E-Mail. Danach muss ein Admin dich freigeben.'
    emit('registered')
  } catch (e) {
    error.value = e.message || 'Registrierung fehlgeschlagen.'
  } finally {
    loading.value = false
  }
}
</script>
