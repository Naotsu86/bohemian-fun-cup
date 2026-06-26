import { supabase } from '../api/supabase'
export async function getSession(){const{data,error}=await supabase.auth.getSession();if(error)throw error;return data.session}
export async function loginWithPassword(email,password){const{data,error}=await supabase.auth.signInWithPassword({email,password});if(error)throw error;return data.session}
export async function logout(){const{error}=await supabase.auth.signOut();if(error)throw error}
