"use client";
import { useState } from "react";
import { createClient } from "../../lib/supabase/client";
export default function AuthPage() {
 const [mode,setMode]=useState<"login"|"signup">("signup");
 const [email,setEmail]=useState(""); const [password,setPassword]=useState("");
 const [message,setMessage]=useState(""); const [busy,setBusy]=useState(false);
 async function submit(e:React.FormEvent){ e.preventDefault(); setBusy(true); setMessage(""); const supabase=createClient();
 if(mode==="signup"){ const {data,error}=await supabase.auth.signUp({email,password}); if(error)setMessage(error.message); else if(data.session)window.location.href="/character"; else setMessage("Account created. Check your email if confirmation is enabled."); }
 else { const {error}=await supabase.auth.signInWithPassword({email,password}); if(error)setMessage(error.message); else window.location.href="/character"; } setBusy(false); }
 return <main className="shell"><nav><strong>SEASIDE<span>RP</span></strong><a href="/">Home</a></nav><section className="panel"><p className="eyebrow">{mode==="signup"?"CREATE ACCOUNT":"SIGN IN"}</p><h1>{mode==="signup"?"Create your account":"Welcome back"}</h1><p className="muted">Your account is stored in SeasideRP. Your persistent RP character is attached to it.</p><form className="form" onSubmit={submit}><label>Email<input required type="email" value={email} onChange={e=>setEmail(e.target.value)}/></label><label>Password<input required minLength={8} type="password" value={password} onChange={e=>setPassword(e.target.value)}/></label><button className="button" disabled={busy}>{busy?"Working…":mode==="signup"?"Create account":"Sign in"}</button></form>{message&&<p className="muted">{message}</p>}<button className="button secondary" onClick={()=>{setMode(mode==="signup"?"login":"signup");setMessage("")}}>{mode==="signup"?"I already have an account":"Create a new account"}</button></section></main>
}