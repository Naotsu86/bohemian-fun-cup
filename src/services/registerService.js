import { supabase } from '../api/supabase'

export async function registerPlayer({ email, password, name, akaName }) {
  const cleanEmail = email.trim().toLowerCase()
  const cleanName = name.trim()
  const cleanAka = akaName.trim()

  if (!cleanEmail || !password || !cleanName) {
    throw new Error('Bitte E-Mail, Passwort und Vorname eingeben.')
  }

  if (password.length < 6) {
    throw new Error('Das Passwort muss mindestens 6 Zeichen haben.')
  }

  const { data, error } = await supabase.auth.signUp({
    email: cleanEmail,
    password,
    options: {
      data: {
        name: cleanName,
        aka_name: cleanAka
      }
    }
  })

  if (error) throw error
  return data
}
