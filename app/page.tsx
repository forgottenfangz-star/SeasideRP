"use client";

import Image from "next/image";
import Link from "next/link";
import { useState } from "react";

const nav = [
  ["Overview", "⌂"],
  ["Character", "♙"],
  ["Licences", "▣"],
  ["Vehicles", "▱"],
  ["Records", "▤"],
  ["Businesses", "⌂"],
  ["Phone", "◈"],
  ["Market", "◇"],
  ["Communities", "◎"],
];

export default function Home() {
  const [active, setActive] = useState("Overview");

  return (
    <main className="cad-app">
      <aside className="sidebar">
        <Link href="/" className="cad-brand">
          <Image src="/kivi-cad-logo.webp" alt="Kiwi CAD" width={38} height={38} priority />
          <div><strong>KIWI</strong><span>CAD</span></div>
        </Link>
        <div className="server-chip"><span className="online-dot" /><div><small>SERVER</small><b>SeasideRP</b></div></div>
        <p className="side-label">CAD</p>
        <nav className="side-nav">
          {nav.map(([label, icon]) => (
            <Link href={label === "Overview" ? "/" : label === "Communities" ? "/organizations" : "/" + label.toLowerCase()} key={label}
              className={active === label ? "side-link active" : "side-link"} onClick={() => setActive(label)}>
              <i>{icon}</i><span>{label}</span>
            </Link>
          ))}
        </nav>
        <p className="side-label">ACCOUNT</p>
        <nav className="side-nav">
          <Link href="/auth" className="side-link"><i>↪</i><span>Sign in</span></Link>
          <Link href="/settings" className="side-link"><i>⚙</i><span>Settings</span></Link>
        </nav>
        <div className="sidebar-bottom"><div className="user-mini"><div className="avatar">K</div><div><b>Kiwi CAD</b><small>Citizen portal</small></div></div></div>
      </aside>

      <section className="workspace">
        <header className="workspace-top">
          <div><span className="crumb">KIWI CAD / SEASIDERP</span><h1>Overview</h1></div>
          <div className="top-actions"><button className="icon-button">⌕</button><button className="icon-button">◌</button><Link href="/auth" className="profile-button"><span>K</span> Account</Link></div>
        </header>

        <div className="content">
          <section className="welcome">
            <div><p className="eyebrow">SEASIDERP · SYDNEY · NEW SOUTH WALES</p><h2>Your roleplay command centre.</h2><p>Everything attached to your character, in one place.</p></div>
            <div className="welcome-mark"><Image src="/kivi-cad-logo.webp" alt="" width={76} height={76} /></div>
          </section>

          <div className="stats">
            <article className="stat"><span>CHARACTER</span><strong>Not created</strong><small>Set up your permanent RP identity</small></article>
            <article className="stat"><span>LICENCES</span><strong>0 active</strong><small>Driver, boat, fishing & more</small></article>
            <article className="stat"><span>RECORDS</span><strong>0 records</strong><small>Your roleplay history</small></article>
            <article className="stat"><span>STATUS</span><strong className="status-live"><i /> System online</strong><small>Kiwi CAD services operational</small></article>
          </div>

          <div className="dashboard-grid">
            <section className="panel large-panel">
              <div className="panel-head"><div><span className="panel-kicker">PERSONAL</span><h3>Character profile</h3></div><Link href="/character">Open character →</Link></div>
              <div className="empty-state"><div className="empty-icon">♙</div><h4>No character yet</h4><p>Create your permanent roleplay character to unlock licences, vehicles and records.</p><Link href="/character" className="primary-button">Create character</Link></div>
            </section>
            <section className="panel">
              <div className="panel-head"><div><span className="panel-kicker">QUICK ACCESS</span><h3>Services</h3></div></div>
              <div className="quick-list">
                <Link href="/licences"><span>▣</span><div><b>Licences</b><small>Manage your licences</small></div><em>→</em></Link>
                <Link href="/records"><span>▤</span><div><b>Records</b><small>View your RP record</small></div><em>→</em></Link>
                <Link href="/vehicles"><span>▱</span><div><b>Vehicles</b><small>Registered vehicles</small></div><em>→</em></Link>
                <Link href="/market"><span>◇</span><div><b>Market</b><small>Buy & sell in-world</small></div><em>→</em></Link>
              </div>
            </section>
          </div>

          <div className="lower-grid">
            <section className="panel"><div className="panel-head"><div><span className="panel-kicker">SYSTEM</span><h3>Kiwi CAD services</h3></div><span className="badge green">OPERATIONAL</span></div>
              <div className="service-row"><span>●</span><b>Core CAD</b><small>Online</small></div><div className="service-row"><span>●</span><b>Identity services</b><small>Online</small></div><div className="service-row"><span>●</span><b>Records service</b><small>Online</small></div>
            </section>
            <section className="panel"><div className="panel-head"><div><span className="panel-kicker">INFORMATION</span><h3>Getting started</h3></div></div><p className="info-copy">Create your character first. Your character becomes your persistent identity across the roleplay system and is used for licences, vehicles and records.</p><Link href="/character" className="text-link">Set up character →</Link></section>
          </div>
        </div>
      </section>
    </main>
  );
}
