import { supabase } from '../api/supabase'
import { calculateForm } from './generator'
export async function loadAll(){const[players,matches,settings]=await Promise.all([supabase.from('players').select('*').order('created_at',{ascending:true}),supabase.from('matches').select('*').order('created_at',{ascending:true}),supabase.from('settings').select('*').eq('id','main').maybeSingle()]);if(players.error)throw players.error;if(matches.error)throw matches.error;if(settings.error)throw settings.error;return{players:players.data||[],matches:matches.data||[],settings:settings.data?.value||{rules:'',adminPin:'2026'}}}
export async function addPlayer(player){const{error}=await supabase.from('players').insert({name:player.name,strength:player.strength,form:0,active:true});if(error)throw error}
export async function updatePlayer(id,patch){const{error}=await supabase.from('players').update(patch).eq('id',id);if(error)throw error}
export async function deletePlayer(id){const{error}=await supabase.from('players').delete().eq('id',id);if(error)throw error}
export async function insertMatch(match){const{error}=await supabase.from('matches').insert(match);if(error)throw error}
export async function updateMatch(id,patch){const{error}=await supabase.from('matches').update(patch).eq('id',id);if(error)throw error}
export async function deleteMatch(id){const{error}=await supabase.from('matches').delete().eq('id',id);if(error)throw error}
export async function updateSettings(settings){const{error}=await supabase.from('settings').upsert({id:'main',value:settings});if(error)throw error}
export async function updateForms(players,matches){const form=calculateForm(players,matches);await Promise.all(players.map(p=>supabase.from('players').update({form:form[p.id]||0}).eq('id',p.id)))}
