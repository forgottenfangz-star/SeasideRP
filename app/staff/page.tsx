import Link from "next/link";
import { createClient } from "@/lib/supabase/server";

export default async function StaffPage() {
  const supabase = await createClient();
  const { data: user } = await supabase.auth.getUser();

  return (
    <main className="cad-app">
      <aside className="sidebar">
        <Link href="/" className="cad-brand"><strong>KIWI</strong><span>CAD</span></Link>
        <div className="server-chip"><span className="online-dot" /><div><small>SERVER</small><b>SeasideRP</b></div></div>
        <p className="side-label">STAFF</p>
        <nav className="side-nav">
          <Link href="/staff" className="side-link active"><i>◆</i><span>Staff</span></Link>
          <Link href="/staff/logs" className="side-link"><i>▤</i><span>Audit Logs</span></Link>
          <Link href="/staff/roles" className="side-link"><i>◆</i><span>Roles & Permissions</span></Link>
          <Link href="/dispatch" className="side-link"><i>⌖</i><span>Dispatch Map</span></Link>
          <Link href="/settings" className="side-link"><i>⚙</i><span>Organization Settings</span></Link>
        </nav>
        <p className="side-label">CAD</p>
        <nav className="side-nav"><Link href="/" className="side-link"><i>⌂</i><span>Overview</span></Link></nav>
      </aside>
      <section className="workspace">
        <header className="workspace-top">
          <div><span className="crumb">KIWI CAD / SEASIDERP / STAFF</span><h1>Staff Management</h1></div>
          <div className="top-actions"><Link href="/" className="profile-button">Dashboard</Link></div>
        </header>
        <div className="content">
          <section className="welcome">
            <div><p className="eyebrow">STAFF CONTROL CENTRE</p><h2>Manage your organization.</h2><p>Staff access, custom roles, permissions, audit history and dispatch tools live here.</p></div>
          </section>
          <div className="dashboard-grid">
            <section className="panel">
              <div className="panel-head"><div><span className="panel-kicker">STAFF</span><h3>People & access</h3></div></div>
              <div className="quick-list">
                <Link href="/staff/roles"><span>◆</span><div><b>Roles & permissions</b><small>Custom hierarchy, inheritance and granular permissions</small></div><em>→</em></Link>
                <Link href="/staff/logs"><span>▤</span><div><b>Audit logs</b><small>Track permission-sensitive staff actions</small></div><em>→</em></Link>
              </div>
            </section>
            <section className="panel">
              <div className="panel-head"><div><span className="panel-kicker">OPERATIONS</span><h3>Dispatch</h3></div></div>
              <div className="quick-list">
                <Link href="/dispatch"><span>⌖</span><div><b>Dispatch map</b><small>Calls, units, markers and live operations</small></div><em>→</em></Link>
                <Link href="/staff"><span>◷</span><div><b>Staff shifts</b><small>Track active and historical staff shifts</small></div><em>→</em></Link>
              </div>
            </section>
          </div>
          <section className="panel">
            <div className="panel-head"><div><span className="panel-kicker">SESSION</span><h3>Signed-in account</h3></div></div>
            <p className="info-copy">{user ? "Your authenticated Kiwi CAD account is active." : "Sign in to access organization staff tools."}</p>
          </section>
        </div>
      </section>
    </main>
  );
}
