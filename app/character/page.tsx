import { createClient } from "../../lib/supabase/server";
import { createCharacter } from "./actions";

export default async function Character(){
  const supabase=await createClient();
  const {data:{user}}=await supabase.auth.getUser();

  if(!user) return <main className="shell"><section className="panel"><p className="eyebrow">SIGN IN REQUIRED</p><h1>Create your account first</h1><p className="muted">Your character is saved to your Kiwi CAD account and can be used across supported roleplay organizations.</p><a className="button" href="/auth">Go to account</a></section></main>;

  const {data:character}=await supabase.from("characters").select("id,full_name,date_of_birth,address,status").eq("user_id",user.id).maybeSingle();

  if(character) return <main className="shell"><nav><strong>KIWI<span>CAD</span></strong><a href="/">Home</a></nav><section className="panel"><p className="eyebrow">YOUR RP CHARACTER</p><h1>{character.full_name}</h1><p className="muted">Character ID: {character.id}</p><div className="card"><p>Status: {character.status}</p><p>Date of birth: {character.date_of_birth}</p><p>Address: {character.address}</p></div></section></main>;

  return <main className="shell"><nav><strong>SEASIDE<span>RP</span></strong><a href="/">Home</a></nav><section className="panel"><p className="eyebrow">RP CHARACTER</p><h1>Create your character</h1><p className="muted">This becomes the persistent roleplay person attached to your account.</p><form className="form" action={createCharacter}><label>Full name<input name="full_name" required minLength={2} placeholder="e.g. Jordan Mitchell"/></label><label>Date of birth<input name="date_of_birth" required type="date"/></label><label>Address<input name="address" required placeholder="Sydney, NSW"/></label><button className="button" type="submit">Create character</button></form></section></main>;
}