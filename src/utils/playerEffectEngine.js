/**
 * Zentrale RPG-Engine.
 *
 * Titel, Skills und Items werden hier zusammengeführt.
 * Der Generator erhält nur den fertigen Spielerzustand.
 */

function number(value, fallback = 0) {
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : fallback
}

function addEffect(effects, source, code, value, target, scope) {
  if (!code) return

  effects.push({
    source,
    code,
    value: number(value),
    target: target || 'self',
    scope: scope || 'permanent'
  })
}

export function calculatePlayerEffects(player) {
  const title = player.player_titles || player.title || {}

  const state = {
    baseStrength: number(player.strength, 1),
    form: number(player.form),

    modifiers: {
      title: {
        strength: number(
          player.title_strength_modifier ??
          title.strength_modifier
        ),

        speed: number(
          player.title_speed_modifier ??
          title.speed_modifier
        ),

        technique: number(
          player.title_technique_modifier ??
          title.technique_modifier
        ),

        power: number(
          player.title_power_modifier ??
          title.power_modifier
        ),

        ambition: number(
          player.title_ambition_modifier ??
          title.ambition_modifier
        ),

        team: number(
          player.title_team_modifier ??
          title.team_modifier
        )
      },

      skill: {
        strength: 0,
        speed: 0,
        technique: 0,
        power: 0,
        ambition: 0,
        team: 0
      },

      item: {
        strength: 0,
        speed: 0,
        technique: 0,
        power: 0,
        ambition: 0,
        team: 0
      }
    },

    effects: [],

    rules: {
      teamBChance: 0.5
    }
  }

  addEffect(
    state.effects,
    'title',
    player.title_effect_code ?? title.effect_code,
    player.title_effect_value ?? title.effect_value,
    player.title_effect_target ?? title.effect_target,
    player.title_effect_scope ?? title.effect_scope
  )

  // Nur vorübergehend zum Testen.
  // Später entfernen, sobald echte Titeldaten geladen werden.
  if (player.name === 'TestPingu') {
    addEffect(
      state.effects,
      'debug',
      'team_b_chance',
      0.25,
      'self',
      'permanent'
    )
  }

  for (const effect of state.effects) {
    if (effect.code === 'team_b_chance') {
      state.rules.teamBChance = Math.min(
        1,
        Math.max(0, number(effect.value, 0.5))
      )
    }
  }

  state.effectiveStrength =
    state.baseStrength +
    state.form +
    state.modifiers.title.strength +
    state.modifiers.skill.strength +
    state.modifiers.item.strength

  return state
}