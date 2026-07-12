<template>
  <section class="screen admin-screen">
    <AdminLogin v-if="!adminUnlocked" @login="$emit('login', $event)" />
    <template v-else>
      <div class="card pixel-card menu-window">
        <h2><span class="headline-icon">🔧</span> Adminbereich</h2>
        <div class="menu-body session-card"><p class="muted">Angemeldet als {{ userEmail }}</p><button class="btn danger" @click="$emit('logout')">Abmelden</button></div>
      </div>
      <div v-if="activePanel === 'menu'" class="admin-tile-grid">
        <button class="admin-tile pixel-card" @click="activePanel = 'players'"><span class="tile-icon">👥</span><strong>Spielerverwaltung</strong><small>Freigeben, anlegen und Spielerliste bearbeiten</small><em v-if="pendingPlayers.length">{{ pendingPlayers.length }} wartet</em></button>
        <button class="admin-tile pixel-card" @click="activePanel = 'games'"><span class="tile-icon">🏐</span><strong>Spiele</strong><small>Neue Spiele erzeugen und Ergebnisse eintragen</small></button>
        <button class="admin-tile pixel-card" @click="activePanel = 'catalog'"><span class="tile-icon">🏷️</span><strong>Titel / Special</strong><small>Titel, Bedingungen und Spezialattacken pflegen</small></button>
      </div>
      <template v-else>
        <button class="btn full back-btn" @click="activePanel = 'menu'">← Zurück zur Admin-Übersicht</button>
        <template v-if="activePanel === 'players'">
          <div class="card pixel-card menu-window"><h2>🕘 Wartende Spieler</h2><div class="menu-body"><button class="btn full" @click="$emit('refresh')">Aktualisieren</button><p v-if="pendingPlayers.length === 0" class="muted">Aktuell wartet kein Spieler auf Freigabe.</p><div class="pending-list"><div v-for="p in pendingPlayers" :key="p.id" class="pending-row"><div><strong>{{ p.name }}</strong><div class="muted small">{{ p.email || '-' }}</div><div class="muted small">Status: wartet auf Freigabe</div></div><button class="btn primary" :disabled="approvingId === p.id" @click="approve(p.id)">{{ approvingId === p.id ? 'WIRD FREIGEGEBEN...' : 'FREIGEBEN' }}</button></div></div><p v-if="message" class="hint">{{ message }}</p></div></div>
          <div class="card pixel-card menu-window"><h2>Spieler manuell anlegen</h2><div class="menu-body"><p class="muted">Normalerweise registrieren sich Spieler selbst. Hier kannst du bei Bedarf trotzdem Spieler ohne Login anlegen.</p><div class="row"><div class="field"><label>Name</label><input v-model="newName" placeholder="z. B. Alex"></div><div class="field"><label>Stärke 1-12</label><select v-model.number="newStrength"><option v-for="n in 12" :key="n" :value="n">{{ n }}</option></select></div></div><button class="btn primary full" @click="add">Spieler hinzufügen</button></div></div>
          <div class="card pixel-card menu-window"><h2>Spielerliste</h2><div class="menu-body"><p v-if="players.length===0" class="muted">Noch keine Spieler angelegt.</p><div class="admin-player-list"><div v-for="p in players" :key="p.id" class="player playerrow"><div><label>Name</label><input :value="p.name" @change="$emit('update-player', p.id, { name: $event.target.value })"><div class="muted small" v-if="p.email">{{ p.email }}</div><div class="muted small">Status: {{ p.approved ? 'Freigegeben' : 'Wartet' }}</div></div><div><label>Stärke</label><select :value="p.strength" @change="$emit('update-player', p.id, { strength: Number($event.target.value) })"><option v-for="n in 12" :key="n" :value="n">{{ n }}</option></select><div class="muted small">Form: {{ Number(p.form||0).toFixed(2) }}</div></div><div class="player-actions"><button class="btn" :class="{ inactive:p.active===false }" @click="$emit('update-player', p.id, { active: p.active === false })">{{ p.active===false?'Inaktiv':'Aktiv' }}</button><button v-if="!p.approved" class="btn primary" :disabled="approvingId === p.id" @click="approve(p.id)">{{ approvingId === p.id ? 'WIRD FREIGEGEBEN...' : 'FREIGEBEN' }}</button><button class="btn danger" @click="$emit('delete-player', p.id)">Löschen</button></div></div></div></div></div>
        </template>
        <template v-if="activePanel === 'games'">
          <div class="card pixel-card menu-window"><h2>Nächstes Spiel</h2><div class="menu-body"><p class="muted">Immer nur ein neues Spiel. So werden aktive Spieler und Turnierform berücksichtigt.</p><div class="field"><label>Modus</label><select v-model="mode"><option value="2v2">2 gegen 2</option><option value="2v3">2 gegen 3</option><option value="3v3">3 gegen 3</option><option value="3v4">3 gegen 4</option><option value="4v4">4 gegen 4</option></select></div><button class="btn primary full" @click="$emit('create-match', mode)">Spiel erzeugen</button><p v-if="message" class="hint">{{ message }}</p></div></div>
          <div class="card pixel-card menu-window"><h2>Ergebnisse eintragen</h2><div class="menu-body"><p v-if="matches.length===0" class="muted">Noch keine Spiele angelegt.</p><MatchCard v-for="m in matches" :key="m.id" :match="m" :number="matchNumber(m)" :editable="true" :name-of="nameOf" @delete="$emit('delete-match',$event)" @score="$emit('score',$event)" /></div></div>
        </template>
        <AdminRpgCatalogManager v-if="activePanel === 'catalog'" />
      </template>
    </template>
  </section>
</template>
<script setup>
import { computed, ref } from 'vue'
import AdminLogin from '../components/AdminLogin.vue'
import MatchCard from '../components/MatchCard.vue'
import AdminRpgCatalogManager from '../components/admin/AdminRpgCatalogManager.vue'
const props = defineProps({ adminUnlocked:Boolean, userEmail:String, players:{ type:Array, default:() => [] }, matches:{ type:Array, default:() => [] }, rules:String, message:String, matchNumber:Function, nameOf:Function })
const emit = defineEmits(['login','logout','refresh','approve-player','add-player','update-player','delete-player','create-match','delete-match','score','update-rules'])
const activePanel = ref('menu'), newName = ref(''), newStrength = ref(6), mode = ref('4v4'), approvingId = ref(null)
const pendingPlayers = computed(() => (props.players || []).filter(p => p.approved === false || p.approved === null || p.approved === undefined))
function add(){ const name = newName.value.trim(); if(!name) return; emit('add-player',{ name, strength:Number(newStrength.value) }); newName.value=''; newStrength.value=6 }

function approve(playerId) {
  approvingId.value = playerId
  emit('approve-player', playerId)

  // Die Liste wird danach vom App-Refresh aktualisiert.
  // Sicherheits-Timeout, damit der Button bei einem Fehler wieder bedienbar wird.
  window.setTimeout(() => {
    approvingId.value = null
  }, 2500)
}
</script>
<style scoped>
.admin-tile-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px}.admin-tile{border:4px solid #2b2115;background:#fff4d2;padding:18px;text-align:left;cursor:pointer;box-shadow:5px 5px 0 rgba(0,0,0,.22);min-height:170px;display:flex;flex-direction:column;gap:8px}.admin-tile:hover{transform:translate(-1px,-1px)}.tile-icon{font-size:34px}.admin-tile strong{font-family:var(--font-pixel,'Silkscreen',monospace);letter-spacing:2px;font-size:18px}.admin-tile small{color:#5f6f86;font-size:14px}.admin-tile em{margin-top:auto;display:inline-block;color:#991b1b;font-weight:900;font-style:normal}.back-btn{margin-bottom:12px}.pending-list{display:grid;gap:10px;margin-top:12px}.pending-row{border:3px solid #c5a66f;background:#fffdf6;padding:10px;display:flex;justify-content:space-between;gap:12px;align-items:center}@media(max-width:850px){.admin-tile-grid{grid-template-columns:1fr}.admin-tile{min-height:130px}.pending-row{align-items:stretch;flex-direction:column}}
</style>
