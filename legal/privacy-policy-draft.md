# Privacy Policy — Your Date Genie

**Effective Date:** May 27, 2026  
**Last Updated:** April 29, 2026  
**Contact:** hello@yourdategenie.com  
[CONFIRM: privacy@yourdategenie.com if alias is set up before launch]

---

## Who We Are

Your Date Genie LLC ("Date Genie," "we," "us," or "our") operates the Your Date Genie iOS app and the website at yourdategenie.com (collectively, the "Service"). We are committed to handling your personal information responsibly, transparently, and in accordance with GDPR, CCPA, CalOPPA, and COPPA.

---

## 1. Information We Collect

### 1.1 Information You Provide

- **Account data** — name, email address, and (optionally) date of birth when you register.
- **Social sign-in data** — if you sign in with Google or Apple, we receive only your name, email, and a provider-issued ID. We never receive or store your Google or Apple password.
- **Preferences & questionnaire data** — date preferences, dietary restrictions, activity preferences, location/neighbourhood, budget range, special occasions, dealbreakers, and similar inputs you provide to personalise date plans.
- **Partner-planning data** — if you use the Partner Planning feature, a temporary session is created linked to both users' accounts. You agree your partner has consented to participation before inviting them.
- **Memories** — photos, captions, and dates you voluntarily add to your Memory Gallery.
- **Love notes & gift suggestions** — text you provide to generate AI-assisted love notes or the gift descriptions you generate and save.
- **Communications** — if you contact support, the content of that message.

### 1.2 Information Collected Automatically

- **Device & app diagnostics** — iOS version, app version, device type, crash reports, and anonymised performance metrics. These are never linked to personally identifiable information.
- **Location** — approximate city/region *only when you grant permission* to enable nearby venue recommendations. We do not collect precise GPS coordinates, and location data is not stored after the plan is generated.
- **Calendar** — the app requests calendar access only for optional "save date plan to calendar" functionality, if implemented. Calendar data is not uploaded to our servers.
- **Photo library** — the app requests photo library *add-only* access to allow you to save generated date-plan images to your camera roll. We do not read your existing photo library.
- **Usage signals** — in-app navigation events (e.g., which screens you visit) to improve UX. These are aggregated and anonymised before any analysis. Collected via Plausible on the web — a privacy-friendly, cookie-free analytics tool.

### 1.3 Information We Do Not Collect

- Payment card numbers or full financial information (payments are processed by Apple / the App Store; we receive only transaction status).
- Social media passwords or OAuth refresh tokens from Google or Apple — we only hold the Supabase session token issued after a successful sign-in.
- Precise, real-time GPS tracks or location history.
- Data from minors under 17 years of age (see Section 9).
- Your name or email when sending data to OpenAI for AI generation (see Section 3.1).

---

## 2. How We Use Your Information

We process your data only for the purposes described below, relying on the following legal bases (GDPR Art. 6):

- **Service delivery (Contractual necessity)** — generating personalised date plans, syncing your preferences across devices, loading your saved plans and memories.
- **Account management (Contractual necessity)** — authenticating you, handling password resets, and ensuring data belongs to the correct account.
- **Transactional communications (Contractual necessity)** — sending welcome emails, subscription confirmations, and account-related notifications via Resend.
- **Safety & security (Legitimate interest)** — detecting and preventing fraud, abuse, and unauthorised access.
- **Legal compliance (Legal obligation)** — responding to valid law-enforcement requests and complying with applicable law.
- **Product improvement (Legitimate interest, after anonymisation)** — understanding aggregate feature usage to prioritise development. No individual-level profiling.
- **Marketing (Consent, where required)** — promotional emails only if you have opted in. You can withdraw consent at any time via the unsubscribe link in any marketing email.

We do **not** sell your personal data, use it for advertising profiling, or share it with data brokers.

---

## 3. How We Share Your Information

### 3.1 Service Providers (Sub-processors)

We share data with the following processors under data-processing agreements:

| Processor | Purpose | Data Sent | Location |
|-----------|---------|-----------|---------|
| **Supabase** | Database, authentication, file storage | Account data, preferences, saved plans, memories | United States (AWS) |
| **OpenAI** | AI generation of date plans, love notes, gift suggestions | Anonymised questionnaire data (no name, no email, no account ID) | United States |
| **Google (Places API)** | Venue search and location data | Search query + approximate city/location | United States |
| **Apple (App Store / StoreKit)** | Subscription billing | Transaction status only; we never see card details | United States |
| **Resend** | Transactional email delivery | Your email address, email content | United States |
| **Firebase / Firestore** | Pre-launch waitlist signups only | Email + signup timestamp (pre-launch only; archived after public launch) | United States |

OpenAI's zero-retention API option is enabled where available, meaning OpenAI does not use our API requests to train its models.

### 3.2 Legal Disclosures

We may disclose your data when we have a good-faith belief it is required by law, court order, or to protect the rights and safety of our users or the public.

### 3.3 Business Transfers

If Your Date Genie LLC is involved in a merger, acquisition, or asset sale, we will provide notice before your personal data is transferred. Any successor will be required to honour the commitments made here.

### 3.4 Aggregated / Anonymised Data

We may share aggregated, non-identifiable statistics with third parties (e.g., "most popular date categories by city"). This data cannot reasonably be used to identify you.

---

## 4. Data Security

- **Encryption in transit** — all communication between the app and our servers uses TLS 1.2+ (HTTPS). HTTP is rejected for all production endpoints.
- **Encryption at rest** — database rows, stored files (memories), and session tokens are encrypted at rest by Supabase's underlying AWS infrastructure (AES-256).
- **Keychain storage** — on iOS, session tokens are stored in the device Keychain using Apple's hardware-backed secure enclave, not in UserDefaults or plaintext files.
- **Row-level security (RLS)** — every Supabase database table is protected by Postgres Row-Level Security policies so that users can only read and write their own rows.
- **Short-lived sessions** — access tokens expire after one hour. Refresh tokens are rotated on every use and invalidated on sign-out.
- **Social OAuth (PKCE)** — Google and Apple sign-in use Proof Key for Code Exchange, preventing interception or replay of authorisation codes.
- **No plaintext passwords** — passwords are hashed with bcrypt by Supabase's auth service.
- **Breach response** — in the event of a data breach affecting personal data, we will notify affected users and relevant authorities within 72 hours where required by GDPR.

---

## 5. Your Rights

Depending on where you live, you have some or all of the following rights:

- **Access** — request a copy of the personal data we hold about you. Available in-app via Settings → Export My Data (if implemented) or by email.
- **Rectification** — correct inaccurate or incomplete data via your account settings.
- **Erasure ("right to be forgotten")** — delete your account and all associated data. Available in-app via Profile → Delete Account, or by emailing us.
- **Portability** — receive your data in a structured, machine-readable format (JSON) by emailing us.
- **Objection** — object to processing based on legitimate interests or for direct marketing.
- **Restriction** — request that we restrict processing while a dispute is resolved.
- **Withdraw consent** — where processing is based on consent (e.g., marketing emails), withdraw it at any time without affecting prior lawful processing.
- **CCPA — Do Not Sell** — California residents: we do not sell personal information. You may submit a "Do Not Sell" request and we will confirm compliance.

To exercise any right, email **hello@yourdategenie.com**. We will respond within 30 days (CCPA) or one month (GDPR). We may need to verify your identity before fulfilling the request.

---

## 6. Data Retention

- **Active accounts** — we retain your data for as long as your account is active and for up to 12 months after your last login to allow reactivation.
- **Deleted accounts** — upon account deletion, all personally identifiable data (profile, preferences, saved plans, memories, love notes) is permanently purged from production databases within **30 days** of the deletion request.
- **Backups** — encrypted database backups may contain your data for up to **90 days** after deletion, after which they are overwritten. Backup contents are not accessible to employees for any purpose other than disaster recovery.
- **Legal hold** — we may retain data longer if required by law, court order, or to resolve an active dispute.
- **Waitlist data (Firebase)** — migrated to Supabase and deleted from Firebase within 30 days of public launch.

---

## 7. International Data Transfers

Your Date Genie is operated from the United States. If you access the app from the European Economic Area, United Kingdom, or other regions with data-protection laws, your data will be transferred to and processed in the United States.

For transfers from the EEA, we rely on the EU–US Data Privacy Framework and Standard Contractual Clauses (SCCs) with sub-processors (Supabase, OpenAI, Resend) to ensure an adequate level of protection.

[VERIFY with lawyer: Confirm SCCs are in place with all listed sub-processors before EU/EEA users onboard.]

---

## 8. Cookies & Tracking (Web App)

- **Strictly necessary cookies** — session cookies used to keep you logged in. No consent required.
- **Functional cookies** — remember UI preferences. No consent required.
- **Analytics (Plausible)** — we use Plausible Analytics on yourdategenie.com. Plausible is cookie-free, does not use fingerprinting, and does not process personal data. No consent banner required under GDPR or ePrivacy Directive for this tool.
- **No advertising cookies** — we do not use Meta Pixel, Google Analytics, LinkedIn Insight Tag, or any advertising/tracking cookies.

You can clear cookies at any time via your browser settings. The iOS app uses no browser cookies; sessions are stored in the Keychain.

---

## 9. Children's Privacy

Your Date Genie is designed for users aged **17 and older**. We do not knowingly collect personal information from anyone under 17. If we learn that we have inadvertently collected data from a minor under 17, we will delete it immediately.

If you believe your child has provided us personal information, please contact us at hello@yourdategenie.com.

[VERIFY: App Store age rating is currently 17+. Confirm this aligns with all target markets and no regional law requires a higher minimum age.]

---

## 10. Third-Party AI Disclosure (Apple §5.1.2(i))

This app uses **OpenAI's API** to generate AI-powered date plans, love notes, and gift suggestions. Your date preferences (e.g., vibe, cuisine, budget, location) are sent to OpenAI to generate personalised suggestions. We do not send your name, email address, or account identifiers to OpenAI. OpenAI processes this data in the United States in accordance with OpenAI's Privacy Policy and Terms of Service.

---

## 11. Changes to This Policy

We may update this Privacy Policy from time to time. Material changes will be communicated via an in-app notification and/or email at least 14 days before they take effect. The updated policy will also be published at yourdategenie.com/privacy-policy with a new effective date.

Your continued use of the app after the effective date constitutes acceptance of the updated policy.

---

## 12. Contact & Data Protection

For privacy-related questions, access requests, data deletion, or complaints:

**Your Date Genie LLC**  
Email: hello@yourdategenie.com  
[CONFIRM: privacy@yourdategenie.com if alias is set up]  
Website: yourdategenie.com

We will respond within 30 days. EU/EEA residents have the right to lodge a complaint with their local supervisory authority (e.g., the Irish Data Protection Commission) if they believe their data has been processed unlawfully. We ask that you contact us first.

---

## Pre-Publication Verification Checklist

Before this policy is published, confirm:

- [ ] **Legal entity:** "Your Date Genie LLC" confirmed throughout (not "Inc.")
- [ ] **Contact email:** hello@yourdategenie.com confirmed as active support alias
- [ ] **Effective date:** May 27, 2026 matches launch date
- [ ] **iOS permissions accuracy:**
  - [ ] Calendar access — confirm whether "save to calendar" feature ships in v1
  - [ ] Photo add-only — confirm NSPhotoLibraryAddUsageDescription is only permission (not NSPhotoLibraryUsageDescription)
  - [ ] Location — confirm city-level only, not precise GPS; confirm not retained after plan generation
- [ ] **OpenAI zero-retention API** confirmed enabled on your OpenAI project settings
- [ ] **Firebase data** — confirm pre-launch only; deletion plan after launch confirmed
- [ ] **SCCs in place** with Supabase, OpenAI, and Resend for EEA users
- [ ] **Plausible analytics** confirmed as cookie-free (no consent banner needed)
- [ ] Lawyer has reviewed Sections 7 (international transfers), 5 (user rights), and 10 (AI disclosure)
- [ ] App Store Connect Privacy Policy URL set to https://yourdategenie.com/privacy-policy

---

**Document status:** Draft for legal review  
**Prepared:** April 29, 2026  
**Entity:** Your Date Genie LLC
