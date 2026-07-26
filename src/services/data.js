import { supabase } from '../api/supabase'
import { calculateForm } from './generator'

async function loadPlayerCards() {
  const rpc = await supabase.rpc('get_player_cards')
  if (!rpc.error) return rpc.data || []

  const view = await supabase.from('player_card_view').select('*')
  if (view.error) return []
  return view.data || []
}

async function loadScoreTotals() {
  const { data, error } = await supabase.rpc('get_player_score_totals')
  if (error) throw error
  return data || []
}

export async function loadAll() {
const [p, m, s, cards, totals, titles] = await Promise.all([
  supabase.from('players').select('*').order('created_at', { ascending: true }),
  supabase.from('matches').select('*').order('created_at', { ascending: true }),
  supabase.from('settings').select('*').eq('id', 'main').maybeSingle(),
  loadPlayerCards(),
  loadScoreTotals(),

  supabase
    .from('player_titles')
    .select(`
      id,
      name,
      strength_modifier,
      speed_modifier,
      technique_modifier,
      ambition_modifier,
      team_modifier,
      power_modifier,
      effect_code,
      effect_value,
      effect_target,
      effect_scope
    `)
])

  if (p.error) throw p.error
  if (m.error) throw m.error
  if (s.error) throw s.error
  if (titles.error) throw titles.error

  const cardByPlayerId = Object.fromEntries(
    (cards || []).map(row => [row.player_id, row])
  )

  const totalsByPlayerId = Object.fromEntries(
    (totals || []).map(row => [row.player_id, row])
  )

  const titleById = Object.fromEntries(
  (titles.data || []).map(title => [String(title.id), title])
  )

  const titleByName = Object.fromEntries(
  (titles.data || []).map(title => [title.name, title])
  )

  const calculatedForm = calculateForm(
  p.data || [],
  m.data || []
  )

  const players = (p.data || []).map(player => {
    const card = cardByPlayerId[player.id] || {}
    const score = totalsByPlayerId[player.id] || {}
    const selectedTitle =
      titleById[String(card.selected_title_id)] ||
      titleByName[card.selected_title_name] || {}

    return {
      ...player,
      ...card,

      id: player.id,
      name: player.name,
      email: player.email,
      active: player.active,
      approved: player.approved,
      strength: player.strength,
      form: Number(calculatedForm[player.id] || 0),

    
      score_total: Number(score.total_points || 0),
      score_games: Number(score.games || 0),
      score_wins: Number(score.wins || 0),
      score_diff: Number(score.point_diff || 0),
      score_pause_points: Number(score.pause_points || 0),
      score_absence_points: Number(score.absence_points || 0),

      previous_score_total: Number(score.previous_total_points || 0),
      previous_score_games: Number(score.previous_games || 0),
      previous_score_wins: Number(score.previous_wins || 0),
      previous_score_diff: Number(score.previous_point_diff || 0),
      has_rank_history: score.has_rank_history === true,

      xp_total: Number(card.xp_total || score.total_points || 0),
      calculated_level: Number(card.calculated_level || 1),
      current_level_xp: Number(card.current_level_xp || 0),
      next_level_xp: Number(card.next_level_xp || 25),

      stat_points_total: Number(card.stat_points_total || 0),
      stat_points_spent: Number(card.stat_points_spent || 0),
      stat_points_available: Number(card.stat_points_available || 0),

      stat_teamgeist: Number(card.stat_teamgeist || 0),
      stat_geschwindigkeit: Number(card.stat_geschwindigkeit || 0),
      stat_kraft: Number(card.stat_kraft || 0),
      stat_technik: Number(card.stat_technik || 0),
      stat_ehrgeiz: Number(card.stat_ehrgeiz || 0),

      selected_title_id: card.selected_title_id || null,
      selected_title_name: card.selected_title_name || null,
      selected_title_description: card.selected_title_description || null,
      title_strength_modifier: Number(
  selectedTitle.strength_modifier || 0
),

title_speed_modifier: Number(
  selectedTitle.speed_modifier || 0
),

title_technique_modifier: Number(
  selectedTitle.technique_modifier || 0
),

title_ambition_modifier: Number(
  selectedTitle.ambition_modifier || 0
),

title_team_modifier: Number(
  selectedTitle.team_modifier || 0
),

title_power_modifier: Number(
  selectedTitle.power_modifier || 0
),

title_effect_code:
  selectedTitle.effect_code || null,

title_effect_value: Number(
  selectedTitle.effect_value || 0
),

title_effect_target:
  selectedTitle.effect_target || 'self',

title_effect_scope:
  selectedTitle.effect_scope || 'permanent',

      selected_special_attack_id: card.selected_special_attack_id || null,
      selected_special_attack_name: card.selected_special_attack_name || null,
      selected_special_attack_description: card.selected_special_attack_description || null,

      body_color: card.body_color || player.body_color || 'black',
      head_item: card.head_item || player.head_item || 'none',
      top_item: card.top_item || player.top_item || 'none',
      bottom_item: card.bottom_item || card.shorts_item || player.shorts_item || 'none',
      shorts_item: card.bottom_item || card.shorts_item || player.shorts_item || 'none',
      accessory_item: card.accessory_item || player.accessory_item || 'none'
    }
  })

  return {
    players,
    matches: m.data || [],
    settings: s.data?.value || {}
  }
}

export async function addPlayer(row) {
  const { error } = await supabase.from('players').insert({
    name: row.name,
    strength: row.strength,
    form: 0,
    active: true
  })
  if (error) throw error
}

export async function updatePlayer(id, patch) {
  const { error } = await supabase.from('players').update(patch).eq('id', id)
  if (error) throw error
}

export async function deletePlayer(id) {
  const { error } = await supabase.from('players').delete().eq('id', id)
  if (error) throw error
}

export async function insertMatch(row) {
  const { error } = await supabase.from('matches').insert(row)
  if (error) throw error
}

export async function updateMatch(id, patch) {
  const changesScore =
    Object.prototype.hasOwnProperty.call(patch, 'score_a') ||
    Object.prototype.hasOwnProperty.call(patch, 'score_b')

  if (changesScore) {
    const { data: current, error: readError } = await supabase
      .from('matches')
      .select('score_a, score_b')
      .eq('id', id)
      .single()

    if (readError) throw readError

    const scoreA = Object.prototype.hasOwnProperty.call(patch, 'score_a')
      ? patch.score_a
      : current.score_a
    const scoreB = Object.prototype.hasOwnProperty.call(patch, 'score_b')
      ? patch.score_b
      : current.score_b

    const { error } = await supabase.rpc('save_match_score', {
      target_match_id: id,
      new_score_a: Number(scoreA),
      new_score_b: Number(scoreB)
    })

    if (error) throw error
    return
  }

  const { error } = await supabase.from('matches').update(patch).eq('id', id)
  if (error) throw error
}

export async function deleteMatch(id) {
  const { error } = await supabase.rpc('delete_match_with_points', {
    target_match_id: id
  })
  if (error) throw error
}

export async function updateSettings(value) {
  const { error } = await supabase.from('settings').upsert({ id: 'main', value })
  if (error) throw error
}

export async function updateForms(players, matches) {
  const form = calculateForm(players, matches)
  await Promise.all(players.map(player =>
    supabase.from('players').update({ form: form[player.id] || 0 }).eq('id', player.id)
  ))
}
