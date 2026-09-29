"use client";

import Image from "next/image";
import { useState } from "react";
import { createClient } from "../../lib/supabase/client";

export default function AuthPage() {
  const [busy, setBusy] = useState<"discord" | "roblox" | null>(null);
  const [message, setMessage] = useState("");

  async function discord() {
    setBusy("discord"); setMessage("");
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOAuth({
      provider: "discord",
      options: { redirectTo: `${window.location.origin}/auth/callback` }
    });
    if (error) { setMessage(error.message); setBusy(null); }
  }

  async function roblox() {
    setBusy("roblox"); setMessage("");
    window.location.href = "/api/roblox/start";
  }

  return (
    <main className="auth-screen">
      <div className="auth-glow" />
      <section className="auth-card">
        <div className="auth-head">
          <Image src="/kivi-cad-logo.webp" alt="Kiwi CAD" width={58} height={58} priority />
          <span className="auth-kicker">KIWI CAD · SYDNEY RP</span>
          <h1>Enter Kiwi CAD</h1>
          <p>Your CAD account is built around your Discord and Roblox identities. No email or password.</p>
        </div>

        <div className="identity-stack">
          <button className="identity-button discord" onClick={discord} disabled={!!busy}>
            <span className="identity-icon">◉</span>
            <span><b>{busy === "discord" ? "Connecting…" : "Continue with Discord"}</b><small>Sign in and link your Discord identity</small></span>
            <em>→</em>
          </button>
          <button className="identity-button roblox" onClick={roblox} disabled={!!busy}>
            <span className="identity-icon">◇</span>
            <span><b>{busy === "roblox" ? "Connecting…" : "Link Roblox account"}</b><small>Required to connect your RP identity</small></span>
            <em>→</em>
          </button>
        </div>

        <div className="auth-rule"><span>HOW IT WORKS</span></div>
        <div className="auth-steps">
          <div><b>01</b><span>Connect Discord</span><small>Your Discord account becomes your CAD login.</small></div>
          <div><b>02</b><span>Connect Roblox</span><small>We attach your Roblox identity to the same CAD account.</small></div>
          <div><b>03</b><span>Create your character</span><small>Your permanent RP character is created once.</small></div>
        </div>

        {message && <div className="auth-error">{message}</div>}
        <a className="back-home" href="/">← Back to Kiwi CAD</a>
      </section>
    </main>
  );
}
