import { NextResponse } from "next/server";
import { createClient } from "../../../lib/supabase/server";

export async function GET(request: Request) {
  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  const next = url.searchParams.get("next") || "/character";
  if (!code) return NextResponse.redirect(new URL("/auth?error=Discord%20sign-in%20was%20cancelled.", url.origin));

  const supabase = await createClient();
  const { error } = await supabase.auth.exchangeCodeForSession(code);
  if (error) return NextResponse.redirect(new URL("/auth?error=Discord%20sign-in%20failed.", url.origin));

  const { data: { user } } = await supabase.auth.getUser();
  const discordId = user?.user_metadata?.provider_id || user?.user_metadata?.sub;
  if (user && discordId) {
    await supabase.from("profiles").update({ discord_id: String(discordId) }).eq("id", user.id);
  }

  return NextResponse.redirect(new URL(next, url.origin));
}
