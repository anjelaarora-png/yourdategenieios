# How to Work with Your AI Executive Team

A practical guide for Anjela. Save this. The whole goal: more leverage, less context-switching.

---

## The one rule

Talk to me like you'd talk to your team. **Name the agent when you want a specific lens; otherwise default to chief-of-staff.** I'll route from there.

## The three modes

### 1. Single-agent mode (most common)
You know what kind of help you need. You just say it.

> "Have the **CFO** model runway through Q4."
> "**Backend agent**: design the Firestore waitlist schema."
> "**Marketing**: give me 3 hooks for a TikTok about long-distance couples."

I load that agent's context and respond in their voice with their defaults.

### 2. Multi-agent mode (for cross-functional decisions)
Some questions span functions. Just name them.

> "**Strategy + finance + marketing** — should we run paid ads this week?"
> "**Backend + frontend** — design the waitlist flow end-to-end."

I'll have each agent weigh in, surface where they disagree, and give you a synthesis.

### 3. Chief-of-staff mode (the default when in doubt)
When you don't know who should handle it — or when you want to start your day — go to your chief-of-staff. They route, synthesize, and protect your time.

> "Brief me — what should today look like?"
> "I just got an email from [investor]. Triage."
> "Plan my week."

---

## A typical day rhythm

**Morning (5 min):**
> "Chief-of-staff, daily brief."

You'll get back: today's 3 priorities, watch-fors, decisions you owe people, yesterday recap.

**During the day (as things come up):**
- New idea → "Strategy, pressure-test this."
- Code question → "Backend / frontend / software-dev — answer this."
- Spend question → "Finance, can we afford X?"
- Content idea → "Social media manager, write this up."

**Friday afternoon (15 min):**
> "Chief-of-staff, weekly review."

Wins, slips, risks, decisions, next week's 3-priority lock.

---

## Sample prompts you can copy

### Strategic
- "Strategy, give me a 2x2 on whether to launch Android in July or October."
- "Strategy + CFO, is the contractor hire still the right call given current runway?"

### Marketing & social
- "Marketing, write App Store subtitle options."
- "Social media manager, plan next week across IG / TikTok / Threads."
- "Marketing + UI/UX, brief the landing page hero rewrite."

### Money
- "CFO, build a 6-month base/bear/bull runway model."
- "Accounting, what do I need to do before tax season?"
- "CFO + accounting, set up my chart of accounts."

### Build
- "Backend, audit my Supabase RLS policies before launch."
- "Frontend, the waitlist form needs UTM capture — implement it."
- "Software-developer, review this PR before I merge."
- "UI/UX, App Store screenshots — give me a brief I can ship to a designer."

### Catch-all
- "Chief-of-staff, take this off my plate."
- "Chief-of-staff, who should I be asking?"

---

## How memory keeps things efficient

Every conversation builds context. You don't have to re-brief.

- **Decisions stick.** When you decide something (e.g. "use Firebase for waitlist"), I remember it and apply it across future conversations.
- **Feedback sticks.** When you tell an agent "stop hedging," that agent (and the others) carry that forward.
- **Dates and numbers stay current.** Launch is May 27, 2026; runway is ~$5K/mo; you're solo with contractors. No need to repeat.

If you ever want to **change** something an agent assumes, just say so:
> "Update the launch date to June 10."
> "We raised — runway is now 18 months."
> "The brand voice should be more playful, less luxe."

The change propagates.

---

## Telling agents apart

If you're not sure who owns what, here's the cheat sheet:

- **What should we do?** → strategy
- **What should we say?** → marketing
- **Can we afford it?** → finance
- **Are the books right?** → accounting
- **Is it well-built?** → software-developer
- **Where does the data live?** → backend-developer
- **Is the web app right?** → frontend-developer
- **Does it look and feel right?** → ui-ux-designer
- **What do we post?** → social-media-manager
- **What does Anjela need to do today?** → chief-of-staff

---

## When agents disagree

They will. That's the point. If marketing wants to test paid ads but finance wants to wait, I'll say so explicitly and either:
1. Synthesize a recommendation (most common), or
2. Tee up the decision for you with options.

Disagreement = signal. Embrace it.

---

## Keeping the team sharp

- **Add new context anytime.** "All future plans should assume we're now selling B2B too." → I'll update.
- **Edit any agent.** Files are in `.claude/agents/`. Tweak their defaults, voice, or scope as you learn what works.
- **Add new agents.** Need a "lawyer" agent or a "data analyst" agent? Just ask: "Add a lawyer agent." I'll create the file the same way.
- **Retire ones you don't use.** If `accounting` never gets called because you have a real CPA, delete the file. No ceremony.

---

## The one thing to remember

You are the CEO. They are your team. The right question is almost never "what should I do?" — it's "**who on my team should be helping me with this?**"

That question is what your chief-of-staff is built to answer. When in doubt, ask them.

---

*Last updated: 2026-04-28*
