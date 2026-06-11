import { Link } from "react-router-dom";
import { useEffect } from "react";
import {
  Sparkles,
  ArrowLeft,
  FileText,
  ShieldAlert,
  CreditCard,
  UserCheck,
  AlertTriangle,
  Scale,
  Globe,
  Mail,
  Users,
  Calendar,
  BookOpen,
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

const Terms = () => {
  useEffect(() => {
    document.title = `Terms of Use | ${APP_NAME}`;
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
            <FileText className="w-4 h-4 text-primary" />
            <span className="text-primary text-sm font-medium">
              Please read carefully before using the app
            </span>
          </div>
          <h1 className="font-display text-3xl sm:text-4xl font-bold text-foreground mb-3">
            Terms of Use
          </h1>
          <p className="text-muted-foreground text-sm">
            Effective:{" "}
            <span className="font-medium text-foreground">{EFFECTIVE_DATE}</span>
            {" · "}Last updated:{" "}
            <span className="font-medium text-foreground">{LAST_UPDATED}</span>
          </p>
          <p className="mt-4 text-muted-foreground max-w-xl mx-auto text-sm leading-relaxed">
            These Terms of Use ("Agreement") constitute a legally binding contract between
            you ("Member," "you," "your") and {COMPANY} ("Company," "we," "us," "our")
            governing your access to and use of the {APP_NAME} mobile application, website
            at yourdategenie.com, and all related services (collectively, the "Service").
            By creating an account or using the Service in any manner, you affirm that you
            have read, understood, and agree to be bound by this Agreement and our{" "}
            <Link to="/privacy" className="text-primary hover:underline">Privacy Policy</Link>,
            which is incorporated herein by reference. <strong>If you do not agree, do not use the Service.</strong>
          </p>
        </div>
      </div>

      {/* Body */}
      <div className="container px-4 sm:px-6 lg:px-8 max-w-3xl mx-auto py-12">

        {/* Definitions */}
        <Section icon={BookOpen} title="1. Definitions">
          <p>As used throughout this Agreement:</p>
          <ul className="space-y-2 mt-3">
            <Bullet><strong>"AI-Generated Content"</strong> means date plans, venue suggestions, gift ideas, love notes, conversation starters, and any other output produced by large language model APIs (currently OpenAI GPT-4 family) operated on our behalf.</Bullet>
            <Bullet><strong>"Couple Plan"</strong> means the premium feature enabling two Members to jointly generate and compare date plan options, also referred to as "Partner Planning."</Bullet>
            <Bullet><strong>"Free Tier"</strong> means the no-charge access tier subject to usage limits described in Section 4.</Bullet>
            <Bullet><strong>"In-App Purchase" or "IAP"</strong> means a subscription or one-time purchase transacted through the Apple App Store.</Bullet>
            <Bullet><strong>"Member"</strong> means any individual who creates an account with the Service.</Bullet>
            <Bullet><strong>"Premium Subscription"</strong> means the paid, auto-renewing subscription that unlocks unlimited AI-Generated Content and other premium features.</Bullet>
            <Bullet><strong>"Service"</strong> means the {APP_NAME} iOS application, the website at yourdategenie.com, all related backend services, APIs, and Edge Functions.</Bullet>
            <Bullet><strong>"User Content"</strong> means text, photos, captions, and other content uploaded or created by a Member, including memories, notes, and customised date plan titles.</Bullet>
          </ul>
        </Section>

        {/* 2. Acceptance & Eligibility */}
        <Section icon={UserCheck} title="2. Eligibility & Account Registration">
          <SubSection title="2.1 Age Requirement">
            <p>
              The Service is intended for persons who are at least <strong>17 years of age</strong>. By creating an account, you represent and warrant that you are 17 or older. We reserve the right to terminate accounts and delete data of Members discovered to be under age without prior notice and without refund. If you are the parent or guardian of a minor who has created an account, contact us immediately at{" "}
              <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a>.
            </p>
          </SubSection>
          <SubSection title="2.2 Legal Capacity">
            <p>
              You represent that you have full legal capacity to enter into this Agreement. If you are acting on behalf of a business entity, you represent that you are authorised to bind that entity to this Agreement, in which case "you" refers to that entity.
            </p>
          </SubSection>
          <SubSection title="2.3 Account Accuracy & Security">
            <ul className="space-y-2 mt-1">
              <Bullet>You agree to provide accurate, current, and complete information at registration and to keep it updated promptly.</Bullet>
              <Bullet>You are solely responsible for maintaining the confidentiality of your credentials and for all activity that occurs under your account, whether or not authorised by you.</Bullet>
              <Bullet>You must notify us immediately at{" "}<a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a>{" "}upon discovering any unauthorised access to your account.</Bullet>
              <Bullet>You may not share your account credentials, create accounts on behalf of others, or maintain multiple accounts to circumvent subscription limits, free-trial restrictions, or account bans.</Bullet>
            </ul>
          </SubSection>
          <SubSection title="2.4 Account Deletion — Apple §5.1.1(v)">
            <p>
              In compliance with Apple App Store Review Guidelines §5.1.1(v), Members may permanently delete their account and all associated personal data at any time by navigating to <strong>Profile → Settings → Delete Account</strong> within the app. Account deletion is irreversible, and all User Content, saved plans, memories, and preference data will be permanently purged from production databases within 30 days. Encrypted backups are overwritten within 90 days. Deletion does not entitle you to a refund of any prepaid subscription fees (see Section 4.8).
            </p>
          </SubSection>
        </Section>

        {/* 3. The Service */}
        <Section icon={FileText} title="3. The Service & AI-Generated Content">
          <SubSection title="3.1 Nature of the Service">
            <p>
              {APP_NAME} is an AI-assisted date-planning concierge. It generates personalised date itineraries, venue suggestions, gift recommendations, love notes, conversation starters, playlist ideas, and memory-storage functionality for couples. The Service is designed as an <em>inspirational planning tool</em> only. We do not make reservations, purchase goods, or guarantee any particular romantic outcome on your behalf.
            </p>
          </SubSection>
          <SubSection title="3.2 AI Disclosure — Apple §5.1.2(i)">
            <p>
              In compliance with Apple App Store Review Guidelines §5.1.2(i), we disclose that the Service uses third-party artificial intelligence technology. Specifically:
            </p>
            <ul className="space-y-2 mt-2">
              <Bullet><strong>Provider:</strong> OpenAI, L.L.C. ("OpenAI"), via its GPT-4 family of large language models.</Bullet>
              <Bullet><strong>What is sent to OpenAI:</strong> anonymised date-preference data (city, cuisine, budget, activity type, energy level, dietary restrictions) and, for Love Notes, the raw text you provide. No name, email address, Apple ID, or other account identifier is transmitted to OpenAI.</Bullet>
              <Bullet><strong>OpenAI's policies:</strong> data transmitted to OpenAI is subject to OpenAI's{" "}<a href="https://openai.com/policies/usage-policies" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">Usage Policies</a>{" "}and API data-handling terms. We have enabled OpenAI's zero-data-retention API option where available.</Bullet>
              <Bullet><strong>We do not use your data to train AI models.</strong> Your preferences and User Content are not used to train or fine-tune any machine-learning model, by us or any sub-processor.</Bullet>
            </ul>
          </SubSection>
          <SubSection title="3.3 Accuracy Disclaimer">
            <p>
              AI-Generated Content is produced by statistical language models and <strong>may be inaccurate, outdated, or inappropriate for your specific circumstances.</strong> Specific known limitations:
            </p>
            <ul className="space-y-2 mt-2">
              <Bullet><strong>Venue hallucination.</strong> The AI may suggest venues that have closed, relocated, changed their menus, or do not exist at the address stated. Always verify directly with the venue before attending.</Bullet>
              <Bullet><strong>Allergy and dietary risk.</strong> While we prompt the AI to respect stated allergies and dietary restrictions, AI-Generated Content is not a substitute for direct confirmation with the venue. You assume sole responsibility for verifying that any venue or product is safe for your needs.</Bullet>
              <Bullet><strong>No guarantee of romantic outcome.</strong> We do not warranty the quality of your date experience, your partner's satisfaction, or any romantic, emotional, or interpersonal result.</Bullet>
              <Bullet><strong>Third-party pricing.</strong> Prices, hours, reservation availability, and menu offerings are subject to change without notice. The Company is not responsible for discrepancies between AI-Generated Content and real-world conditions.</Bullet>
            </ul>
          </SubSection>
          <SubSection title="3.4 Third-Party Integrations">
            <p>
              The Service integrates with third-party providers including OpenAI, Google Places API, Apple StoreKit 2, Supabase, Resend, and Apple Maps. Use of the Service does not create any relationship between you and those third-party providers. Each provider's own terms of service and privacy policies apply to their respective services. We are not liable for third-party service failures, data breaches, discontinuations, or policy changes.
            </p>
          </SubSection>
          <SubSection title="3.5 Service Availability">
            <p>
              We target high availability but do not guarantee that the Service will be uninterrupted, error-free, or available in all geographic regions. We may temporarily suspend all or part of the Service for maintenance, security incidents, regulatory requirements, or force majeure events, with or without advance notice.
            </p>
          </SubSection>
        </Section>

        {/* 4. Subscriptions & Payments */}
        <Section icon={CreditCard} title="4. Subscriptions, Payments & Auto-Renewal">
          <SubSection title="4.1 Free Tier">
            <p>
              The Service includes a no-charge access tier. Free Members may generate up to <strong>3 AI date plans per calendar month</strong> and save up to <strong>5 plans</strong> at any time. Free-tier limits are subject to change; changes will be communicated with at least 14 days' notice.
            </p>
          </SubSection>
          <SubSection title="4.2 Premium Subscription — Pricing">
            <p>
              Premium features require an auto-renewing subscription purchased through the Apple App Store. Current U.S. pricing:
            </p>
            <ul className="space-y-2 mt-2">
              <Bullet><strong>Monthly Plan:</strong> $14.99 per month, billed monthly.</Bullet>
              <Bullet><strong>Annual Plan:</strong> $99.99 per year (equivalent to approximately $8.33/month).</Bullet>
            </ul>
            <p className="mt-2">
              Prices are displayed in U.S. Dollars and may vary by country due to App Store regional pricing. The price confirmed to you in the App Store at the time of purchase is the binding price for that billing period.
            </p>
          </SubSection>
          <SubSection title="4.3 Free Trial">
            <ul className="space-y-2 mt-1">
              <Bullet><strong>Duration:</strong> 7 days, commencing upon purchase confirmation by Apple.</Bullet>
              <Bullet><strong>No charge during trial:</strong> You will not be charged during the 7-day trial period provided you cancel before the trial expires.</Bullet>
              <Bullet><strong>Cancellation to avoid charge:</strong> You must cancel at least 24 hours before the end of the trial period to avoid being charged. Cancellation instructions are in Section 4.6.</Bullet>
              <Bullet><strong>Trial eligibility:</strong> Free trials are available only to new subscribers. Apple may limit trial offers to accounts that have not previously subscribed to the same product.</Bullet>
            </ul>
          </SubSection>
          <SubSection title="4.4 Auto-Renewal Disclosure — California SB-313 & Apple §3.1.2">
            <p className="font-semibold text-foreground">
              IMPORTANT — AUTOMATIC RENEWAL NOTICE:
            </p>
            <p className="mt-2">
              Your subscription will automatically renew at the end of each billing period (monthly or annually, depending on the plan you selected) at the then-current price unless you cancel at least 24 hours before the renewal date. Renewal charges your Apple ID account at the start of each renewal period. We will provide advance notice of any price increase before your subscription renews at the new price. Your continued use of the Service following such notice constitutes consent to the increased price.
            </p>
            <p className="mt-2">
              <strong>How to cancel:</strong> See Section 4.6. Apple manages all billing; we have no ability to charge you or issue refunds directly.
            </p>
          </SubSection>
          <SubSection title="4.5 Payment Processing">
            <ul className="space-y-2 mt-1">
              <Bullet>All payments are processed exclusively by Apple through the App Store. We do not receive, process, or store your payment card number, bank details, or any full financial account information.</Bullet>
              <Bullet>You authorise Apple to charge your Apple ID payment method at the confirmation of purchase and at the start of each renewal period.</Bullet>
              <Bullet>All transactions are subject to Apple's App Store Terms of Service.</Bullet>
            </ul>
          </SubSection>
          <SubSection title="4.6 Managing & Cancelling Your Subscription">
            <p>To cancel, you must do so through Apple — not through us. We have no ability to cancel your subscription on your behalf.</p>
            <ul className="space-y-2 mt-2">
              <Bullet><strong>On your iPhone or iPad:</strong> Open the Settings app → tap your Apple ID at the top → Subscriptions → tap "{APP_NAME}" → tap "Cancel Subscription." Cancellation takes effect at the end of the current paid period; you retain Premium access through that date.</Bullet>
              <Bullet><strong>On a Mac:</strong> Open the App Store → click your name → Account Settings → Subscriptions → tap "{APP_NAME}" → Cancel.</Bullet>
              <Bullet><strong>Via Apple support:</strong> Visit <a href="https://support.apple.com" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">support.apple.com</a> or call Apple at 1-800-MY-APPLE.</Bullet>
            </ul>
            <p className="mt-2">
              Cancellation is prospective only. No partial-period refunds are issued. You will retain access to Premium features until the end of the current paid billing period.
            </p>
          </SubSection>
          <SubSection title="4.7 Restore Purchases">
            <p>
              If you reinstall the app, switch devices, or lose access to your Premium features, you may restore your existing subscription via <strong>Settings → Restore Purchases</strong> within the app. Restoration verifies your active subscription with Apple's servers at no charge.
            </p>
          </SubSection>
          <SubSection title="4.8 Refund Policy">
            <p>
              Refunds for App Store purchases are governed exclusively by Apple's refund policy. We have no authority to issue refunds directly. To request a refund, visit{" "}
              <a href="https://reportaproblem.apple.com" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">reportaproblem.apple.com</a>{" "}
              within 90 days of the charge. Deleting your account while subscribed does not entitle you to a refund of any prepaid subscription fees except to the extent permitted by Apple's refund policy.
            </p>
          </SubSection>
          <SubSection title="4.9 Price Changes">
            <p>
              We may change subscription pricing with at least 30 days' advance notice delivered via in-app notification and/or email. If you do not cancel before the effective date of a price increase, you consent to the new price. If you reside in a jurisdiction where such consent is legally insufficient, we will obtain separate explicit consent before billing you at the new price.
            </p>
          </SubSection>
        </Section>

        {/* 5. User Conduct */}
        <Section icon={UserCheck} title="5. Member Conduct & Acceptable Use">
          <p>
            You agree to use the Service lawfully and in a manner consistent with these Terms. Without limiting the foregoing, you expressly agree <strong>not</strong> to:
          </p>
          <ul className="space-y-2 mt-3">
            <Bullet>Use the Service for any purpose that is unlawful, fraudulent, deceptive, harassing, threatening, defamatory, obscene, or invasive of another's privacy.</Bullet>
            <Bullet>Reverse-engineer, decompile, disassemble, or attempt to derive the source code of any portion of the Service; circumvent, disable, or otherwise interfere with security features, rate limits, subscription enforcement, or access controls.</Bullet>
            <Bullet>Use automated scripts, bots, crawlers, or other programmatic means to access, scrape, index, or harvest data from the Service without our prior written consent.</Bullet>
            <Bullet>Upload, post, or transmit content that is illegal, infringes any third-party intellectual-property right, contains malware or malicious code, or violates any applicable export-control law.</Bullet>
            <Bullet>Use AI-Generated Content to facilitate stalking, harassment, non-consensual surveillance, or harm to another individual.</Bullet>
            <Bullet>Impersonate any person, entity, or {COMPANY} representative, or falsely claim an affiliation with any person or entity.</Bullet>
            <Bullet>Create or use multiple accounts to circumvent subscription limits, exploit free-trial offers, evade account bans, or otherwise manipulate the Service.</Bullet>
            <Bullet>Use the Couple Plan or Partner Planning feature without the other person's fully informed, freely given consent.</Bullet>
            <Bullet>Resell, sublicense, commercially redistribute, or create derivative products from AI-Generated Content, venue recommendation lists, gift suggestions, or love notes generated by the Service.</Bullet>
            <Bullet>Transmit unsolicited commercial communications ("spam") to other Members or through any Service feature.</Bullet>
            <Bullet>Interfere with or disrupt the integrity or performance of the Service or any infrastructure connected thereto.</Bullet>
          </ul>
          <p className="mt-3">
            Violation of this Section may result in immediate account suspension or permanent termination without notice. We reserve the right to cooperate with law enforcement authorities in connection with any investigation of suspected unlawful activity.
          </p>
        </Section>

        {/* 6. Partner Planning / Couple Plan */}
        <Section icon={Users} title="6. Partner Planning & Couple Plan">
          <SubSection title="6.1 Feature Description">
            <p>
              The Couple Plan (also called Partner Planning) is a premium feature that allows two Members to independently complete a date-preferences questionnaire, compare AI-Generated plan options, and co-select a mutually preferred itinerary. Both Members must have separately created accounts; the feature cannot be activated unilaterally.
            </p>
          </SubSection>
          <SubSection title="6.2 Consent Requirement">
            <p>
              <strong>You represent and warrant that any individual you invite to a Couple Plan session has provided freely given, specific, informed, and unambiguous consent to participate.</strong> You must not use the feature to:
            </p>
            <ul className="space-y-2 mt-2">
              <Bullet>Invite a person without their prior knowledge and agreement;</Bullet>
              <Bullet>Access, collect, or infer personal information about another individual without their consent;</Bullet>
              <Bullet>Facilitate surveillance, monitoring, or control of another person.</Bullet>
            </ul>
            <p className="mt-2">
              Misuse of this feature to deceive, manipulate, stalk, or coerce another person may constitute a violation of applicable anti-stalking, harassment, or computer-fraud laws. We reserve the right to terminate your account and report such activity to law enforcement.
            </p>
          </SubSection>
          <SubSection title="6.3 Data Sharing Within a Session">
            <ul className="space-y-2 mt-1">
              <Bullet>Your partner sees a <em>summary</em> of your stated date preferences (e.g., cuisine, budget tier, energy level, vibe) within the active session — not your name, email, or other account identifiers — unless you are both actively participating in the same session and have been mutually verified.</Bullet>
              <Bullet>Session data is stored in our Supabase database and automatically purged 90 days after the session closes, or immediately upon account deletion by either participant.</Bullet>
              <Bullet>Either Member may unlink the Couple Plan relationship at any time via Settings → Partner → Unlink. Unlinking prevents future invitations from the unlinked account.</Bullet>
            </ul>
          </SubSection>
          <SubSection title="6.4 Reporting & Blocking">
            <p>
              In accordance with Apple App Store Review Guidelines §1.2, any Member may report a concern or block another Member via <strong>Settings → Report a Concern</strong>. Blocked Members cannot send new Couple Plan invitations to the blocking Member. All reports are reviewed within 48 hours. See our{" "}
              <a href="https://yourdategenie.com/safety" className="text-primary hover:underline">Safety page</a>{" "}for more information.
            </p>
          </SubSection>
        </Section>

        {/* 7. User Content */}
        <Section icon={FileText} title="7. User Content & Memory Gallery">
          <SubSection title="7.1 Your Ownership">
            <p>
              You retain all intellectual-property rights in User Content you create or upload — including photos in your Memory Gallery, captions, notes, and personalised date plan modifications. Nothing in this Agreement transfers ownership of your User Content to the Company.
            </p>
          </SubSection>
          <SubSection title="7.2 Licence Grant to Company">
            <p>
              By uploading or submitting User Content, you grant {COMPANY} a limited, non-exclusive, royalty-free, worldwide, sublicensable licence to host, store, reproduce, display, and transmit your User Content <em>solely</em> to the extent necessary to operate and provide the Service to you. This licence does not permit us to use your User Content for marketing, advertising, or AI-model training purposes without your separate, explicit written consent.
            </p>
          </SubSection>
          <SubSection title="7.3 Content Standards">
            <p>
              You represent and warrant that all User Content: (a) is owned by you or you have the right to grant the licence in Section 7.2; (b) does not violate any applicable law or regulation; (c) does not infringe any third-party intellectual-property, privacy, or publicity right; and (d) does not contain malicious code.
            </p>
          </SubSection>
          <SubSection title="7.4 Removal">
            <p>
              We reserve the right to remove or disable User Content that we reasonably believe violates these Terms, applicable law, or poses a risk to safety, without prior notice and without liability. We are not obligated to pre-screen User Content.
            </p>
          </SubSection>
        </Section>

        {/* 8. Intellectual Property */}
        <Section icon={Scale} title="8. Intellectual Property">
          <SubSection title="8.1 Company Ownership">
            <p>
              The Service — including its software, codebase, AI pipeline architecture, design system, graphics, trademarks, service marks, databases, and all Company-authored content ("Company IP") — is owned exclusively by {COMPANY} or its licensors and is protected by United States and international copyright, trademark, patent, and trade-secret law. These Terms do not transfer any ownership interest in Company IP to you.
            </p>
          </SubSection>
          <SubSection title="8.2 Limited Licence to Members">
            <p>
              Subject to your compliance with these Terms, we grant you a personal, non-exclusive, non-transferable, non-sublicensable, revocable, limited licence to: (a) install and use the iOS application on Apple-branded devices you own or control; and (b) access the web application at yourdategenie.com — in each case solely for your personal, non-commercial use in accordance with this Agreement.
            </p>
          </SubSection>
          <SubSection title="8.3 AI-Generated Content Ownership">
            <p>
              To the extent permitted by applicable law, {COMPANY} does not assert copyright over AI-Generated Content delivered to you. However, you may not commercially exploit, resell, or distribute AI-Generated Content at scale; such use is prohibited by Section 5.
            </p>
          </SubSection>
          <SubSection title="8.4 Feedback">
            <p>
              If you submit suggestions, ideas, or feedback about the Service ("Feedback"), you grant us an irrevocable, perpetual, royalty-free, worldwide licence to use and incorporate that Feedback without restriction or compensation to you.
            </p>
          </SubSection>
        </Section>

        {/* 9. Disclaimers & Limitation of Liability */}
        <Section icon={AlertTriangle} title="9. Disclaimers & Limitation of Liability">
          <SubSection title="9.1 Disclaimer of Warranties">
            <p className="font-semibold text-foreground uppercase text-sm">
              To the fullest extent permitted by applicable law, the Service is provided "as is" and "as available," without any warranty of any kind, express, implied, statutory, or otherwise, including without limitation any implied warranties of merchantability, fitness for a particular purpose, title, non-infringement, accuracy, reliability, or that the Service will be error-free, uninterrupted, or free of harmful components. We expressly disclaim all warranties with respect to AI-Generated Content, including without limitation any warranty that venue information is accurate, current, or safe; that romantic outcomes will be positive; or that AI suggestions are appropriate for your specific circumstances.
            </p>
            <p className="mt-2">Some jurisdictions do not permit disclaimer of implied warranties; to the extent such laws apply, some of the above disclaimers may not apply to you.</p>
          </SubSection>
          <SubSection title="9.2 Limitation of Liability">
            <p className="font-semibold text-foreground uppercase text-sm">
              To the fullest extent permitted by applicable law, {COMPANY.toUpperCase()} and its managers, members, officers, employees, agents, and successors ("Released Parties") shall not be liable for any indirect, incidental, special, consequential, punitive, or exemplary damages — including but not limited to: loss of profits; loss of data; loss of goodwill; personal injury or property damage; failed dates; partner dissatisfaction; adverse romantic outcomes; venue closures; AI hallucinations; incorrect allergy information; or any damages arising from reliance on AI-Generated Content — arising from or related to your access to or use of (or inability to use) the Service, even if the Released Parties have been advised of the possibility of such damages, and regardless of the legal theory asserted (contract, tort, statute, warranty, or otherwise).
            </p>
          </SubSection>
          <SubSection title="9.3 Aggregate Liability Cap">
            <p>
              Our total aggregate liability to you for all claims arising out of or relating to these Terms or the Service during the 12-month period preceding the claim shall not exceed the greater of: (a) the total fees you paid to us during that 12-month period; or (b) USD $50.00. This cap applies regardless of the number of claims or the legal theory under which they are asserted.
            </p>
          </SubSection>
          <SubSection title="9.4 Essential Basis of the Bargain">
            <p>
              The limitations and disclaimers in Sections 9.1–9.3 reflect a deliberate and reasonable allocation of risk between sophisticated parties. You acknowledge that the Company would not provide the Service at its current pricing without these limitations, and that the Service's pricing reflects this allocation.
            </p>
          </SubSection>
          <SubSection title="9.5 Consumer Protection Carve-Out">
            <p>
              Nothing in this Agreement excludes liability for (a) death or personal injury caused by our negligence; (b) fraud or fraudulent misrepresentation; or (c) any other liability that cannot be excluded or limited under applicable law.
            </p>
          </SubSection>
        </Section>

        {/* 10. Indemnification */}
        <Section icon={ShieldAlert} title="10. Indemnification">
          <p>
            To the fullest extent permitted by applicable law, you agree to indemnify, defend (at our option), and hold harmless the Released Parties from and against any and all third-party claims, demands, suits, proceedings, losses, liabilities, damages, costs, and expenses (including reasonable attorneys' fees) arising out of or relating to:
          </p>
          <ul className="space-y-2 mt-3">
            <Bullet>Your access to or use of the Service in violation of these Terms or any applicable law;</Bullet>
            <Bullet>Your User Content;</Bullet>
            <Bullet>Your violation of any third party's intellectual-property, privacy, or other rights;</Bullet>
            <Bullet>Your misuse of AI-Generated Content in a manner that causes harm to any person;</Bullet>
            <Bullet>Any claim that, if true, would constitute a breach of your representations or warranties herein.</Bullet>
          </ul>
          <p className="mt-3">
            We reserve the right to assume exclusive control of the defence of any matter otherwise subject to indemnification by you, at your expense. You agree not to settle any such matter without our prior written consent.
          </p>
        </Section>

        {/* 11. Dispute Resolution */}
        <Section icon={Scale} title="11. Dispute Resolution & Governing Law">
          <SubSection title="11.1 Governing Law">
            <p>
              This Agreement is governed by the laws of the State of New York, United States, without regard to its conflict-of-law provisions, except that the Federal Arbitration Act (FAA) governs all questions of arbitrability. If you are a consumer residing in the European Union, your statutory rights under the law of your country of residence are unaffected.
            </p>
          </SubSection>
          <SubSection title="11.2 Mandatory Informal Resolution">
            <p>
              Before initiating any formal dispute, you and we each agree to attempt in good faith to resolve the dispute informally. The party asserting a dispute must provide written notice to the other — emailed to{" "}
              <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a>{" "}
              or mailed to our address below — describing the nature of the dispute and the relief sought. The parties shall negotiate in good faith for at least <strong>30 calendar days</strong> following receipt of that notice before either party may initiate formal proceedings. This requirement does not apply to requests for emergency injunctive relief.
            </p>
          </SubSection>
          <SubSection title="11.3 Binding Individual Arbitration">
            <p>
              <strong>PLEASE READ THIS SECTION CAREFULLY. IT LIMITS YOUR ABILITY TO PURSUE CLAIMS IN COURT AND TO PARTICIPATE IN CLASS ACTIONS.</strong>
            </p>
            <p className="mt-2">
              If a dispute is not resolved informally, you and the Company agree that any dispute, claim, or controversy arising out of or relating to this Agreement or the Service — including questions of arbitrability — shall be resolved by <strong>final and binding individual arbitration</strong> administered by JAMS pursuant to its Streamlined Arbitration Rules and Procedures (available at <a href="https://www.jamsadr.com" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">jamsadr.com</a>), except that:
            </p>
            <ul className="space-y-2 mt-2">
              <Bullet>Either party may bring an individual action in small claims court for disputes within that court's jurisdiction, so long as the action remains in small claims court and is not removed or appealed.</Bullet>
              <Bullet>Either party may seek emergency injunctive or declaratory relief in any court of competent jurisdiction to prevent irreparable harm pending arbitration.</Bullet>
            </ul>
          </SubSection>
          <SubSection title="11.4 Class Action & Mass Action Waiver">
            <p>
              <strong>You and the Company agree that each may bring claims against the other only in an individual capacity and not as a plaintiff or class member in any purported class action, collective action, consolidated action, private attorney general action, or other representative proceeding.</strong> The arbitrator may not consolidate more than one person's claims and may not preside over any form of a class, collective, or representative proceeding. If this class-action waiver is found unenforceable, the entirety of Section 11.3 shall be void, and the dispute shall be resolved in court (subject to Section 11.5).
            </p>
          </SubSection>
          <SubSection title="11.5 Arbitration Opt-Out — 30-Day Window">
            <p>
              You have the right to opt out of binding arbitration by providing written notice to{" "}
              <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a>{" "}
              within <strong>30 days</strong> of first accepting these Terms. Your opt-out notice must include your name, email address, and a clear statement that you are opting out of arbitration. If you opt out, neither party will be bound by Section 11.3 or 11.4 with respect to future disputes; all other provisions remain in effect. Opting out has no adverse effect on your use of or access to the Service.
            </p>
          </SubSection>
          <SubSection title="11.6 Venue for Non-Arbitrated Claims">
            <p>
              For any claims not subject to arbitration (or following a valid opt-out), you and the Company consent to the exclusive jurisdiction of the state and federal courts located in New York County, New York, USA, and waive any objection to personal jurisdiction or venue in those courts.
            </p>
          </SubSection>
          <SubSection title="11.7 EU/EEA & UK Consumers">
            <p>
              Nothing in this Agreement limits the rights of EU, EEA, or UK consumers to pursue claims before their local courts or relevant consumer-protection or data-protection authorities. EU consumers may also access the European Commission's online dispute resolution platform at <a href="https://ec.europa.eu/consumers/odr" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">ec.europa.eu/consumers/odr</a>.
            </p>
          </SubSection>
        </Section>

        {/* 12. Termination */}
        <Section icon={Globe} title="12. Suspension & Termination">
          <SubSection title="12.1 Termination by Member">
            <p>
              You may close your account at any time by navigating to <strong>Profile → Settings → Delete Account</strong> in the app or by emailing{" "}
              <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a>{" "}with the subject line "Delete My Account." Account deletion is permanent and irreversible. Upon deletion, all personally identifiable data will be purged from production systems within 30 days; encrypted backup copies are overwritten within 90 days. Deletion does not release you from obligations accrued prior to deletion (e.g., indemnification claims) and does not entitle you to any refund of prepaid subscription fees.
            </p>
            <p className="mt-2">
              <strong>Important:</strong> You must cancel your Apple subscription separately via iOS Settings before or after deleting your account. Deleting your account does not cancel your App Store subscription; failure to cancel may result in continued billing by Apple.
            </p>
          </SubSection>
          <SubSection title="12.2 Suspension or Termination by Company">
            <p>
              We may suspend, restrict, or permanently terminate your access to the Service, with or without prior notice, if we reasonably believe you have: (a) violated these Terms; (b) engaged in fraudulent, abusive, or illegal activity; (c) posed a safety risk to other Members or to the Company; or (d) failed to pay any amounts due. Where practical, we will provide notice and an opportunity to cure before permanent termination of accounts with a history of good standing.
            </p>
          </SubSection>
          <SubSection title="12.3 Effect of Termination">
            <p>
              Upon termination, your licence to use the Service ends immediately. Sections 1, 7.2, 8, 9, 10, 11, 12.3, and 13 survive termination.
            </p>
          </SubSection>
        </Section>

        {/* 13. Changes */}
        <Section icon={FileText} title="13. Modifications to These Terms">
          <p>
            We may modify these Terms at any time. For material changes — including changes to dispute resolution, pricing terms, or your legal rights — we will provide at least <strong>14 days' advance notice</strong> via in-app notification and/or email. Non-material changes (e.g., formatting, typographical corrections, clarifications that do not narrow your rights) take effect upon posting.
          </p>
          <p className="mt-3">
            Your continued use of the Service after the effective date of updated Terms constitutes your acceptance of the changes. If you do not agree to the modified Terms, you must stop using the Service and delete your account before the effective date.
          </p>
        </Section>

        {/* 14. General Provisions */}
        <Section icon={FileText} title="14. General Provisions">
          <ul className="space-y-3">
            <Bullet>
              <strong>Entire Agreement.</strong> This Agreement (including the Privacy Policy incorporated by reference) constitutes the entire agreement between you and the Company regarding the Service and supersedes all prior negotiations, representations, warranties, and understandings between the parties with respect to its subject matter.
            </Bullet>
            <Bullet>
              <strong>Severability.</strong> If any provision of this Agreement is held invalid, illegal, or unenforceable by a court of competent jurisdiction, the provision shall be modified to the minimum extent necessary to make it enforceable, and the remaining provisions shall remain in full force and effect.
            </Bullet>
            <Bullet>
              <strong>No Waiver.</strong> Our failure or delay in exercising any right, remedy, power, or privilege under this Agreement shall not operate as a waiver thereof, nor shall any single or partial exercise preclude any other or further exercise of any right, remedy, power, or privilege.
            </Bullet>
            <Bullet>
              <strong>Assignment.</strong> You may not assign or transfer any rights or obligations under this Agreement without our prior written consent. We may freely assign this Agreement in connection with a merger, acquisition, or sale of substantially all of our assets, provided the assignee assumes all of our obligations hereunder.
            </Bullet>
            <Bullet>
              <strong>Force Majeure.</strong> Neither party shall be in breach of this Agreement or liable for delay or failure in performance resulting from causes outside that party's reasonable control, including but not limited to acts of God, natural disasters, war, terrorism, pandemic, governmental action, labour disputes, or internet infrastructure failures.
            </Bullet>
            <Bullet>
              <strong>Notices.</strong> Notices to the Company under this Agreement must be sent to{" "}<a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a>. Notices to you will be sent to the email address associated with your account.
            </Bullet>
            <Bullet>
              <strong>Controlling Language.</strong> This Agreement is written in English. If we provide translations for convenience, the English version controls in the event of any inconsistency.
            </Bullet>
            <Bullet>
              <strong>Headings.</strong> Section headings are for convenience only and shall not affect the interpretation of any provision.
            </Bullet>
          </ul>
        </Section>

        {/* 15. Events */}
        <Section icon={Calendar} title="15. Real-World Events & In-Person Experiences">
          <p className="text-sm italic mb-4">
            This section applies when {COMPANY} hosts, sponsors, or co-produces in-person events including launch parties, group date experiences, workshops, and community meetups ("Events"). If no Events are currently scheduled, this section is provided for completeness and shall become operative upon the scheduling of any such Event.
          </p>
          <SubSection title="15.1 Voluntary Participation">
            <p>
              Attendance at any Event is entirely voluntary. By registering for or attending an Event, you acknowledge and agree to be bound by this Section 15 in addition to all other provisions of this Agreement.
            </p>
          </SubSection>
          <SubSection title="15.2 Assumption of Risk">
            <p>
              You acknowledge that participation in any in-person Event involves inherent risks, including without limitation physical injury, illness, property loss, and interpersonal conflict. You voluntarily and knowingly assume all such risks to the fullest extent permitted by applicable law, whether foreseeable or unforeseeable at the time of your decision to attend.
            </p>
          </SubSection>
          <SubSection title="15.3 Release of Liability">
            <p>
              To the fullest extent permitted by law, you release, discharge, and covenant not to sue {COMPANY} and its managers, members, officers, employees, contractors, sponsors, and venue partners (collectively, "Event Parties") from any and all claims, demands, damages, losses, liabilities, costs, and expenses of any nature — including personal injury, death, and property damage — arising out of or related to your attendance at or participation in any Event, <em>except</em> to the extent caused by the gross negligence or wilful misconduct of an Event Party.
            </p>
          </SubSection>
          <SubSection title="15.4 Code of Conduct">
            <p>
              All Event attendees must: (a) treat other attendees, Event staff, and venue personnel with dignity and respect; (b) refrain from harassment, unwanted physical contact, intimidation, discrimination, or threatening behaviour of any kind; (c) comply with all venue rules and lawful directions from Event staff; and (d) not bring or use weapons, controlled substances, or other prohibited items. We reserve the right to remove any attendee for Code of Conduct violations without refund and without liability.
            </p>
          </SubSection>
          <SubSection title="15.5 Photography & Likeness Release">
            <p>
              Events may be photographed, filmed, or live-streamed. By attending, you grant {COMPANY} a royalty-free, worldwide, perpetual licence to use, reproduce, and distribute your image and likeness captured at the Event solely for non-commercial promotional purposes related to our Services. If you do not wish to be photographed or filmed, you must notify Event check-in staff at arrival, and we will make reasonable efforts to accommodate your request, though we cannot guarantee that your image will not appear incidentally in Event coverage.
            </p>
          </SubSection>
          <SubSection title="15.6 Ticket Refunds">
            <p>
              Unless otherwise stated in writing at the time of ticket purchase: (a) tickets are non-refundable within 7 calendar days of the Event date; (b) if we cancel an Event, we will refund the face value of tickets; (c) we are not responsible for travel, accommodation, or other costs you incur. All Events are 18+ unless explicitly stated otherwise in the Event listing.
            </p>
          </SubSection>
        </Section>

        {/* 16. Contact */}
        <Section icon={Mail} title="16. Contact & Legal Notices">
          <p>For legal notices, Terms-related inquiries, account-deletion requests, or to report a violation:</p>
          <div className="mt-3 p-4 rounded-lg border border-border bg-secondary/20 space-y-1 text-sm">
            <p className="font-semibold text-foreground">{COMPANY}</p>
            <p>
              Email:{" "}
              <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">
                {CONTACT_EMAIL}
              </a>
            </p>
            <p>Website: yourdategenie.com</p>
          </div>
          <p className="mt-3">
            We endeavour to respond to all legal inquiries within 10 business days. For privacy-specific questions, data-rights requests, or to exercise your GDPR/CCPA rights, see our{" "}
            <Link to="/privacy" className="text-primary hover:underline">
              Privacy Policy
            </Link>.
          </p>
          <p className="mt-3 text-sm italic">
            Note: These Terms have been drafted with care but are not a substitute for advice from a licensed attorney in your jurisdiction. If you have specific legal questions about your rights or obligations, we encourage you to consult qualified legal counsel.
          </p>
        </Section>

        {/* Divider + navigation */}
        <div className="mt-16 pt-8 border-t border-border flex flex-col sm:flex-row items-center justify-between gap-4 text-sm text-muted-foreground">
          <p>© {new Date().getFullYear()} {COMPANY}. All rights reserved.</p>
          <div className="flex items-center gap-6">
            <Link to="/privacy" className="hover:text-foreground transition-colors">
              Privacy Policy
            </Link>
            <Link to="/" className="hover:text-foreground transition-colors">
              Home
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Terms;
