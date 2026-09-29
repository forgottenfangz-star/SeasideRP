import "node:process";
import {Client,GatewayIntentBits} from "discord.js";

const token=process.env.DISCORD_BOT_TOKEN;
const base=(process.env.KIWI_CAD_URL||"").replace(/\/$/,"");
const secret=process.env.KIWI_DISCORD_SYNC_SECRET;
const org=process.env.KIWI_ORGANIZATION_ID;
const guildId=process.env.KIWI_GUILD_ID;
if(!token||!base||!secret||!org||!guildId) throw new Error("Missing Discord bot configuration.");

const client=new Client({intents:[GatewayIntentBits.Guilds,GatewayIntentBits.GuildMembers]});

async function sync(member){
 if(member.guild.id!==guildId)return;
 const res=await fetch(base+"/api/discord/sync",{method:"POST",headers:{"content-type":"application/json","authorization:"Bearer "+secret},body:JSON.stringify({organization_id:org,guild_id:member.guild.id,discord_user_id:member.user.id,discord_role_ids:[...member.roles.cache.keys()]})});
 if(!res.ok) console.error("Kiwi CAD sync failed",member.user.tag,res.status,await res.text());
}

client.once("ready",async()=>{
 console.log("Kiwi CAD Discord bot online as "+client.user.tag);
 const guild=client.guilds.cache.get(guildId);
 if(!guild){console.error("Configured guild is not available to this bot.");return;}
 try{const members=await guild.members.fetch();for(const member of members.values()){if(!member.user.bot)await sync(member);}console.log("Initial role sync complete.");}catch(e){console.error("Initial sync failed",e);}
});
client.on("guildMemberAdd",sync);
client.on("guildMemberUpdate",async(_old,member)=>sync(member));
client.login(token);