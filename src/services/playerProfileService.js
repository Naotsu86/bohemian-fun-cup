import { supabase } from '../api/supabase'

export async function getMyProfile() {
  const { data: userData, error: userError } = await supabase.auth.getUser()
  if (userError) throw userError

  const user = userData.user
  if (!user) return null

  const { data, error } = await supabase
    .from('player_profiles')
    .select('*, players(name, email, approved, active)')
    .eq('user_id', user.id)
    .maybeSingle()

  if (error) throw error
  if (!data) return null

  return {
    ...data,
    level: levelFromXp(Number(data.xp_total || 0))
  }
}

export async function loadProfileChoices(profile) {
  const [titles, attacks] = await Promise.all([
    supabase.rpc('get_my_unlocked_titles'),
    supabase.rpc('get_my_available_special_attacks')
  ])

  if (!titles.error && !attacks.error) {
    return {
      titles: (titles.data || [])
        .filter(title => title.unlocked)
        .filter(title => !isEmptyTitle(title)),

      attacks: (attacks.data || [])
        .filter(attack => attack.unlocked)
        .filter(attack => !isEmptySpecial(attack))
    }
  }

  console.warn('RPC für Titel/Spezialattacken nicht verfügbar, nutze Fallback.', {
    titles: titles.error?.message,
    attacks: attacks.error?.message
  })

  const level = Number(profile?.level || levelFromXp(Number(profile?.xp_total || 0)))

  const [fallbackTitles, fallbackAttacks] = await Promise.all([
    supabase.from('player_titles').select('*').eq('active', true).order('sort_order'),
    supabase.from('special_attacks').select('*').eq('active', true).lte('min_level', level).order('sort_order')
  ])

  if (fallbackTitles.error) throw fallbackTitles.error
  if (fallbackAttacks.error) throw fallbackAttacks.error

  const unlockedTitles = (fallbackTitles.data || [])
    .filter(title =>
      level >= Number(title.min_level || 1) &&
      Number(profile?.stat_teamgeist || 0) >= Number(title.req_teamgeist || 0) &&
      Number(profile?.stat_geschwindigkeit || 0) >= Number(title.req_geschwindigkeit || 0) &&
      Number(profile?.stat_kraft || 0) >= Number(title.req_kraft || 0) &&
      Number(profile?.stat_technik || 0) >= Number(title.req_technik || 0) &&
      Number(profile?.stat_ehrgeiz || 0) >= Number(title.req_ehrgeiz || 0)
    )
    .filter(title => !isEmptyTitle(title))

  return {
    titles: unlockedTitles,
    attacks: (fallbackAttacks.data || []).filter(attack => !isEmptySpecial(attack))
  }
}

export async function updateMyProfileChoices(profileId, choices) {
  const { error } = await supabase.rpc('update_my_profile_choices', {
    new_title_id: choices.selected_title_id || null,
    new_special_attack_id: choices.selected_special_attack_id || null,
    new_body_color: choices.body_color || null,
    new_head_item: choices.head_item || null,
    new_top_item: choices.top_item || null,
    new_bottom_item: choices.bottom_item || null
  })

  if (error) {
    const fallback = await supabase
      .from('player_profiles')
      .update({
        selected_title_id: choices.selected_title_id || null,
        selected_special_attack_id: choices.selected_special_attack_id || null,
        body_color: choices.body_color,
        head_item: choices.head_item,
        top_item: choices.top_item,
        bottom_item: choices.bottom_item,
        shorts_item: choices.bottom_item
      })
      .eq('id', profileId)

    if (fallback.error) throw error
  }
}

export async function allocateMyStatPoints(points) {
  const { error } = await supabase.rpc('allocate_my_stat_points', {
    add_teamgeist: Number(points.teamgeist || 0),
    add_geschwindigkeit: Number(points.geschwindigkeit || 0),
    add_kraft: Number(points.kraft || 0),
    add_technik: Number(points.technik || 0),
    add_ehrgeiz: Number(points.ehrgeiz || 0)
  })

  if (error) throw error
}

export async function updateMyAvatar(profileId, avatar) {
  return updateMyProfileChoices(profileId, {
    selected_title_id: avatar.selected_title_id,
    selected_special_attack_id: avatar.selected_special_attack_id,
    body_color: avatar.body_color,
    head_item: avatar.head_item,
    top_item: avatar.top_item,
    bottom_item: avatar.bottom_item || avatar.shorts_item
  })
}

function isEmptyTitle(title) {
  const name = normalize(title?.name)
  const code = normalize(title?.code)

  return code === 'none' || name === 'kein titel' || name === 'none'
}

function isEmptySpecial(attack) {
  const name = normalize(attack?.name)
  const code = normalize(attack?.code)

  return code === 'none' || name === 'keine spezialattacke' || name === 'keine' || name === 'none'
}

function normalize(value) {
  return String(value || '').trim().toLowerCase()
}

function levelFromXp(totalXp) {
  let lvl = 1
  while (totalXp >= xpForLevel(lvl + 1) && lvl < 99) lvl += 1
  return lvl
}

function xpForLevel(targetLevel) {
  let needed = 0
  for (let current = 1; current < targetLevel; current += 1) {
    needed += current * 15 + 10
  }
  return needed
}
