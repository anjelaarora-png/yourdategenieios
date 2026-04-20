import { Link } from "react-router-dom";
import { Sparkles, ArrowLeft, Shield, Lock, Eye, UserCheck, Globe, Bell, Trash2, Mail } from "lucide-react";
import { Button } from "@/components/ui/button";

const EFFECTIVE_DATE = "April 18, 2026";
const CONTACT_EMAIL = "privacy@yourdategenie.com";
const APP_NAME = "Your Date Genie";
const COMPANY = "Your Date Genie, Inc.";

const Section = ({ icon: Icon, title, children }: { icon: React.ElementType; title: string; children: React.ReactNode }) => (
  <section className="mb-10">
    <div className="flex items-center gap-3 mb-4">
      <div className="w-9 h-9 rounded-full bg-primary/10 border border-primary/20 flex items-center justify-center flex-shrink-0">
        <Icon className="w-4 h-4 text-primary" />
      </div>
      <h2 className="text-xl font-semibold text-foreground">{title}</h2>
    </div>
    <div className="pl-12 space-y-3 text-muted-foreground leading-relaxed">{children}</div>
  </section>
);

const SubSection = ({ title, children }: { title: string; children: React.ReactNode }) => (
  <div className="mb-4">
    <h3 className="font-semibold text-foreground mb-2">{title}</h3>
    {children}
  </div>
);

const Bullet = ({ children }: { children: React.ReactNode }) => (
  <li className="flex gap-2">
    <span className="text-primary mt-1 flex-shrink-0">•</span>
    <span>{children}</span>
  </li>
);

const PrivacyPolicy = () => {
  return (
    <div className="min-h-screen bg-background text-foreground">
      {/* Header */}
      <div className="border-b border-border bg-secondary/20 sticky top-0 z-10 backdrop-blur-sm">
        <div className="container px-4 sm:px-6 lg:px-8 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-full border-2 border-gold-subtle flex items-center justify-center">
              <Sparkles className="w-4 h-4 text-primary" />
            </div>
            <span className="font-display text-lg text-foreground">{APP_NAME}</span>
          </div>
          <Button variant="ghost" size="sm" asChild>
            <Link to="/" className="flex items-center gap-2 text-muted-foreground hover:text-foreground">
              <ArrowLeft className="w-4 h-4" />
              Back
            </Link>
          </Button>
        </div>
      </div>

      {/* Hero */}
      <div className="bg-gradient-to-b from-secondary/30 to-background py-12">
        <div className="container px-4 sm:px-6 lg:px-8 max-w-3xl mx-auto text-center">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20 mb-6">
            <Shield className="w-4 h-4 text-primary" />
            <span className="text-primary text-sm font-medium">Your privacy is our priority</span>
          </div>
          <h1 className="font-display text-3xl sm:text-4xl font-bold text-foreground mb-3">
            Privacy Policy
          </h1>
          <p className="text-muted-foreground text-sm">
            Effective date: <span className="font-medium text-foreground">{EFFECTIVE_DATE}</span>
          </p>
          <p className="mt-4 text-muted-foreground max-w-xl mx-auto text-sm leading-relaxed">
            {APP_NAME} is built on the principle that your personal data belongs to you. This policy
            explains exactly what we collect, how we use it, and the robust controls you have over it.
            We comply with GDPR, CCPA, CalOPPA, and COPPA.
          </p>
        </div>
      </div>

      {/* Body */}
      <div className="container px-4 sm:px-6 lg:px-8 max-w-3xl mx-auto py-12">

        <Section icon={Eye} title="1. Information We Collect">
          <SubSection title="1.1 Information You Provide">
            <ul className="space-y-2 mt-1">
              <Bullet><strong>Account data</strong> — name, email address, and (optionally) date of birth when you register.</Bullet>
              <Bullet><strong>Social sign-in data</strong> — if you sign in with Google or Apple, we receive only your name, email, and a provider-issued ID. We never receive or store your Google or Apple password.</Bullet>
              <Bullet><strong>Preferences &amp; questionnaire data</strong> — date preferences, dietary restrictions, activity preferences, location/neighbourhood, budget range, and similar inputs you provide to personalise date plans.</Bullet>
              <Bullet><strong>Partner-planning data</strong> — if you use the Partner Planning feature, the session is identified by a random UUID. We only link it to your account on your explicit action.</Bullet>
              <Bullet><strong>Memories</strong> — photos, captions, and dates you voluntarily add to your memory gallery.</Bullet>
              <Bullet><strong>Communications</strong> — if you contact support, the content of that message.</Bullet>
            </ul>
          </SubSection>
          <SubSection title="1.2 Information Collected Automatically">
            <ul className="space-y-2 mt-1">
              <Bullet><strong>Device &amp; app diagnostics</strong> — iOS version, app version, crash reports, and anonymised performance metrics. These are never linked to personally identifiable information.</Bullet>
              <Bullet><strong>Location</strong> — approximate city/region <em>only when you grant permission</em> to enable nearby venue recommendations. We do not collect precise GPS coordinates, and location data is never stored after the plan is generated.</Bullet>
              <Bullet><strong>Usage signals</strong> — in-app navigation events (e.g., which screens you visit) to improve UX. These are aggregated and anonymised before any analysis.</Bullet>
            </ul>
          </SubSection>
          <SubSection title="1.3 Information We Do Not Collect">
            <ul className="space-y-2 mt-1">
              <Bullet>Payment card numbers or full financial information (payments are processed by Apple / the App Store; we receive only transaction status).</Bullet>
              <Bullet>Social media passwords or OAuth refresh tokens from Google or Apple — we only hold the Supabase session token issued after a successful sign-in.</Bullet>
              <Bullet>Precise, real-time GPS tracks or location history.</Bullet>
              <Bullet>Data from minors under 17 years of age (see Section 9).</Bullet>
            </ul>
          </SubSection>
        </Section>

        <Section icon={Lock} title="2. How We Use Your Information">
          <p>We process your data only for the purposes described below, relying on the following legal bases (GDPR Art. 6):</p>
          <ul className="space-y-2 mt-3">
            <Bullet><strong>Service delivery (Contractual necessity)</strong> — generating personalised date plans, syncing your preferences across devices, loading your saved plans and memories.</Bullet>
            <Bullet><strong>Account management (Contractual necessity)</strong> — authenticating you, handling password resets, and ensuring data belongs to the correct account.</Bullet>
            <Bullet><strong>Safety &amp; security (Legitimate interest)</strong> — detecting and preventing fraud, abuse, and unauthorised access.</Bullet>
            <Bullet><strong>Legal compliance (Legal obligation)</strong> — responding to valid law-enforcement requests and complying with applicable law.</Bullet>
            <Bullet><strong>Product improvement (Legitimate interest, after anonymisation)</strong> — understanding aggregate feature usage to prioritise development. No individual-level profiling.</Bullet>
            <Bullet><strong>Marketing (Consent, where required)</strong> — promotional emails only if you have opted in. You can withdraw consent at any time.</Bullet>
          </ul>
          <p className="mt-3">
            We do <strong>not</strong> sell your personal data, use it for advertising profiling, or share it with data brokers.
          </p>
        </Section>

        <Section icon={Globe} title="3. How We Share Your Information">
          <SubSection title="3.1 Service Providers (Sub-processors)">
            <p>We share data with the following categories of processors under strict data-processing agreements:</p>
            <ul className="space-y-2 mt-2">
              <Bullet><strong>Supabase</strong> (database, authentication, storage) — hosted on AWS within the United States.</Bullet>
              <Bullet><strong>OpenAI</strong> — receives anonymised questionnaire data to generate date plan suggestions. No name, email, or account identifiers are sent. OpenAI's zero-retention API option is enabled where available.</Bullet>
              <Bullet><strong>Google (Places API)</strong> — receives a search query and approximate location to return venue suggestions. No user credentials or account data are sent.</Bullet>
              <Bullet><strong>Apple (App Store / StoreKit)</strong> — manages subscription status; we receive only a boolean "is subscribed" flag.</Bullet>
            </ul>
          </SubSection>
          <SubSection title="3.2 Legal Disclosures">
            <p>We may disclose your data when we have a good-faith belief it is required by law, court order, or to protect the rights and safety of our users or the public.</p>
          </SubSection>
          <SubSection title="3.3 Business Transfers">
            <p>If {COMPANY} is involved in a merger, acquisition, or asset sale, we will provide notice before your personal data is transferred and becomes subject to a different privacy policy. Any successor will be required to honour the commitments made here.</p>
          </SubSection>
          <SubSection title="3.4 Aggregated / Anonymised Data">
            <p>We may share aggregated, non-identifiable statistics (e.g., "most popular date categories by city") with third parties. This data cannot reasonably be used to identify you.</p>
          </SubSection>
        </Section>

        <Section icon={Shield} title="4. Data Security">
          <ul className="space-y-2">
            <Bullet><strong>Encryption in transit</strong> — all communication between the app and our servers uses TLS 1.2+ (HTTPS). HTTP is rejected for all production endpoints.</Bullet>
            <Bullet><strong>Encryption at rest</strong> — database rows, stored files (memories), and session tokens are encrypted at rest by Supabase's underlying AWS infrastructure (AES-256).</Bullet>
            <Bullet><strong>Keychain storage</strong> — on iOS, session tokens are stored in the device Keychain using Apple's hardware-backed secure enclave, not in UserDefaults or on-disk plaintext files.</Bullet>
            <Bullet><strong>Row-level security (RLS)</strong> — every Supabase database table is protected by Postgres Row-Level Security policies so that users can only read and write their own rows. Queries are rejected at the database level even if an attacker gains an API key.</Bullet>
            <Bullet><strong>Short-lived sessions</strong> — access tokens expire after one hour. Refresh tokens are rotated on every use and immediately invalidated on sign-out.</Bullet>
            <Bullet><strong>Social OAuth</strong> — Google and Apple sign-in use PKCE (Proof Key for Code Exchange), preventing interception or replay of authorisation codes.</Bullet>
            <Bullet><strong>No plaintext passwords</strong> — passwords are hashed with bcrypt by Supabase's auth service and never stored or transmitted in recoverable form.</Bullet>
            <Bullet><strong>Breach response</strong> — in the event of a data breach affecting personal data, we will notify affected users and relevant authorities within 72 hours where required by GDPR.</Bullet>
          </ul>
        </Section>

        <Section icon={UserCheck} title="5. Your Rights">
          <p>Depending on where you live, you have some or all of the following rights:</p>
          <ul className="space-y-2 mt-3">
            <Bullet><strong>Access</strong> — request a copy of the personal data we hold about you.</Bullet>
            <Bullet><strong>Rectification</strong> — correct inaccurate or incomplete data.</Bullet>
            <Bullet><strong>Erasure ("right to be forgotten")</strong> — request deletion of your account and all associated data. Available in-app via Profile → Delete Account, or by emailing us.</Bullet>
            <Bullet><strong>Portability</strong> — receive your data in a structured, machine-readable format (JSON).</Bullet>
            <Bullet><strong>Objection</strong> — object to processing based on legitimate interests or for direct marketing.</Bullet>
            <Bullet><strong>Restriction</strong> — request that we restrict processing while a dispute is resolved.</Bullet>
            <Bullet><strong>Withdraw consent</strong> — where processing is based on consent, withdraw it at any time without affecting prior lawful processing.</Bullet>
            <Bullet><strong>CCPA — Do Not Sell</strong> — California residents: we do not sell personal information. You may submit a "Do Not Sell" request and we will confirm compliance.</Bullet>
          </ul>
          <p className="mt-3">
            To exercise any right, email <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a>. We will respond within 30 days (CCPA) or one month (GDPR). We may need to verify your identity before fulfilling the request.
          </p>
        </Section>

        <Section icon={Bell} title="6. Data Retention">
          <ul className="space-y-2">
            <Bullet><strong>Active accounts</strong> — we retain your data for as long as your account is active and for up to 12 months after your last login to allow reactivation.</Bullet>
            <Bullet><strong>Deleted accounts</strong> — upon account deletion, all personally identifiable data (profile, preferences, saved plans, memories) is permanently purged from production databases within 30 days. Anonymised, aggregated data derived from your usage may be retained indefinitely.</Bullet>
            <Bullet><strong>Backups</strong> — encrypted database backups may contain your data for up to 90 days after deletion, after which they are overwritten.</Bullet>
            <Bullet><strong>Legal hold</strong> — we may retain data longer if required by law or to resolve a dispute.</Bullet>
          </ul>
        </Section>

        <Section icon={Globe} title="7. International Data Transfers">
          <p>
            {APP_NAME} is operated from the United States. If you access the app from the European Economic Area, United Kingdom, or other regions with data-protection laws, your data will be transferred to and processed in the United States.
          </p>
          <p className="mt-2">
            For transfers from the EEA, we rely on the EU–US Data Privacy Framework and Standard Contractual Clauses (SCCs) with sub-processors (Supabase, OpenAI) to ensure an adequate level of protection.
          </p>
        </Section>

        <Section icon={UserCheck} title="8. Cookies & Tracking (Web App)">
          <ul className="space-y-2">
            <Bullet><strong>Strictly necessary cookies</strong> — session cookies used to keep you logged in. No consent required.</Bullet>
            <Bullet><strong>Functional cookies</strong> — remember UI preferences (e.g., theme). No consent required.</Bullet>
            <Bullet><strong>Analytics</strong> — we do not currently use third-party analytics or advertising cookies. If this changes, we will update this policy and request consent where required.</Bullet>
          </ul>
          <p className="mt-2">You can clear cookies at any time via your browser settings. The iOS app uses no browser cookies; sessions are stored in the Keychain.</p>
        </Section>

        <Section icon={Shield} title="9. Children's Privacy (COPPA)">
          <p>
            {APP_NAME} is designed for users aged 17 and older. We do not knowingly collect personal information from anyone under 17. If we learn that we have inadvertently collected data from a minor under 17, we will delete it immediately.
          </p>
          <p className="mt-2">
            If you believe your child has provided us personal information, please contact us at{" "}
            <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a>.
          </p>
        </Section>

        <Section icon={Bell} title="10. Changes to This Policy">
          <p>
            We may update this Privacy Policy from time to time. Material changes will be communicated via an in-app notification and/or email at least 14 days before they take effect. The updated policy will also be published at <code className="bg-secondary/50 px-1 rounded text-sm">yourdategenie.com/privacy-policy</code> with a new effective date.
          </p>
          <p className="mt-2">Your continued use of the app after the effective date constitutes acceptance of the updated policy.</p>
        </Section>

        <Section icon={Mail} title="11. Contact & Data Protection Officer">
          <p>For privacy-related questions, access requests, or complaints:</p>
          <div className="mt-3 p-4 rounded-lg border border-border bg-secondary/20 space-y-1 text-sm">
            <p className="font-semibold text-foreground">{COMPANY}</p>
            <p>Privacy &amp; Data Protection</p>
            <p>
              Email:{" "}
              <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a>
            </p>
          </div>
          <p className="mt-3">
            EU/EEA residents have the right to lodge a complaint with their local supervisory authority (e.g., the Irish Data Protection Commission) if they believe their data has been processed unlawfully. We ask that you contact us first so we can try to resolve the issue.
          </p>
        </Section>

        {/* Divider + navigation */}
        <div className="mt-16 pt-8 border-t border-border flex flex-col sm:flex-row items-center justify-between gap-4 text-sm text-muted-foreground">
          <p>© {new Date().getFullYear()} {COMPANY}. All rights reserved.</p>
          <div className="flex items-center gap-6">
            <Link to="/terms" className="hover:text-foreground transition-colors">Terms of Service</Link>
            <Link to="/" className="hover:text-foreground transition-colors">Home</Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PrivacyPolicy;
