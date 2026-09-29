import { createClient } from "@/lib/supabase/server";

export async function hasOrganizationPermission(organizationId: string, permission: string) {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("has_org_permission", {
    target_org: organizationId,
    permission,
  });
  if (error) return false;
  return data === true;
}

export async function requireOrganizationPermission(organizationId: string, permission: string) {
  const allowed = await hasOrganizationPermission(organizationId, permission);
  if (!allowed) throw new Error("You do not have permission to perform this action.");
}
