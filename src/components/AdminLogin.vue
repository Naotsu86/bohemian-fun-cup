<template>
  <div class="card pixel-card menu-window">
    <h2><span class="headline-icon">🔐</span> Admin anmelden</h2>
    <div class="menu-body">
      <p class="muted">Nur angemeldete Admins dürfen Spieler, Spiele und Ergebnisse ändern.</p>
      <div class="field"><label>E-Mail</label><input v-model="email" type="email" placeholder="name@example.de" autocomplete="email" /></div>
      <div class="field"><label>Passwort</label><input v-model="password" type="password" placeholder="Passwort" autocomplete="current-password" @keydown.enter="submit" /></div>
      <button class="btn primary full" :disabled="loading" @click="submit">{{ loading ? 'Melde an...' : 'Anmelden' }}</button>
      <p v-if="error" class="error-small">{{ error }}</p>
    </div>
  </div>
</template>
<script setup>
import { ref } from 'vue'
const emit = defineEmits(['login'])
const email = ref(''), password = ref(''), loading = ref(false), error = ref('')
async function submit(){ error.value=''; if(!email.value||!password.value){ error.value='Bitte E-Mail und Passwort eingeben.'; return } loading.value=true; try{ await emit('login',{email:email.value.trim(),password:password.value}) }catch(e){ error.value=e.message||'Anmeldung fehlgeschlagen.' }finally{ loading.value=false } }
</script>
