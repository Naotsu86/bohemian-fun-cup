<template>
<section class="screen admin-screen">
  <AdminLogin v-if="!adminUnlocked" @login="$emit('login', $event)" />
  <template v-else>
    <div class="card pixel-card menu-window"><h2><span class="headline-icon">🔧</span> Adminbereich</h2><div class="menu-body session-card"><div><p class="muted">Angemeldet als {{ userEmail }}</p></div><button class="btn danger" @click="$emit('logout')">Abmelden</button></div></div>
    <div class="grid"><div class="card pixel-card menu-window"><h2>Spieler eintragen</h2><div class="menu-body"><div class="row"><div class="field"><label>Name</label><input v-model="newName" placeholder="z. B. Alex"></div><div class="field"><label>Stärke 1-12</label><select v-model.number="newStrength"><option v-for="n in 12" :key="n" :value="n">{{ n }}</option></select></div></div><button class="btn primary full" @click="add">Spieler hinzufügen</button></div></div><div class="card pixel-card menu-window"><h2>Nächstes Spiel</h2><div class="menu-body"><p class="muted">Immer nur ein neues Spiel. So werden aktive Spieler und Turnierform berücksichtigt.</p><div class="field"><label>Modus</label><select v-model="mode"><option value="2v2">2 gegen 2</option><option value="2v3">2 gegen 3</option><option value="3v3">3 gegen 3</option><option value="3v4">3 gegen 4</option><option value="4v4">4 gegen 4</option></select></div><button class="btn primary full" @click="$emit('create-match', mode)">Spiel erzeugen</button><p v-if="message" class="hint">{{ message }}</p></div></div></div>
    <div class="card pixel-card menu-window"><h2>Spielerliste</h2><div class="menu-body"><p v-if="players.length===0" class="muted">Noch keine Spieler angelegt.</p><div class="admin-player-list"><div v-for="p in players" :key="p.id" class="player playerrow"><div><label>Name</label><input :value="p.name" @change="$emit('update-player', p.id, { name: $event.target.value })"></div><div><label>Stärke</label><select :value="p.strength" @change="$emit('update-player', p.id, { strength: Number($event.target.value) })"><option v-for="n in 12" :key="n" :value="n">{{ n }}</option></select><div class="muted small">Form: {{ Number(p.form||0).toFixed(2) }}</div></div><div class="player-actions"><button class="btn" :class="{ inactive:p.active===false }" @click="$emit('update-player', p.id, { active: p.active === false })">{{ p.active===false?'Inaktiv':'Aktiv' }}</button><button class="btn danger" @click="$emit('delete-player', p.id)">Löschen</button></div></div></div></div></div>
    <div class="card pixel-card menu-window"><h2>Ergebnisse eintragen</h2><div class="menu-body"><p v-if="matches.length===0" class="muted">Noch keine Spiele angelegt.</p><MatchCard v-for="m in matches" :key="m.id" :match="m" :number="matchNumber(m)" :editable="true" :name-of="nameOf" @delete="$emit('delete-match',$event)" @score="$emit('score',$event)" /></div></div>
    <div class="card pixel-card menu-window"><h2>Regeltext</h2><div class="menu-body"><textarea :value="rules" @change="$emit('update-rules', $event.target.value)"></textarea></div></div>
  </template>
</section>
</template>
<script setup>
import { ref } from 'vue'
import AdminLogin from '../components/AdminLogin.vue'
import MatchCard from '../components/MatchCard.vue'
defineProps({ adminUnlocked:Boolean, userEmail:String, players:Array, matches:Array, rules:String, message:String, matchNumber:Function, nameOf:Function })
const emit = defineEmits(['login','logout','add-player','update-player','delete-player','create-match','delete-match','score','update-rules'])
const newName=ref(''), newStrength=ref(6), mode=ref('4v4')
function add(){ const name=newName.value.trim(); if(!name)return; emit('add-player',{name,strength:Number(newStrength.value)}); newName.value=''; newStrength.value=6 }
</script>
