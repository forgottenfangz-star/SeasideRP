import Link from "next/link";

export default function DispatchPage() {
  return (
    <main className="cad-app">
      <aside className="sidebar">
        <Link href="/" className="cad-brand"><strong>KIWI</strong><span>CAD</span></Link>
        <div className="server-chip"><span className="online-dot" /><div><small>SERVER</small><b>SeasideRP</b></div></div>
        <p className="side-label">OPERATIONS</p>
        <nav className="side-nav">
          <Link href="/dispatch" className="side-link active"><i>⌖</i><span>Dispatch Map</span></Link>
          <Link href="/staff" className="side-link"><i>◆</i><span>Staff</span></Link>
          <Link href="/" className="side-link"><i>⌂</i><span>Overview</span></Link>
        </nav>
      </aside>
      <section className="workspace">
        <header className="workspace-top"><div><span className="crumb">KIWI CAD / SEASIDERP / DISPATCH</span><h1>Dispatch Map</h1></div><Link href="/staff" className="profile-button">Staff</Link></header>
        <div className="content">
          <section className="welcome"><div><p className="eyebrow">LIVE OPERATIONS</p><h2>Dispatch map.</h2><p>The map foundation is organization-scoped, so each community can maintain its own map, markers and operational data.</p></div></section>
          <section className="panel" style={{minHeight:520}}>
            <div className="panel-head"><div><span className="panel-kicker">MAP</span><h3>Operations canvas</h3></div><span className="badge green">READY</span></div>
            <div style={{height:420,display:"grid",placeItems:"center",border:"1px dashed rgba(255,255,255,.14)",borderRadius:16,background:"rgba(255,255,255,.02)"}}>
              <div style={{textAlign:"center",maxWidth:520}}><div style={{fontSize:48}}>⌖</div><h4>Map data layer ready</h4><p className="info-copy">Organization maps, markers and default-map configuration are now part of the CAD foundation. Live ERLC units, calls and incidents can be attached to this layer next.</p></div>
            </div>
          </section>
        </div>
      </section>
    </main>
  );
}
