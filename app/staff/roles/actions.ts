"use server";

import { createClient } from "@/lib/supabase/server";
import { requireOrganizationPermission } from "@/lib/permissions";
import { revalidatePath } from "next/cache";

const ORG_SLUG="seaside-rp";

async function getOrgId() {
 const db=await createClient();
 const {data,error}=await db.from("organizations").select("id").eq("slug",ORG_SLUG).single();
 if(error||!data) throw new Error("Organization not found.");
 return data.id as string;
}

export async function updateRole(formData:FormData) {
 const db=await createClient(); const organizationId=await getOrgId(); const roleId=String(formData.get("roleId")||"");
 await requireOrganizationPermission(organizationId,"roles.edit");
 const patch={name:String(formData.get("name")||"").trim(),description:String(formData.get("description")||"").trim()||null,hierarchy_level:Math.max(0,Number(formData.get("hierarchyLevel")||0)),parent_role_id:String(formData.get("parentRoleId")||"")||null,enabled:formData.get("enabled")==="on"};
 if(!patch.name) throw new Error("Role name is required.");
 const {error}=await db.from("organization_roles").update(patch).eq("id",roleId).eq("organization_id",organizationId);
 if(error) throw new Error(error.message);
 const {data:user}=await db.auth.getUser();
 await db.from("audit_logs").insert({organization_id:organizationId,actor_user_id:user.user?.id??null,action:"role.updated",category:"staff",target_type:"role",target_id:roleId,target_label:patch.name,metadata:{hierarchy_level:patch.hierarchy_level,parent_role_id:patch.parent_role_id}});
 revalidatePath("/staff/roles"); revalidatePath("/staff/roles/"+roleId);
}

export async function setRolePermissions(formData:FormData) {
 const db=await createClient(); const organizationId=await getOrgId(); const roleId=String(formData.get("roleId")||"");
 await requireOrganizationPermission(organizationId,"roles.permissions");
 const keys=formData.getAll("permission").map(String);
 const {error:roleError}=await db.from("organization_roles").select("id").eq("id",roleId).eq("organization_id",organizationId).single();
 if(roleError) throw new Error("Role not found.");
 const {error:delError}=await db.from("role_permissions").delete().eq("role_id",roleId);
 if(delError) throw new Error(delError.message);
 if(keys.length){const {error}=await db.from("role_permissions").insert(keys.map(permission_key=>({role_id:roleId,permission_key}))); if(error) throw new Error(error.message);}
 const {data:user}=await db.auth.getUser();
 await db.from("audit_logs").insert({organization_id:organizationId,actor_user_id:user.user?.id??null,action:"role.permissions.updated",category:"staff",target_type:"role",target_id:roleId,metadata:{permission_count:keys.length}});
 revalidatePath("/staff/roles"); revalidatePath("/staff/roles/"+roleId);
}

export async function createRole(formData:FormData) {
 const db=await createClient(); const organizationId=await getOrgId();
 await requireOrganizationPermission(organizationId,"roles.create");
 const name=String(formData.get("name")||"").trim();
 if(!name) throw new Error("Role name is required.");
 const {data:role,error}=await db.from("organization_roles").insert({organization_id:organizationId,name,description:String(formData.get("description")||"").trim()||null,hierarchy_level:Math.max(0,Number(formData.get("hierarchyLevel")||0)),parent_role_id:String(formData.get("parentRoleId")||"")||null,color:String(formData.get("color")||"")||null}).select("id").single();
 if(error) throw new Error(error.message);
 const {data:user}=await db.auth.getUser();
 await db.from("audit_logs").insert({organization_id:organizationId,actor_user_id:user.user?.id??null,action:"role.created",category:"staff",target_type:"role",target_id:role.id,target_label:name});
 revalidatePath("/staff/roles");
}
