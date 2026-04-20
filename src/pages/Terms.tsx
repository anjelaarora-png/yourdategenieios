import { Link } from "react-router-dom";
import { Sparkles, ArrowLeft, FileText, ShieldAlert, CreditCard, UserCheck, AlertTriangle, Scale, Globe, Mail } from "lucide-react";
import { Button } from "@/components/ui/button";

const EFFECTIVE_DATE = "April 18, 2026";
const CONTACT_EMAIL = "legal@yourdategenie.com";
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

const Terms = () => {
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
            <span className="text-primary text-sm font-medium">Please read carefully before using the app</span>
          </div>
          <h1 className="font-display text-3xl sm:text-4xl font-bold text-foreground mb-3">
            Terms of Service
          </h1>
          <p className="text-muted-foreground text-sm">
            Effective date: <span className="font-medium text-foreground">{EFFECTIVE_DATE}</span>
          </p>
          <p className="mt-4 text-muted-foreground max-w-xl mx-auto text-sm leading-relaxed">
            These Terms of Service ("Terms") form a legally binding agreement between you and {COMPANY}
            ("we", "us", "our") governing your use of the {APP_NAME} mobile application and website
            (collectively, the "Service"). By creating an account or using the Service you agree to
            these Terms in full.
          </p>
        </div>
      </div>

      {/* Body */}
      <div className="container px-4 sm:px-6 lg:px-8 max-w-3xl mx-auto py-12">

        <Section icon={UserCheck} title="1. Eligibility & Account Registration">
          <SubSection title="1.1 Age Requirement">
            <p>You must be at least <strong>17 years old</strong> to use the Service. By creating an account, you represent that you meet this requirement. We reserve the right to terminate accounts of users found to be under age without notice.</p>
          </SubSection>
          <SubSection title="1.2 Account Accuracy">
            <p>You agree to provide accurate, current, and complete information during registration and to keep it updated. You are responsible for all activity that occurs under your account.</p>
          </SubSection>
          <SubSection title="1.3 Account Security">
            <ul className="space-y-2 mt-1">
              <Bullet>You are responsible for keeping your password and device secure.</Bullet>
              <Bullet>You must notify us immediately at <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a> if you suspect unauthorised access to your account.</Bullet>
              <Bullet>We are not liable for losses resulting from unauthorised access you failed to prevent or report promptly.</Bullet>
            </ul>
          </SubSection>
          <SubSection title="1.4 One Account per Person">
            <p>You may not create multiple accounts to circumvent subscription limits, bans, or other restrictions.</p>
          </SubSection>
        </Section>

        <Section icon={FileText} title="2. The Service">
          <SubSection title="2.1 What We Provide">
            <p>{APP_NAME} is an AI-assisted date-planning concierge that generates personalised date plans, venue suggestions, memory storage, gift recommendations, and related features. Date plans are suggestions only — we do not make bookings, reservations, or purchases on your behalf unless explicitly stated.</p>
          </SubSection>
          <SubSection title="2.2 AI-Generated Content">
            <p>Date plan suggestions are generated by large language models (currently OpenAI's GPT-4). While we strive for accuracy:</p>
            <ul className="space-y-2 mt-2">
              <Bullet>Venue details (hours, prices, availability) may change without notice. Always verify directly with the venue.</Bullet>
              <Bullet>AI outputs may occasionally be incorrect, outdated, or unsuitable for your specific circumstances. You remain responsible for evaluating suggestions before acting on them.</Bullet>
              <Bullet>We do not guarantee any particular experience quality based on our suggestions.</Bullet>
            </ul>
          </SubSection>
          <SubSection title="2.3 Third-Party Services">
            <p>The Service integrates with third-party providers (Google Places, OpenAI, Apple StoreKit, OpenTable, Resy, etc.). Use of those services is subject to their own terms and privacy policies, which we do not control.</p>
          </SubSection>
          <SubSection title="2.4 Service Availability">
            <p>We aim for high availability but do not guarantee the Service will be uninterrupted, error-free, or available in all regions. We may temporarily suspend the Service for maintenance, updates, or reasons beyond our control.</p>
          </SubSection>
        </Section>

        <Section icon={CreditCard} title="3. Subscriptions & Payments">
          <SubSection title="3.1 Free Tier">
            <p>Certain features are available free of charge. Free-tier limitations may change at any time.</p>
          </SubSection>
          <SubSection title="3.2 Paid Subscriptions">
            <p>Premium features require a paid subscription, purchased and managed through the Apple App Store. By subscribing:</p>
            <ul className="space-y-2 mt-2">
              <Bullet>Your subscription renews automatically at the then-current price unless cancelled at least 24 hours before the renewal date.</Bullet>
              <Bullet>Payment is charged to your Apple ID account at confirmation of purchase.</Bullet>
              <Bullet>You can manage or cancel your subscription in your Apple ID account settings at any time. Cancellation takes effect at the end of the current billing period.</Bullet>
              <Bullet>We do not process or store your payment card details — all billing is handled exclusively by Apple.</Bullet>
            </ul>
          </SubSection>
          <SubSection title="3.3 Refunds">
            <p>Refund requests are governed by Apple's App Store refund policy. We do not issue refunds directly. To request a refund, visit <a href="https://reportaproblem.apple.com" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">reportaproblem.apple.com</a>.</p>
          </SubSection>
          <SubSection title="3.4 Price Changes">
            <p>We may change subscription prices with at least 30 days' notice. Continued use after the notice period constitutes acceptance of the new price.</p>
          </SubSection>
        </Section>

        <Section icon={UserCheck} title="4. User Conduct & Acceptable Use">
          <p>You agree not to:</p>
          <ul className="space-y-2 mt-3">
            <Bullet>Use the Service for any unlawful purpose or in violation of any applicable laws.</Bullet>
            <Bullet>Attempt to reverse-engineer, decompile, or extract source code from the app.</Bullet>
            <Bullet>Circumvent, disable, or interfere with security features, rate limits, or access controls.</Bullet>
            <Bullet>Scrape, crawl, or harvest data from the Service using automated means without our written consent.</Bullet>
            <Bullet>Upload or transmit content that is illegal, defamatory, harassing, obscene, or infringes third-party intellectual property rights.</Bullet>
            <Bullet>Use the Service to generate plans or content intended to harm, stalk, or harass another person.</Bullet>
            <Bullet>Impersonate another user, person, or entity.</Bullet>
            <Bullet>Attempt to gain unauthorised access to other users' accounts or our backend systems.</Bullet>
            <Bullet>Use the Partner Planning feature to deceive or manipulate another person without their informed consent.</Bullet>
          </ul>
          <p className="mt-3">Violation of this section may result in immediate account suspension or termination.</p>
        </Section>

        <Section icon={FileText} title="5. User Content">
          <SubSection title="5.1 Your Content">
            <p>You retain ownership of content you upload or create in the Service (memory photos, captions, customised plans, etc.) ("User Content").</p>
          </SubSection>
          <SubSection title="5.2 License to Us">
            <p>By uploading User Content, you grant {COMPANY} a limited, non-exclusive, royalty-free, worldwide licence to store, reproduce, and display your User Content solely for the purpose of operating and improving the Service for you. We do not use your personal photos or date plans for marketing or advertising without your explicit consent.</p>
          </SubSection>
          <SubSection title="5.3 Content Standards">
            <p>You are solely responsible for User Content you submit. You represent that it does not violate any law, infringe any third-party rights, or contain malicious code.</p>
          </SubSection>
          <SubSection title="5.4 Removal">
            <p>We may remove User Content that violates these Terms or applicable law, without prior notice.</p>
          </SubSection>
        </Section>

        <Section icon={Scale} title="6. Intellectual Property">
          <SubSection title="6.1 Our IP">
            <p>The Service, including its software, design, graphics, AI models, databases, trademarks, and branding ("Our Content"), is owned by {COMPANY} or its licensors and is protected by copyright, trademark, and other laws. Nothing in these Terms grants you ownership of Our Content.</p>
          </SubSection>
          <SubSection title="6.2 Limited Licence">
            <p>We grant you a personal, non-transferable, non-exclusive, revocable licence to use the app on devices you own or control, solely for your personal, non-commercial use and in accordance with these Terms.</p>
          </SubSection>
          <SubSection title="6.3 Restrictions">
            <p>You may not copy, modify, distribute, sell, rent, sublicense, or create derivative works of Our Content without our prior written permission.</p>
          </SubSection>
        </Section>

        <Section icon={AlertTriangle} title="7. Disclaimers & Limitation of Liability">
          <SubSection title="7.1 Disclaimer of Warranties">
            <p className="font-medium text-foreground">
              THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND,
              EXPRESS OR IMPLIED, INCLUDING WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
              NON-INFRINGEMENT, OR UNINTERRUPTED ACCESS. AI-GENERATED DATE PLANS ARE SUGGESTIONS ONLY —
              WE DO NOT GUARANTEE THEIR ACCURACY, SUITABILITY, OR OUTCOME.
            </p>
          </SubSection>
          <SubSection title="7.2 Limitation of Liability">
            <p className="font-medium text-foreground">
              TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, {COMPANY.toUpperCase()} AND ITS
              OFFICERS, DIRECTORS, EMPLOYEES, AND AGENTS SHALL NOT BE LIABLE FOR ANY INDIRECT,
              INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING LOSS OF PROFITS,
              DATA, GOODWILL, OR ROMANTIC OUTCOMES, ARISING FROM YOUR USE OF OR INABILITY TO USE
              THE SERVICE, EVEN IF WE HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
            </p>
          </SubSection>
          <SubSection title="7.3 Cap on Liability">
            <p>Our total aggregate liability to you for any claim arising from these Terms or your use of the Service shall not exceed the greater of (a) the fees you paid us in the 12 months preceding the claim, or (b) USD $50.</p>
          </SubSection>
          <SubSection title="7.4 Essential Basis of the Bargain">
            <p>The limitations in this section reflect an allocation of risk between the parties and are an essential element of the basis of the bargain between us.</p>
          </SubSection>
        </Section>

        <Section icon={ShieldAlert} title="8. Indemnification">
          <p>You agree to indemnify, defend, and hold harmless {COMPANY} and its affiliates, officers, directors, employees, and agents from and against any claims, liabilities, damages, losses, and expenses (including reasonable legal fees) arising out of or in any way connected with:</p>
          <ul className="space-y-2 mt-3">
            <Bullet>Your use of the Service in violation of these Terms.</Bullet>
            <Bullet>Your User Content.</Bullet>
            <Bullet>Your violation of any law or the rights of any third party.</Bullet>
          </ul>
        </Section>

        <Section icon={Scale} title="9. Dispute Resolution & Governing Law">
          <SubSection title="9.1 Governing Law">
            <p>These Terms are governed by the laws of the State of California, United States, without regard to conflict of law provisions.</p>
          </SubSection>
          <SubSection title="9.2 Informal Resolution">
            <p>Before filing any formal dispute, you agree to contact us at <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a> and attempt to resolve the issue informally for at least 30 days.</p>
          </SubSection>
          <SubSection title="9.3 Binding Arbitration (US Users)">
            <p>
              For users in the United States: any dispute that cannot be resolved informally shall be resolved by final and binding individual arbitration under the American Arbitration Association Consumer Arbitration Rules, rather than in court. <strong>You and {COMPANY} each waive the right to a jury trial and to participate in a class action.</strong>
            </p>
          </SubSection>
          <SubSection title="9.4 EU / EEA Users">
            <p>Nothing in these Terms limits your rights to bring a claim before your local courts or consumer protection authority as provided by the law of your country of residence.</p>
          </SubSection>
          <SubSection title="9.5 Exception">
            <p>Either party may seek emergency injunctive or equitable relief in any court of competent jurisdiction to prevent irreparable harm pending arbitration.</p>
          </SubSection>
        </Section>

        <Section icon={Globe} title="10. Termination">
          <SubSection title="10.1 By You">
            <p>You may close your account at any time via Profile → Delete Account. Termination does not entitle you to a refund of any prepaid subscription fees.</p>
          </SubSection>
          <SubSection title="10.2 By Us">
            <p>We may suspend or terminate your account immediately and without notice if you breach these Terms, engage in fraudulent activity, or for any other reason at our sole discretion. We will endeavour to provide notice and an opportunity to cure minor violations.</p>
          </SubSection>
          <SubSection title="10.3 Effect of Termination">
            <p>Upon termination, your licence to use the Service ends. Provisions that by their nature should survive (intellectual property, limitation of liability, indemnification, dispute resolution) shall survive termination.</p>
          </SubSection>
        </Section>

        <Section icon={FileText} title="11. Changes to These Terms">
          <p>
            We may update these Terms from time to time. Material changes will be communicated via in-app notification or email at least 14 days before they take effect. Your continued use of the Service after the effective date of updated Terms constitutes acceptance. If you do not agree to updated Terms, you must stop using the Service and delete your account.
          </p>
        </Section>

        <Section icon={FileText} title="12. Miscellaneous">
          <ul className="space-y-2">
            <Bullet><strong>Entire Agreement</strong> — these Terms, together with our Privacy Policy, constitute the entire agreement between you and us regarding the Service and supersede all prior agreements.</Bullet>
            <Bullet><strong>Severability</strong> — if any provision is held unenforceable, the remaining provisions remain in full effect.</Bullet>
            <Bullet><strong>Waiver</strong> — our failure to enforce any right is not a waiver of that right.</Bullet>
            <Bullet><strong>Assignment</strong> — you may not assign these Terms without our prior written consent. We may assign these Terms in connection with a merger or acquisition.</Bullet>
            <Bullet><strong>Force Majeure</strong> — we are not liable for delays or failures caused by circumstances beyond our reasonable control.</Bullet>
            <Bullet><strong>Language</strong> — these Terms are written in English. Any translated version is provided for convenience only; the English version controls.</Bullet>
          </ul>
        </Section>

        <Section icon={Mail} title="13. Contact Us">
          <p>For legal questions or notices:</p>
          <div className="mt-3 p-4 rounded-lg border border-border bg-secondary/20 space-y-1 text-sm">
            <p className="font-semibold text-foreground">{COMPANY}</p>
            <p>Legal &amp; Compliance</p>
            <p>
              Email:{" "}
              <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary hover:underline">{CONTACT_EMAIL}</a>
            </p>
          </div>
        </Section>

        {/* Divider + navigation */}
        <div className="mt-16 pt-8 border-t border-border flex flex-col sm:flex-row items-center justify-between gap-4 text-sm text-muted-foreground">
          <p>© {new Date().getFullYear()} {COMPANY}. All rights reserved.</p>
          <div className="flex items-center gap-6">
            <Link to="/privacy-policy" className="hover:text-foreground transition-colors">Privacy Policy</Link>
            <Link to="/" className="hover:text-foreground transition-colors">Home</Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Terms;
