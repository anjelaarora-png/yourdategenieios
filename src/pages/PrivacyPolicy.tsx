import { useEffect } from "react";
import { Link } from "react-router-dom";
import {
  Sparkles,
  ArrowLeft,
  Shield,
  Lock,
  Eye,
  UserCheck,
  Globe,
  Bell,
  Mail,
  Database,
  Cpu,
  FileText,
} from "lucide-react";
import { Button } from "@/components/ui/button";

const EFFECTIVE_DATE = "May 27, 2026";
const LAST_UPDATED = "May 27, 2026";
const CONTACT_EMAIL = "hello@yourdategenie.com";
const APP_NAME = "Your Date Genie";
const COMPANY = "Your Date Genie LLC";

const Section = ({
  icon: Icon,
  title,
  children,
}: {
  icon: React.ElementType;
  title: string;
  children: React.ReactNode;
}) => (
  <section className="mb-10">
    <div className="flex items-center gap-3 mb-4">
      <div className="w-9 h-9 rounded-full bg-primary/10 border border-primary/20 flex items-center justify-center flex-shrink-0">
        <Icon className="w-4 h-4 text-primary" />
      </div>
      <h2 className="text-xl font-semibold text-foreground">{title}</h2>
    </div>
    <div className="pl-12 space-y-3 text-muted-foreground leading-relaxed">
      {children}
    </div>
  </section>
);

const SubSection = ({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) => (
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

const TableRow = ({
  category,
  examples,
  purpose,
  retention,
}: {
  category: string;
  examples: string;
  purpose: string;
  retention: string;
}) => (
  <tr className="border-b border-border">
    <td className="py-3 pr-4 font-medium text-foreground text-sm align-top">{category}</td>
    <td className="py-3 pr-4 text-muted-foreground text-sm align-top">{examples}</td>
    <td className="py-3 pr-4 text-muted-foreground text-sm align-top">{purpose}</td>
    <td className="py-3 text-muted-foreground text-sm align-top">{retention}</td>
  </tr>
);

const PrivacyPolicy = () => {
  useEffect(() => {
    document.title = `Privacy Policy | ${APP_NAME}`;
  }, []);

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
            <span className="text-primary text-sm font-medium">Your data, your control</span>
          </div>
          <h1 className="font-display text-3xl sm:text-4xl font-bold text-foreground mb-3">
            Privacy Policy
          </h1>
          <p className="text-muted-foreground text-sm">
            Effective:{" "}
            <span className="font-medium text-foreground">{EFFECTIVE_DATE}</span>
            {" · "}Last updated:{" "}
            <span className="font-medium text-foreground">{LAST_UPDATED}</span>
          </p>
          <p className="mt-4 text-muted-foreground max-w-xl mx-auto text-sm leading-relaxed">
            {COMPANY} ("Company," "we," "us," "our") operates the {APP_NAME} iOS application
            and the website at yourdategenie.com (collectively, the "Service"). This Privacy
            Policy explains what personal data we collect about you, how we use and share it,
            how we protect it, and the choices and rights available to you. We comply with the
            EU General Data Protection Regulation (GDPR), California Consumer Privacy Act
            (CCPA) as amended by the California Privacy Rights Act (CPRA), CalOPPA, and
            the Children's Online Privacy Protection Act (COPPA).
          </p>
          <p className="mt-3 text-muted-foreground max-w-xl mx-auto text-sm font-medium">
            We do not sell your personal data. We do not use your data to train AI models. We do not serve you third-party ads.
          </p>
        </div>
      </div>

      {/* Body */}
      <div className="container px-4 sm:px-6 lg:px-8 max-w-3xl mx-auto py-12">

        {/* 1. Information We Collect */}
        <Section icon={Eye} title="1. Personal Data We Collect">
          <p>
            We collect personal data in three ways: data you actively provide, data generated
            by your use of the Service, and (where applicable) data received from third-party
            sign-in providers.
          </p>

          <SubSection title="1.1 Data You Provide Directly">
            <ul className="space-y-2 mt-1">
              <Bullet>
                <strong>Account registration data</strong> — name, email address, and (optionally)
                a profile photo when you register. If you sign up via Google or Apple, we receive
                only the name, email address, and provider-issued identifier shared by that provider.
                We never receive your Google or Apple password.
              </Bullet>
              <Bullet>
                <strong>Date-planning preferences</strong> — city, neighbourhood, dietary
                restrictions, food allergies, activity preferences, budget range, energy level,
                relationship stage, partner interests, occasion type, transportation mode, and
                other inputs you provide to generate a personalised date plan. This data is
                pseudonymous: it is used to call our AI service but is not labelled with your
                name or email address when transmitted to OpenAI (see Section 3).
              </Bullet>
              <Bullet>
                <strong>Love Note content</strong> — the raw text you type when using the Love
                Note rewrite feature. This text is transmitted to OpenAI to generate a rewritten
                version; it is not stored beyond the duration of the API call.
              </Bullet>
              <Bullet>
                <strong>Partner Planning data</strong> — if you invite someone to a Couple Plan
                session, we store a session record linking both accounts. Each participant's
                preferences are accessible to the other within the session only; see Section 3.4.
              </Bullet>
              <Bullet>
                <strong>Memory Gallery</strong> — photos, captions, and dates you voluntarily
                add to preserve memories of past dates. Photos are stored encrypted in our
                cloud storage (Supabase / AWS S3) and are accessible only by your account.
              </Bullet>
              <Bullet>
                <strong>Waitlist data (pre-launch)</strong> — if you joined the waitlist before
                public launch, we collected your name, email, city, and (optionally) phone
                number via Firebase Firestore. This data is migrated to Supabase upon launch
                and deleted from Firebase within 30 days of public release.
              </Bullet>
              <Bullet>
                <strong>Support communications</strong> — the content of any message you send
                to our support team, used solely to resolve your inquiry.
              </Bullet>
            </ul>
          </SubSection>

          <SubSection title="1.2 Data Generated Automatically">
            <ul className="space-y-2 mt-1">
              <Bullet>
                <strong>Device and app diagnostics</strong> — iOS version, app version, device
                model, crash logs, and anonymised performance metrics. These are never linked
                to your name or email in our analytics systems.
              </Bullet>
              <Bullet>
                <strong>Location data</strong> — approximate city or region (coarse location),
                and only when you grant location permission in iOS Settings. We use this to
                refine venue suggestions in your area. We do not collect or store precise GPS
                coordinates (latitude/longitude), and location data is discarded after a plan
                is generated; it is not retained in your profile.
              </Bullet>
              <Bullet>
                <strong>Usage signals</strong> — which in-app screens you navigate to and which
                features you use, collected in aggregate and anonymised form. We use this to
                improve UX; we do not build individual behavioural profiles for advertising.
              </Bullet>
              <Bullet>
                <strong>Web analytics</strong> — if you visit yourdategenie.com, we collect
                page-level analytics via Plausible Analytics, a privacy-respecting tool that
                does not use cookies, does not fingerprint your device, and does not share
                data with advertising networks.
              </Bullet>
            </ul>
          </SubSection>

          <SubSection title="1.3 Data We Expressly Do Not Collect">
            <ul className="space-y-2 mt-1">
              <Bullet>Payment card numbers, bank account details, or any full financial information. All payments are processed by Apple; we receive only a transaction status confirmation ("subscribed / not subscribed").</Bullet>
              <Bullet>Precise, continuous, or historical GPS location.</Bullet>
              <Bullet>Social-media passwords, OAuth refresh tokens, or access tokens from Google or Apple — we hold only the Supabase session token issued after a successful sign-in.</Bullet>
              <Bullet>Biometric data, health data, or any data from the "special categories" listed in GDPR Article 9.</Bullet>
              <Bullet>Personal data from persons under 17 years of age (see Section 10).</Bullet>
              <Bullet>Device Advertising Identifier (IDFA) — we do not serve third-party ads and do not request tracking permission (NSUserTrackingUsageDescription).</Bullet>
            </ul>
          </SubSection>
        </Section>

        {/* 2. Data Processing Table */}
        <Section icon={Database} title="2. How We Use Your Data — Legal Bases & Purposes">
          <p>
            We process personal data only for specific, documented purposes. The table below
            identifies each processing activity, its legal basis under GDPR Article 6, and
            the equivalent CCPA business purpose.
          </p>
          <div className="mt-4 overflow-x-auto -mx-4 px-4">
            <table className="w-full text-sm min-w-[600px]">
              <thead>
                <tr className="border-b-2 border-border">
                  <th className="text-left py-2 pr-4 font-semibold text-foreground">Processing Activity</th>
                  <th className="text-left py-2 pr-4 font-semibold text-foreground">Data Used</th>
                  <th className="text-left py-2 pr-4 font-semibold text-foreground">GDPR Legal Basis</th>
                  <th className="text-left py-2 font-semibold text-foreground">Retention</th>
                </tr>
              </thead>
              <tbody>
                <TableRow
                  category="Account creation & authentication"
                  examples="Name, email, provider ID"
                  purpose="Contractual necessity"
                  retention="Life of account + 30 days post-deletion"
                />
                <TableRow
                  category="Generate AI date plans"
                  examples="Anonymised preferences, city"
                  purpose="Contractual necessity"
                  retention="Preferences: life of account. Transmitted to OpenAI: not retained by OpenAI (zero-retention API)"
                />
                <TableRow
                  category="Rewrite Love Notes"
                  examples="Raw note text"
                  purpose="Contractual necessity"
                  retention="Not stored after API call completes"
                />
                <TableRow
                  category="Memory Gallery storage"
                  examples="Photos, captions"
                  purpose="Contractual necessity / consent"
                  retention="Until deleted by user or account deletion + 30 days"
                />
                <TableRow
                  category="Subscription management"
                  examples="Apple transaction ID, subscription status"
                  purpose="Contractual necessity"
                  retention="5 years (tax / accounting obligation)"
                />
                <TableRow
                  category="Safety, fraud & abuse prevention"
                  examples="Device diagnostics, usage anomalies"
                  purpose="Legitimate interest"
                  retention="90 days rolling"
                />
                <TableRow
                  category="Product analytics (aggregate)"
                  examples="Anonymised usage events"
                  purpose="Legitimate interest"
                  retention="Aggregated indefinitely; individual events 90 days"
                />
                <TableRow
                  category="Transactional email"
                  examples="Email address"
                  purpose="Contractual necessity"
                  retention="Life of account"
                />
                <TableRow
                  category="Marketing email"
                  examples="Email address"
                  purpose="Consent"
                  retention="Until you withdraw consent or unsubscribe"
                />
                <TableRow
                  category="Legal compliance & law enforcement"
                  examples="As required by law"
                  purpose="Legal obligation"
                  retention="As required by applicable law"
                />
              </tbody>
            </table>
          </div>
          <p className="mt-4 text-sm">
            We do not use automated decision-making or profiling that produces legal or similarly
            significant effects on you, within the meaning of GDPR Article 22.
          </p>
        </Section>

        {/* 3. Sharing */}
        <Section icon={Globe} title="3. How We Share Your Data">
          <SubSection title="3.1 Sub-processors (Service Providers)">
            <p>
              We share personal data with the following categories of vendors under written
              data-processing agreements that prohibit them from using your data for their own
              purposes:
            </p>
            <ul className="space-y-2 mt-2">
              <Bullet>
                <strong>Supabase, Inc.</strong> (database, authentication, storage, Edge Functions) —
                hosted on AWS in the United States. Supabase processes your account data, preferences,
                saved plans, and Memory Gallery photos on our behalf. EU/EEA transfers rely on
                Standard Contractual Clauses (SCCs).
              </Bullet>
              <Bullet>
                <strong>OpenAI, L.L.C.</strong> (AI generation) — receives anonymised date-preference
                data and Love Note text to generate content. No name, email address, or account
                identifier is transmitted. OpenAI's zero-data-retention API option is enabled where
                available. Your data is not used by OpenAI to train its models under our API agreement.
                OpenAI is a sub-processor within the meaning of GDPR Article 28.
              </Bullet>
              <Bullet>
                <strong>Google LLC</strong> (Places API) — receives a search-query string and
                approximate location to return venue suggestions. No account identifiers are
                transmitted to Google.
              </Bullet>
              <Bullet>
                <strong>Apple Inc.</strong> (App Store, StoreKit 2) — manages payment processing
                and subscription status. We receive only a boolean subscription-status signal ("active /
                inactive") and an opaque transaction identifier; we never receive your payment
                card number.
              </Bullet>
              <Bullet>
                <strong>Resend, Inc.</strong> (transactional email) — delivers welcome emails,
                account notifications, and support responses from us to you. Your email address
                is transmitted to Resend solely to facilitate delivery.
              </Bullet>
              <Bullet>
                <strong>Google LLC / Firebase</strong> (pre-launch waitlist only) — collected
                waitlist sign-ups before public launch. Waitlist data is migrated to Supabase
                and deleted from Firebase within 30 days of public release. Firebase is no
                longer used after migration.
              </Bullet>
              <Bullet>
                <strong>Plausible Analytics</strong> (website analytics) — collects cookie-free,
                aggregated page analytics on yourdategenie.com. No personal data or device
                fingerprints are shared with Plausible. Data is hosted in the EU.
              </Bullet>
            </ul>
          </SubSection>
          <SubSection title="3.2 Partner Planning — Member-to-Member Data Sharing">
            <p>
              When you participate in a Couple Plan session, your date preferences (venue type,
              budget tier, energy level, dietary needs, activity style) are visible to your
              linked partner within the active session only. Your name, email address, and
              account identifier are not shared with your partner unless you choose to disclose
              them outside the app. Session data is purged 90 days after the session closes or
              immediately upon account deletion by either participant.
            </p>
          </SubSection>
          <SubSection title="3.3 Legal Disclosures">
            <p>
              We may disclose personal data when we have a good-faith, documented belief that
              disclosure is required by: (a) applicable law, regulation, or legally binding
              court order; (b) a valid request from a governmental or law-enforcement authority
              with jurisdiction; or (c) to protect the rights, property, or safety of the
              Company, our Members, or the public. Where permitted by law, we will notify
              you before complying with such a request.
            </p>
          </SubSection>
          <SubSection title="3.4 Business Transfers">
            <p>
              If {COMPANY} is involved in a merger, acquisition, financing, restructuring, or
              sale of substantially all of its assets, your personal data may be transferred
              as part of that transaction. We will provide at least 30 days' advance notice
              via in-app notification and/or email before your data is subject to a materially
              different privacy policy. Any successor entity will be contractually required to
              honour the commitments made in this Policy.
            </p>
          </SubSection>
          <SubSection title="3.5 Aggregated & De-identified Data">
            <p>
              We may share aggregated, anonymised, and de-identified statistics (e.g., "top date
              categories by city this month") with third parties for business, research, or
              marketing purposes. This data is processed in a manner reasonably designed to
              prevent re-identification and does not constitute "personal data" under applicable
              law.
            </p>
          </SubSection>
          <SubSection title="3.6 What We Do Not Do">
            <ul className="space-y-2 mt-1">
              <Bullet><strong>We do not sell your personal data.</strong> "Sell" and "share" are used as defined in the CCPA/CPRA.</Bullet>
              <Bullet><strong>We do not share your data for cross-context behavioural advertising.</strong></Bullet>
              <Bullet><strong>We do not disclose your personal data to data brokers.</strong></Bullet>
              <Bullet><strong>We do not use your data to train or fine-tune any AI or machine-learning model.</strong></Bullet>
            </ul>
          </SubSection>
        </Section>

        {/* 4. AI Disclosure */}
        <Section icon={Cpu} title="4. Artificial Intelligence — Apple §5.1.2(i) Disclosure">
          <p>
            In compliance with Apple App Store Review Guidelines §5.1.2(i), we provide the
            following specific disclosures regarding our use of third-party AI:
          </p>
          <ul className="space-y-2 mt-3">
            <Bullet>
              <strong>Provider:</strong> OpenAI, L.L.C., 3180 18th Street, San Francisco, CA 94110, USA.
            </Bullet>
            <Bullet>
              <strong>Models used:</strong> GPT-4o and GPT-4o-mini (as of the effective date of this Policy; may be updated as OpenAI releases newer models).
            </Bullet>
            <Bullet>
              <strong>What data is sent:</strong> For date-plan generation — anonymised preference data (city, cuisine, budget, activity type, energy level, dietary restrictions, allergen list, occasion, duration). For Love Notes — the raw text you type. <em>Your name, email, Apple ID, Supabase user ID, and any other account identifier are never sent to OpenAI.</em>
            </Bullet>
            <Bullet>
              <strong>Zero-data-retention:</strong> We use OpenAI's API under a zero-data-retention policy where available, meaning OpenAI does not store prompts or completions after the API call completes, and does not use them to train models.
            </Bullet>
            <Bullet>
              <strong>AI-Generated Content is not medical, legal, financial, or safety advice.</strong> You are solely responsible for independently verifying any venue, product, or suggestion before acting on it.
            </Bullet>
            <Bullet>
              <strong>Human review:</strong> AI-Generated Content is not reviewed by a human before delivery. If you believe a plan contains harmful, inaccurate, or inappropriate content, please report it via Settings → Report a Concern.
            </Bullet>
          </ul>
        </Section>

        {/* 5. Data Security */}
        <Section icon={Lock} title="5. Data Security">
          <p>
            We implement industry-standard technical and organisational security measures
            proportionate to the risk of processing. Our key controls include:
          </p>
          <ul className="space-y-2 mt-3">
            <Bullet>
              <strong>Encryption in transit:</strong> All communication between the app and our
              servers uses TLS 1.3 (HTTPS). HTTP is rejected at the infrastructure level.
            </Bullet>
            <Bullet>
              <strong>Encryption at rest:</strong> Database rows, stored files (Memory Gallery
              photos), and backup archives are encrypted at rest using AES-256, provided by
              Supabase's underlying AWS infrastructure.
            </Bullet>
            <Bullet>
              <strong>iOS Keychain storage:</strong> Session tokens are stored in the device
              Keychain with hardware-backed protection via Apple's Secure Enclave. We do not
              store session tokens in UserDefaults, NSUserDefaults, or unencrypted on-disk files.
            </Bullet>
            <Bullet>
              <strong>Row-Level Security (RLS):</strong> Every table in our Supabase (PostgreSQL)
              database is protected by RLS policies. Queries are rejected at the database engine
              level if a user attempts to read or write another user's rows, even with a valid
              API key.
            </Bullet>
            <Bullet>
              <strong>Short-lived access tokens:</strong> JWT access tokens expire after one hour.
              Refresh tokens are rotated on each use and immediately invalidated upon sign-out
              or account deletion.
            </Bullet>
            <Bullet>
              <strong>PKCE OAuth:</strong> Google and Apple Sign-In flows use Proof Key for Code
              Exchange (PKCE), preventing interception and replay of authorisation codes.
            </Bullet>
            <Bullet>
              <strong>No plaintext passwords:</strong> Passwords are hashed with bcrypt (cost factor ≥12)
              by Supabase Auth. We never store, log, or transmit passwords in recoverable form.
            </Bullet>
            <Bullet>
              <strong>Secret management:</strong> All API keys (OpenAI, Google Places) are stored
              exclusively in Supabase's encrypted server-side secret store and are never embedded
              in the iOS app binary or client-side JavaScript.
            </Bullet>
            <Bullet>
              <strong>Breach notification:</strong> In the event of a personal data breach, we
              will notify affected Members and relevant supervisory authorities within 72 hours
              of discovery, as required by GDPR Article 33. Notification will include the nature
              of the breach, categories of data affected, approximate number of individuals
              affected, likely consequences, and measures taken or proposed.
            </Bullet>
          </ul>
          <p className="mt-3">
            No security system is impenetrable. We cannot guarantee absolute security of your
            data transmitted over the internet or stored in our systems. You are responsible
            for maintaining the security of your account credentials.
          </p>
        </Section>

        {/* 6. Your Rights */}
        <Section icon={UserCheck} title="6. Your Privacy Rights">
          <SubSection title="6.1 Rights Available to All Members">
            <ul className="space-y-2 mt-1">
              <Bullet><strong>Access:</strong> Request a copy of the personal data we hold about you in a structured, commonly used, machine-readable format (JSON).</Bullet>
              <Bullet><strong>Rectification / Correction:</strong> Request that we correct inaccurate or incomplete personal data.</Bullet>
              <Bullet><strong>Erasure ("Right to Be Forgotten"):</strong> Request deletion of your account and all associated personal data. You can initiate this in-app via <strong>Profile → Settings → Delete Account</strong>. Production data is purged within 30 days; encrypted backup copies are overwritten within 90 days.</Bullet>
              <Bullet><strong>Restriction:</strong> Request that we restrict processing of your data while a dispute about its accuracy or our right to process it is being resolved.</Bullet>
              <Bullet><strong>Portability:</strong> Receive your personal data in a structured, machine-readable format and transmit it to another controller, where technically feasible.</Bullet>
              <Bullet><strong>Objection:</strong> Object to processing based on legitimate interests. We will cease such processing unless we demonstrate compelling legitimate grounds that override your interests, rights, and freedoms, or unless we need to process data for the establishment, exercise, or defence of legal claims.</Bullet>
              <Bullet><strong>Withdraw Consent:</strong> Where processing is based on your consent (e.g., marketing emails), withdraw it at any time by clicking "Unsubscribe" in any email or emailing us. Withdrawal does not affect the lawfulness of processing prior to withdrawal.</Bullet>
              <Bullet><strong>Opt-out of automated profiling:</strong> We do not engage in automated profiling with legal or similarly significant effects (GDPR Art. 22). No action is required.</Bullet>
            </ul>
          </SubSection>

          <SubSection title="6.2 California Residents — CCPA / CPRA Rights">
            <p>California residents have additional rights under the CCPA as amended by the CPRA:</p>
            <ul className="space-y-2 mt-2">
              <Bullet>
                <strong>Right to Know:</strong> Request disclosure of the categories and specific pieces of personal information collected about you in the preceding 12 months, the sources, the business purpose for collection, and the categories of third parties with whom we shared it.
              </Bullet>
              <Bullet>
                <strong>Right to Delete:</strong> Request deletion of personal information we have collected (subject to certain exceptions, including information necessary to complete a pending transaction, detect fraud, or comply with law).
              </Bullet>
              <Bullet>
                <strong>Right to Correct:</strong> Request correction of inaccurate personal information.
              </Bullet>
              <Bullet>
                <strong>Right to Opt-Out of Sale or Sharing:</strong> We do not sell or share personal information for cross-context behavioural advertising. This right is therefore satisfied by our practices. You may submit a request and we will confirm in writing.
              </Bullet>
              <Bullet>
                <strong>Right to Limit Use of Sensitive Personal Information:</strong> Under the CPRA, "sensitive personal information" includes precise geolocation, financial account details, contents of personal communications, and biometric data. We do not collect precise geolocation, financial account details, or biometric data. The text content of Love Notes may qualify as personal communications; we limit its use to generating the rewritten note and do not retain it.
              </Bullet>
              <Bullet>
                <strong>Right to Non-Discrimination:</strong> We will not discriminate against you — including by denying services, charging different prices, or providing a different level of service — for exercising any of your CCPA/CPRA rights.
              </Bullet>
              <Bullet>
                <strong>California Shine the Light (Cal. Civ. Code §1798.83):</strong> California residents may request information about our disclosure of personal information to third parties for their direct marketing purposes. We do not share personal information with third parties for their direct marketing purposes.
              </Bullet>
            </ul>
            <p className="mt-2">
              To exercise any California right, email{" "}
              <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a>{" "}
              with subject line "California Privacy Request." We will respond within 45 days (extendable by an additional 45 days with notice). We may verify your identity before fulfilling the request. You may designate an authorised agent; the agent must provide written proof of authorisation.
            </p>
          </SubSection>

          <SubSection title="6.3 EEA / UK / Swiss Residents — GDPR Rights">
            <p>
              If you are in the EEA, United Kingdom, or Switzerland, you may exercise any
              of the rights in Section 6.1 by emailing{" "}
              <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a>.
              We will respond within one calendar month (extendable by two additional months for
              complex requests). If you are not satisfied with our response, you have the right
              to lodge a complaint with your local supervisory authority:
            </p>
            <ul className="space-y-2 mt-2">
              <Bullet>EU residents: the supervisory authority in your Member State of residence (e.g., <a href="https://www.cnil.fr" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">CNIL</a> in France, <a href="https://www.bfdi.bund.de" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">BfDI</a> in Germany).</Bullet>
              <Bullet>UK residents: the <a href="https://ico.org.uk" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">Information Commissioner's Office (ICO)</a>.</Bullet>
              <Bullet>Swiss residents: the <a href="https://www.edoeb.admin.ch" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">Federal Data Protection and Information Commissioner (FDPIC)</a>.</Bullet>
            </ul>
          </SubSection>

          <SubSection title="6.4 Global Privacy Control (GPC)">
            <p>
              We honour Global Privacy Control signals on our website as an opt-out of the sale
              or sharing of personal information, consistent with applicable California law.
              If your browser transmits a GPC signal, we treat it as a valid "Do Not Sell or Share"
              request.
            </p>
          </SubSection>
        </Section>

        {/* 7. Data Retention */}
        <Section icon={Bell} title="7. Data Retention">
          <p>We retain personal data only as long as necessary for the purposes described in this Policy or as required by law:</p>
          <ul className="space-y-2 mt-3">
            <Bullet>
              <strong>Active account data</strong> (profile, preferences, saved plans, memories) —
              retained for the life of your account and for up to 12 months after your last login to
              allow reactivation upon request.
            </Bullet>
            <Bullet>
              <strong>Deleted account data</strong> — all personally identifiable data is permanently
              purged from production databases within <strong>30 days</strong> of account deletion.
              Encrypted database backups are overwritten within <strong>90 days</strong>.
            </Bullet>
            <Bullet>
              <strong>Love Note text</strong> — not retained after the API call to OpenAI completes.
            </Bullet>
            <Bullet>
              <strong>Couple Plan session data</strong> — purged 90 days after the session closes
              or immediately upon account deletion by either participant, whichever is earlier.
            </Bullet>
            <Bullet>
              <strong>Transaction and subscription records</strong> — retained for 5 years to
              comply with tax, accounting, and financial-regulation obligations.
            </Bullet>
            <Bullet>
              <strong>Support communications</strong> — retained for 2 years after the ticket closes,
              then deleted.
            </Bullet>
            <Bullet>
              <strong>Aggregated, anonymised analytics</strong> — retained indefinitely; individual
              event logs are anonymised after 90 days.
            </Bullet>
            <Bullet>
              <strong>Legal hold</strong> — we may retain data for longer periods if required to
              comply with applicable law, resolve a dispute, or enforce our agreements.
            </Bullet>
          </ul>
        </Section>

        {/* 8. International Transfers */}
        <Section icon={Globe} title="8. International Data Transfers">
          <p>
            {COMPANY} is based in the United States. If you access the Service from the
            European Economic Area, United Kingdom, Switzerland, or other jurisdictions with
            data-protection laws that restrict cross-border transfers, your personal data will
            be transferred to and processed in the United States.
          </p>
          <p className="mt-2">
            We rely on the following transfer mechanisms for EEA/UK/Swiss data:
          </p>
          <ul className="space-y-2 mt-2">
            <Bullet>
              <strong>EU Standard Contractual Clauses (SCCs)</strong> — incorporated into our
              data-processing agreements with Supabase, OpenAI, Resend, and other U.S.-based
              sub-processors.
            </Bullet>
            <Bullet>
              <strong>EU–U.S. Data Privacy Framework</strong> — for sub-processors that are
              certified under the Framework.
            </Bullet>
          </ul>
          <p className="mt-2">
            You may request a copy of the applicable SCCs by emailing{" "}
            <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a>.
          </p>
        </Section>

        {/* 9. Cookies & Tracking */}
        <Section icon={FileText} title="9. Cookies & Tracking Technologies">
          <SubSection title="9.1 iOS Application">
            <p>
              The {APP_NAME} iOS app does not use browser cookies. Session tokens are stored
              exclusively in the iOS Keychain using hardware-backed Secure Enclave protection.
              We do not request the App Tracking Transparency (ATT) permission
              (NSUserTrackingUsageDescription) because we do not serve third-party advertising
              or use cross-app tracking.
            </p>
          </SubSection>
          <SubSection title="9.2 Website (yourdategenie.com)">
            <ul className="space-y-2 mt-1">
              <Bullet>
                <strong>Strictly necessary cookies</strong> — session cookies to keep you
                authenticated while browsing the web app. These cannot be disabled without
                breaking core functionality.
              </Bullet>
              <Bullet>
                <strong>Functional cookies</strong> — remember UI preferences (e.g., theme
                selection). No consent required.
              </Bullet>
              <Bullet>
                <strong>Analytics</strong> — Plausible Analytics (cookie-free). No consent
                banner required; no personal data processed.
              </Bullet>
              <Bullet>
                <strong>Third-party advertising / tracking cookies</strong> — we do not use
                any. No Meta Pixel, Google Analytics, LinkedIn Insight Tag, or similar
                advertising-technology is present on our website.
              </Bullet>
            </ul>
            <p className="mt-2">
              You may clear cookies at any time via your browser settings. You can verify
              the absence of third-party trackers using browser extensions such as uBlock
              Origin or Privacy Badger.
            </p>
          </SubSection>
        </Section>

        {/* 10. Children */}
        <Section icon={Shield} title="10. Children's Privacy (COPPA)">
          <p>
            The Service is intended for persons who are at least <strong>17 years of age</strong>.
            We do not knowingly collect personal information from children under 13 years of
            age within the meaning of the Children's Online Privacy Protection Act (COPPA),
            and we do not knowingly collect personal information from any person under 17.
          </p>
          <p className="mt-2">
            If we learn or have reason to suspect that we have inadvertently collected personal
            data from a person under 17, we will promptly delete that data from all production
            systems. If you are a parent or legal guardian who believes your child under 17
            has submitted personal information to us, please contact us immediately at{" "}
            <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a>.
            We will investigate and delete the data within 10 business days.
          </p>
        </Section>

        {/* 11. Changes */}
        <Section icon={Bell} title="11. Changes to This Policy">
          <p>
            We may update this Privacy Policy as our data practices evolve or in response to
            changes in applicable law. We will distinguish between material and non-material changes:
          </p>
          <ul className="space-y-2 mt-3">
            <Bullet>
              <strong>Material changes</strong> (e.g., new categories of data collected, new
              third-party sub-processors, changes to your rights or the legal basis for
              processing) will be communicated via in-app notification and/or email at least
              <strong> 14 days</strong> before the change takes effect, along with a summary
              of what changed and why.
            </Bullet>
            <Bullet>
              <strong>Non-material changes</strong> (e.g., typographical corrections, improved
              clarity, updated sub-processor contact details that do not affect your rights)
              may take effect upon posting at{" "}
              <code className="bg-secondary/50 px-1 rounded text-sm">yourdategenie.com/privacy</code>{" "}
              with an updated effective date.
            </Bullet>
          </ul>
          <p className="mt-3">
            Your continued use of the Service after the effective date of a material change
            constitutes your acceptance of the updated Policy. If you do not agree, you must
            stop using the Service and delete your account before the effective date.
          </p>
        </Section>

        {/* 12. Contact */}
        <Section icon={Mail} title="12. Contact & Data Protection Inquiries">
          <p>
            For all privacy-related questions, data-rights requests, sub-processor inquiries,
            or to report a potential data breach:
          </p>
          <div className="mt-3 p-4 rounded-lg border border-border bg-secondary/20 space-y-1 text-sm">
            <p className="font-semibold text-foreground">{COMPANY}</p>
            <p>Privacy &amp; Data Protection</p>
            <p>
              Email:{" "}
              <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">
                {CONTACT_EMAIL}
              </a>
            </p>
            <p>Website: yourdategenie.com</p>
          </div>
          <p className="mt-3">
            <strong>Response timelines:</strong> We will acknowledge receipt within 5 business days and
            provide a substantive response within 30 calendar days (CCPA) or one calendar month (GDPR).
            Complex or numerous requests may be extended by a further two months with notice.
          </p>
          <p className="mt-3">
            <strong>Identity verification:</strong> To protect your privacy, we may ask you to verify
            your identity before fulfilling a data-rights request. We will not require you to create
            an account to submit a request, but we may need the email address associated with your
            account to locate your data.
          </p>
          <p className="mt-3">
            EU/EEA residents have the right to lodge a complaint with the supervisory authority
            in their Member State of habitual residence, place of work, or place of the alleged
            infringement. We ask that you contact us first so we have the opportunity to address
            your concern directly.
          </p>
        </Section>

        {/* Divider + navigation */}
        <div className="mt-16 pt-8 border-t border-border flex flex-col sm:flex-row items-center justify-between gap-4 text-sm text-muted-foreground">
          <p>© {new Date().getFullYear()} {COMPANY}. All rights reserved.</p>
          <div className="flex items-center gap-6">
            <Link to="/terms" className="hover:text-foreground transition-colors">Terms of Use</Link>
            <Link to="/" className="hover:text-foreground transition-colors">Home</Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PrivacyPolicy;
