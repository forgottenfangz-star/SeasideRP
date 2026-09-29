"use server";

import { createClient } from "../../lib/supabase/server";

export async function createCharacter(formData: FormData) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in." };
  const full_name=String(formData.get("full_name")||"").trim();
  const date_of_birth=String(formData.get("date_of_birth")||"").trim();
  const address=String(formData.get("address")||"").trim();
  if(!full_name || full_name.length<2) return {error:"Enter a valid full name."};
  if(!date_of_birth) return {error:"Date of birth is required."};
  if(!address) return {error:"Address is required."};
  const { error } = await supabase.from("characters").insert({user_id:user.id,full_name,date_of_birth,address});
  if(error) return {error:error.message};
  return {success:true};
}