<template>
  <AppHeader v-model="tab" :status-text="statusText" @refresh="loadData" />
  <main class="wrap">
    <p v-if="error" class="error-box">{{ error }}</p>
    <Overview v-if="tab==='overview'" :ranking="ranking" :open-matches="openMatches" :rules="rules" :match-number="matchNumber" :name-of="nameOf" />
    <Games v-if="tab==='games'" :matches="matches" :match-number="matchNumber" :name-of="nameOf" />
    <Ranking v-if="tab==='ranking'" :ranking="ranking" />
    <Admin v-if="tab==='admin'" :admin-unlocked="adminUnlocked" :user-email="userEmail" :players="players" :matches="matches" :rules="rules" :message="message" :match-number="matchNumber" :name-of="nameOf" @login="handleLogin" @logout="handleLogout" @add-player="handleAddPlayer" @update-player="handleUpdatePlayer" @delete-player="handleDeletePlayer" @create-match="handleCreateMatch" @delete-match="handleDeleteMatch" @score="handleScore" @update-rules="handleRules" />
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
import { getSession, loginWithPassword, logout } from './services/auth'
import { buildRanking, getOpenMatches } from './services/ranking'
import { createNextMatch } from './services/generator'
import { addPlayer, deleteMatch, deletePlayer, insertMatch, loadAll, updateForms, updateMatch, updatePlayer, updateSettings } from './services/data'

const tab=ref('overview'), session=ref(null), players=ref([]), matches=ref([]), settings=ref({}), loading=ref(false), error=ref(''), message=ref('')
let channel=null, timer=null
const adminUnlocked=computed(()=>!!session.value)
const userEmail=computed(()=>session.value?.user?.email || '')
const ranking=computed(()=>buildRanking(players.value,matches.value))
const openMatches=computed(()=>getOpenMatches(matches.value))
const rules=computed(()=>settings.value.rules || 'Noch keine Regeln eingetragen.')
const statusText=computed(()=>loading.value?'lädt...':'live')

onMounted(async()=>{ await loadSession(); await loadData(); subscribe(); timer=setInterval(loadData,5000); supabase.auth.onAuthStateChange((_event,newSession)=>{ session.value=newSession }) })
onUnmounted(()=>{ if(channel) supabase.removeChannel(channel); if(timer) clearInterval(timer) })

async function run(fn){ error.value=''; try{ await fn() }catch(e){ error.value=e.message || 'Fehler' } }
async function loadSession(){ await run(async()=>{ session.value=await getSession() }) }
async function loadData(){ loading.value=true; try{ const d=await loadAll(); players.value=d.players; matches.value=d.matches; settings.value=d.settings }catch(e){ error.value=e.message || 'Daten konnten nicht geladen werden.' }finally{ loading.value=false } }
function subscribe(){ channel=supabase.channel('bfc-live').on('postgres_changes',{event:'*',schema:'public',table:'players'},loadData).on('postgres_changes',{event:'*',schema:'public',table:'matches'},loadData).on('postgres_changes',{event:'*',schema:'public',table:'settings'},loadData).subscribe() }
async function handleLogin({email,password}){ await run(async()=>{ session.value=await loginWithPassword(email,password); await loadData() }) }
async function handleLogout(){ await run(async()=>{ await logout(); session.value=null; tab.value='overview' }) }
function nameOf(id){ return players.value.find(p=>p.id===id)?.name || '?' }
function matchNumber(m){ return matches.value.findIndex(x=>x.id===m.id)+1 }
async function handleAddPlayer(p){ await run(async()=>{ await addPlayer(p); await loadData() }) }
async function handleUpdatePlayer(id,patch){ await run(async()=>{ await updatePlayer(id,patch); await loadData() }) }
async function handleDeletePlayer(id){ if(!confirm('Besser ist meistens: Spieler auf inaktiv setzen. Trotzdem löschen?'))return; await run(async()=>{ await deletePlayer(id); await loadData() }) }
async function handleCreateMatch(mode){ await run(async()=>{ const m=createNextMatch(players.value,matches.value,mode); await insertMatch(m); message.value='Nächstes Spiel wurde erzeugt.'; await loadData() }) }
async function handleDeleteMatch(id){ await run(async()=>{ await deleteMatch(id); await loadData(); await updateForms(players.value,matches.value); await loadData() }) }
async function handleScore({id,side,value}){ await run(async()=>{ await updateMatch(id,{[side]:value}); await loadData(); await updateForms(players.value,matches.value); await loadData() }) }
async function handleRules(rules){ await run(async()=>{ await updateSettings({...settings.value,rules}); await loadData() }) }
</script>
