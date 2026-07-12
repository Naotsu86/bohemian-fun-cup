import { supabase } from '../api/supabase'
import { recalcForm } from './generator'
export async function loadAll() {
  const [p,m,s,pp] = await Promise.all([
    supabase.from('players').select('*').order('created_at', { ascending:true }),
    supabase.from('matches').select('*').order('created_at', { ascending:true }),
    supabase.from('settings').select('*').eq('id','main').maybeSingle(),
    supabase.from('player_profiles').select('player_id,body_color,belly_color,avatar_body,avatar_belly,head_item,shorts_item,accessory_item'),
  ])
  if (p.error) throw p.error; if (m.error) throw m.error; if (s.error) throw s.error
  if (pp.error) console.warn('player_profiles konnte nicht geladen werden:', pp.error.message)

  const profileByPlayerId = Object.fromEntries((pp.data || []).map(row => [row.player_id, row]))
  const players = (p.data || []).map(player => {
    const profile = profileByPlayerId[player.id]
    if (!profile) return player
    return {
      ...player,
      body_color: profile.body_color || profile.avatar_body,
      belly_color: profile.belly_color || profile.avatar_belly,
      head_item: profile.head_item,
      shorts_item: profile.shorts_item,
      accessory_item: profile.accessory_item
    }
  })

  return { players, matches:m.data || [], settings:s.data?.value || {} }
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
