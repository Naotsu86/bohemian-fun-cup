import { supabase } from '../api/supabase'

export async function loadRpgCatalogs() {
  const [titles, specials] = await Promise.all([
    supabase.rpc('admin_get_player_titles'),
    supabase.rpc('admin_get_special_attacks')
  ])
  if (titles.error) throw titles.error
  if (specials.error) throw specials.error
  return { titles: titles.data || [], specials: specials.data || [] }
}

export async function saveTitle(row) {
  const { error } = await supabase.rpc('admin_save_player_title', {
    p_id: row.id || null,
    p_name: row.name,
    p_description: row.description || '',
    p_min_level: Number(row.min_level || 1),
    p_req_teamgeist: Number(row.req_teamgeist || 0),
    p_req_geschwindigkeit: Number(row.req_geschwindigkeit || 0),
    p_req_kraft: Number(row.req_kraft || 0),
    p_req_technik: Number(row.req_technik || 0),
    p_req_ehrgeiz: Number(row.req_ehrgeiz || 0),
    p_sort_order: Number(row.sort_order || 100),
    p_active: row.active !== false
  })
  if (error) throw error
}

export async function deleteTitle(id) {
  const { error } = await supabase.rpc('admin_delete_player_title', { p_id: Number(id) })
  if (error) throw error
}

export async function saveSpecial(row) {
  const { error } = await supabase.rpc('admin_save_special_attack', {
    p_id: row.id || null,
    p_name: row.name,
    p_description: row.description || '',
    p_min_level: Number(row.min_level || 1),
    p_req_teamgeist: Number(row.req_teamgeist || 0),
    p_req_geschwindigkeit: Number(row.req_geschwindigkeit || 0),
    p_req_kraft: Number(row.req_kraft || 0),
    p_req_technik: Number(row.req_technik || 0),
    p_req_ehrgeiz: Number(row.req_ehrgeiz || 0),
    p_sort_order: Number(row.sort_order || 100),
    p_active: row.active !== false
  })
  if (error) throw error
}

export async function deleteSpecial(id) {
  const { error } = await supabase.rpc('admin_delete_special_attack', { p_id: Number(id) })
  if (error) throw error
}
