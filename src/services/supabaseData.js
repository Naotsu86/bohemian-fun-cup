import { supabase } from '../api/supabase'
import { recalcForm } from './generator'
export async function loadAll() {
  const [p,m,s] = await Promise.all([
    supabase.from('players').select('*').order('created_at', { ascending:true }),
    supabase.from('matches').select('*').order('created_at', { ascending:true }),
    supabase.from('settings').select('*').eq('id','main').maybeSingle(),
  ])
  if (p.error) throw p.error; if (m.error) throw m.error; if (s.error) throw s.error
  return { players:p.data || [], matches:m.data || [], settings:s.data?.value || {} }
}
export async function addPlayer(row){ const {error}=await supabase.from('players').insert({name:row.name,strength:row.strength,form:0,active:true}); if(error) throw error }
export async function updatePlayer(id, patch){ const {error}=await supabase.from('players').update(patch).eq('id',id); if(error) throw error }
export async function deletePlayer(id){ const {error}=await supabase.from('players').delete().eq('id',id); if(error) throw error }
export async function insertMatch(row){ const {error}=await supabase.from('matches').insert(row); if(error) throw error }
export async function updateMatch(id, patch){ const {error}=await supabase.from('matches').update(patch).eq('id',id); if(error) throw error }
export async function deleteMatch(id){ const {error}=await supabase.from('matches').delete().eq('id',id); if(error) throw error }
export async function updateSettings(value){ const {error}=await supabase.from('settings').upsert({id:'main',value}); if(error) throw error }
export async function updateForms(players, matches) {
  const form = recalcForm(players, matches)
  await Promise.all(players.map(p => supabase.from('players').update({ form: form[p.id] || 0 }).eq('id', p.id)))
}
