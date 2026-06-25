import { createClient } from '@supabase/supabase-js'

export const supabaseUrl = 'https://xubrfwhjqskuzbujepro.supabase.co'
export const supabaseKey = 'sb_publishable_KZBXCLQ_UizvXSy7Blc5WA_rnp3hMZ-'
export const supabase = createClient(supabaseUrl, supabaseKey)
