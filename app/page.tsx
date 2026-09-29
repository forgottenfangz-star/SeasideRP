import Image from "next/image";
import Link from "next/link";

export default function Home() {
  return (
    <main className="site-shell">
      <nav className="topbar">
        <Link className="brand" href="/">
          <Image src="/kivi-cad-logo.webp" alt="Kiwi CAD" width={42} height={42} priority />
          <span>KIWI <b>CAD</b></span>
        </Link>
        <div className="nav-links">
          <Link href="/character">Character</Link>
          <Link href="/licences">Licences</Link>
          <Link href="/records">Records</Link>
          <Link className="nav-login" href="/auth">Sign in</Link>
        </div>
      </nav>

      <section className="hero">
        <div className="hero-logo">
          <Image src="/kivi-cad-logo.webp" alt="Kiwi CAD logo" width={132} height={132} priority />
        </div>
        <p className="eyebrow">KIWI CAD · ERLC ROLEPLAY</p>
        <h1>One CAD for your<br /><span>entire roleplay.</span></h1>
        <p className="hero-copy">
          Manage your character, licences and records from one clean, live roleplay system.
          Built for communities that want their CAD to feel like an actual platform.
        </p>
        <div className="actions">
          <Link className="button primary" href="/character">Get started</Link>
          <Link className="button secondary" href="/licences">Explore licences</Link>
        </div>
      </section>

      <section className="feature-grid">
        <Link className="feature-card" href="/character">
          <span className="feature-number">01</span>
          <h2>Character</h2>
          <p>Your persistent RP identity, connected to your CAD account.</p>
        </Link>
        <Link className="feature-card" href="/licences">
          <span className="feature-number">02</span>
          <h2>Licences</h2>
          <p>Driver, fishing, boat, hunting and firearms licensing.</p>
        </Link>
        <Link className="feature-card" href="/records">
          <span className="feature-number">03</span>
          <h2>Records</h2>
          <p>Keep the records that make your character part of the world.</p>
        </Link>
      </section>

      <footer>
        <span>KIWI CAD</span>
        <span>Roleplay records platform</span>
      </footer>
    </main>
  );
}
