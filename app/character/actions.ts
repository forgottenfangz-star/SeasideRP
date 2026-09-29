"use server";

import { redirect } from "next/navigation";
import { createClient } from "../../lib/supabase/server";

export async function createCharacter(formData: FormData): Promise<never> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) redirect("/auth?error=You%20must%20be%20signed%20in.");

  const full_name = String(formData.get("full_name") || "").trim();
  const date_of_birth = String(formData.get("date_of_birth") || "").trim();
  const address = String(formData.get("address") || "").trim();

  if (!full_name || full_name.length < 2) redirect("/character?error=Enter%20a%20valid%20full%20name.");
  if (!date_of_birth) redirect("/character?error=Date%20of%20birth%20is%20required.");
  if (!address) redirect("/character?error=Address%20is%20required.");

  const { error } = await supabase.from("characters").insert({
    user_id: user.id,
    full_name,
    date_of_birth,
    address,
  });

  if (error) redirect(`/character?error=${encodeURIComponent(error.message)}`);

  redirect("/character");
}