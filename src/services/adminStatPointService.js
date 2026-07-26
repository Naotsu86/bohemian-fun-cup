import { supabase } from '../api/supabase'

export async function grantAdminStatPoints(playerId, points) {
  const safePoints = Math.floor(Number(points || 0))

  if (!playerId) {
    throw new Error('Bitte einen Spieler auswählen.')
  }

  if (!Number.isFinite(safePoints) || safePoints <= 0) {
    throw new Error('Bitte eine positive Punktzahl eingeben.')
  }

  const { error } = await supabase.rpc('admin_grant_stat_points', {
    target_player_id: playerId,
    points_to_add: safePoints
  })

  if (error) throw error
}
