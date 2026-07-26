/**
 * Benötigte XP vom aktuellen Level bis zum nächsten Level.
 */
export function xpNeededForNextLevel(currentLevel) {
  const level = Math.max(1, Number(currentLevel) || 1)

  if (level >= 15) {
    return 250
  }

  if (level >= 10) {
    return 200
  }

  // Bisherige Formel für Level 1 bis 9.
  return level * 15 + 10
}

/**
 * Gesamte XP, die zum Erreichen eines Levels benötigt werden.
 *
 * Beispiel:
 * xpForLevel(1) = 0
 */
export function xpForLevel(targetLevel) {
  const level = Math.max(1, Number(targetLevel) || 1)

  let totalXp = 0

  for (let currentLevel = 1; currentLevel < level; currentLevel += 1) {
    totalXp += xpNeededForNextLevel(currentLevel)
  }

  return totalXp
}

/**
 * Ermittelt das Level anhand der gesamten XP.
 */
export function levelFromXp(totalXp, maxLevel = 99) {
  const xp = Math.max(0, Number(totalXp) || 0)

  let level = 1

  while (
    level < maxLevel &&
    xp >= xpForLevel(level + 1)
  ) {
    level += 1
  }

  return level
}