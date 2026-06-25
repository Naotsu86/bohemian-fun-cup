<template>
  <AppHeader v-model="tab" :status-text="statusText" @refresh="loadData" />
  <main class="wrap">
    <p v-if="errorMessage" class="error-box">{{ errorMessage }}</p>
    <Overview v-if="tab==='overview'" :ranking="ranking" :open-matches="openMatches" :rules="rules" :match-number="matchNumber" :name-of="nameOf" />
    <Games v-if="tab==='games'" :matches="matches" :match-number="matchNumber" :name-of="nameOf" />
    <Ranking v-if="tab==='ranking'" :ranking="ranking" />
    <Admin v-if="tab==='admin'" :admin-unlocked="adminUnlocked" :players="players" :matches="matches" :rules="rules" :message="adminMessage" :match-number="matchNumber" :name-of="nameOf" @login="login" @logout="logout" @add-player="handleAddPlayer" @update-player="handleUpdatePlayer" @delete-player="handleDeletePlayer" @create-match="handleCreateMatch" @delete-match="handleDeleteMatch" @score="handleScore" @update-rules="handleUpdateRules" />
  </main>
</template>
<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { supabase } from './api/supabase'
import AppHeader from './components/AppHeader.vue'
import Overview from './views/Overview.vue'
import Games from './views/Games.vue'
import Ranking from './views/Ranking.vue'
import Admin from './views/Admin.vue'
import { buildRanking, getOpenMatches } from './services/ranking'
import { createNextMatch } from './services/generator'
import { addPlayer, deleteMatch, deletePlayer, insertMatch, loadAll, updateForms, updateMatch, updatePlayer, updateSettings } from './services/supabaseData'
const tab=ref('overview'), adminUnlocked=ref(sessionStorage.getItem('bfc-admin')==='1'), players=ref([]), matches=ref([]), settings=ref({}), loading=ref(false), errorMessage=ref(''), adminMessage=ref('')
let channel=null, timer=null
const ranking=computed(()=>buildRanking(players.value,matches.value))
const openMatches=computed(()=>getOpenMatches(matches.value))
const rules=computed(()=>settings.value.rules || 'Noch keine Regeln eingetragen.')
const statusText=computed(()=>loading.value?'lädt...':'live')
onMounted(async()=>{await loadData(); subscribeRealtime(); timer=setInterval(loadData,5000)})
onUnmounted(()=>{if(channel)supabase.removeChannel(channel); if(timer)clearInterval(timer)})
async function run(action){errorMessage.value='';try{await action()}catch(e){errorMessage.value=e.message||'Es ist ein Fehler aufgetreten.'}}
async function loadData(){loading.value=true;try{const d=await loadAll();players.value=d.players;matches.value=d.matches;settings.value=d.settings}catch(e){errorMessage.value=e.message||'Daten konnten nicht geladen werden.'}finally{loading.value=false}}
function subscribeRealtime(){channel=supabase.channel('bohemian-fun-cup-live').on('postgres_changes',{event:'*',schema:'public',table:'players'},loadData).on('postgres_changes',{event:'*',schema:'public',table:'matches'},loadData).on('postgres_changes',{event:'*',schema:'public',table:'settings'},loadData).subscribe()}
function login(){const pin=prompt('Admin-PIN eingeben'); if(pin===String(settings.value.adminPin||'2026')){adminUnlocked.value=true;sessionStorage.setItem('bfc-admin','1')}else alert('PIN ist falsch.')}
function logout(){adminUnlocked.value=false;sessionStorage.removeItem('bfc-admin');tab.value='overview'}
function nameOf(id){return players.value.find(p=>p.id===id)?.name||'?'}
function matchNumber(match){return matches.value.findIndex(m=>m.id===match.id)+1}
async function handleAddPlayer(payload){await run(async()=>{await addPlayer(payload); await loadData()})}
async function handleUpdatePlayer(id,patch){await run(async()=>{await updatePlayer(id,patch); await loadData()})}
async function handleDeletePlayer(id){if(!confirm('Spieler wirklich löschen? Alte Spiele mit diesem Spieler werden danach unvollständig angezeigt. Besser ist meistens: Spieler auf inaktiv setzen.'))return; await run(async()=>{await deletePlayer(id); await loadData()})}
async function handleCreateMatch(mode){await run(async()=>{const match=createNextMatch({players:players.value,matches:matches.value,mode}); await insertMatch(match); adminMessage.value='Nächstes Spiel wurde erzeugt.'; await loadData()})}
async function handleDeleteMatch(id){await run(async()=>{await deleteMatch(id); await loadData(); await updateForms(players.value,matches.value); await loadData()})}
async function handleScore({id,side,value}){await run(async()=>{await updateMatch(id,{[side]:value}); await loadData(); await updateForms(players.value,matches.value); await loadData()})}
async function handleUpdateRules(rules){await run(async()=>{await updateSettings({...settings.value,rules}); await loadData()})}
</script>
