import { supabase } from '../api/supabase'

export async function getMyProfile() {
  const { data: userData, error: userError } = await supabase.auth.getUser()
  if (userError) throw userError

  const user = userData.user
  if (!user) return null

  const { data, error } = await supabase
    .from('player_profiles')
    .select('*, players(name)')
    .eq('user_id', user.id)
    .maybeSingle()

  if (error) throw error
  return data
}

export async function updateMyAvatar(profileId, avatar) {
  const { data, error } = await supabase
    .from('player_profiles')
    .update({
      avatar_body: avatar.avatar_body,
      avatar_belly: avatar.avatar_belly,
      head_item: avatar.head_item,
      face_item: avatar.face_item,
      body_item: avatar.body_item,
      back_item: avatar.back_item,
      bio: avatar.bio ?? null
    })
    .eq('id', profileId)
    .select()
    .single()

  if (error) throw error
  return data
}
