import { NextResponse } from "next/server";
import { randomBytes, createHash } from "crypto";
import { createClient } from "../../../../lib/supabase/server";

function base64url(input: Buffer) {
  return input.toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

export async function GET(request: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.redirect(new URL("/auth?error=Connect%20Discord%20first.", request.url));

  if (!process.env.ROBLOX_CLIENT_ID) {
    return NextResponse.redirect(new URL("/auth?error=Roblox%20OAuth%20is%20not%20configured%20yet.", request.url));
  }

  const state = base64url(randomBytes(32));
  const verifier = base64url(randomBytes(48));
  const challenge = base64url(createHash("sha256").update(verifier).digest());

  const response = NextResponse.redirect(new URL("/api/roblox/callback", request.url));
  response.cookies.set("kiwi_roblox_state", state, { httpOnly: true, secure: true, sameSite: "lax", maxAge: 600, path: "/" });
  response.cookies.set("kiwi_roblox_verifier", verifier, { httpOnly: true, secure: true, sameSite: "lax", maxAge: 600, path: "/" });

  const callback = new URL("/api/roblox/callback", request.url);
  const authorize = new URL("https://apis.roblox.com/oauth/v1/authorize");
  authorize.searchParams.set("client_id", process.env.ROBLOX_CLIENT_ID);
  authorize.searchParams.set("redirect_uri", callback.toString());
  authorize.searchParams.set("scope", "openid profile");
  authorize.searchParams.set("response_type", "code");
  authorize.searchParams.set("state", state);
  authorize.searchParams.set("code_challenge", challenge);
  authorize.searchParams.set("code_challenge_method", "S256");

  return NextResponse.redirect(authorize);
}
