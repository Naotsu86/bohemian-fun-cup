import { supabase } from '../api/supabase'

export async function loadPendingPlayers() {
  const { data, error } = await supabase
    .from('players')
    .select('id, name, aka_name, email, approved, active')
    .eq('approved', false)
    .order('name')

  if (error) throw error
  return data || []
}

export async function approvePlayer(playerId) {
  const { error } = await supabase.rpc('approve_player', {
    target_player_id: playerId
  })

  if (error) throw error

  const { data: player, error: verifyError } = await supabase
    .from('players')
    .select('id, approved, active')
    .eq('id', playerId)
    .single()

  if (verifyError) throw verifyError

  if (!player?.approved) {
    throw new Error('Der Spieler wurde in der Datenbank nicht freigegeben.')
  }

  return player
}

export async function blockPlayer(playerId) {
  const { error } = await supabase.rpc('block_player', {
    target_player_id: playerId
  })

  if (error) throw error
}
