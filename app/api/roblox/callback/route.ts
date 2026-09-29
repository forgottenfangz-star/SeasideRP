import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "../../../../lib/supabase/server";

export async function GET(request: Request) {
  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  const cookieStore = await cookies();
  const savedState = cookieStore.get("kiwi_roblox_state")?.value;
  const verifier = cookieStore.get("kiwi_roblox_verifier")?.value;

  if (!code || !state || !savedState || state !== savedState || !verifier) {
    return NextResponse.redirect(new URL("/auth?error=Roblox%20connection%20could%20not%20be%20verified.", url.origin));
  }

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.redirect(new URL("/auth?error=Connect%20Discord%20first.", url.origin));

  const body = new URLSearchParams({
    grant_type: "authorization_code",
    code,
    code_verifier: verifier,
    client_id: process.env.ROBLOX_CLIENT_ID!,
    client_secret: process.env.ROBLOX_CLIENT_SECRET!,
    redirect_uri: new URL("/api/roblox/callback", url.origin).toString()
  });

  const tokenResponse = await fetch("https://apis.roblox.com/oauth/v1/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body
  });
  if (!tokenResponse.ok) return NextResponse.redirect(new URL("/auth?error=Roblox%20token%20exchange%20failed.", url.origin));

  const token = await tokenResponse.json();
  const userResponse = await fetch("https://apis.roblox.com/oauth/v1/userinfo", {
    headers: { Authorization: `Bearer ${token.access_token}` }
  });
  if (!userResponse.ok) return NextResponse.redirect(new URL("/auth?error=Could%20not%20read%20your%20Roblox%20identity.", url.origin));

  const roblox = await userResponse.json();
  const { error } = await supabase.from("profiles").update({ roblox_id: String(roblox.sub) }).eq("id", user.id);
  if (error) return NextResponse.redirect(new URL("/auth?error=Could%20not%20link%20Roblox%20to%20your%20CAD%20account.", url.origin));

  const response = NextResponse.redirect(new URL("/character", url.origin));
  response.cookies.delete("kiwi_roblox_state");
  response.cookies.delete("kiwi_roblox_verifier");
  return response;
}
