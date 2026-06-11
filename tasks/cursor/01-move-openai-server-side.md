# Cursor Task — Move all OpenAI calls server-side (close client-side key leak)

**Owner:** Anjela (executing in Cursor)
**Specced by:** backend-developer agent + software-developer agent
**Priority:** P0 — must complete before App Store submission 2026-05-18
**Estimated effort:** 3–5 hours of Cursor + testing time

---

## Context for Cursor (paste this into Cursor's chat first)

Your Date Genie's iOS app currently calls OpenAI directly from the client. The OpenAI API key is shipped inside the app binary via Info.plist substitution from `Secrets.xcconfig`. This means anyone who downloads the app can extract the key and use it on our OpenAI account.

The fix: route every OpenAI call through a Supabase Edge Function. The OpenAI key lives only in Supabase's secret store; the iOS app never sees it.

The codebase already has most of the infrastructure for this — three of the four AI flows have Edge Functions. We just need to (a) finish the missing function, (b) make the iOS code call the Edge Functions instead of OpenAI directly, and (c) strip the OpenAI key out of the iOS app entirely.

---

## Goal

Three iOS services currently call OpenAI directly:

1. `ios/YourDateGenie/Managers/DatePlanGeneratorService.swift` → date plan generation
2. `ios/YourDateGenie/Managers/GiftAIService.swift` → gift suggestions
3. `ios/YourDateGenie/Managers/LoveNoteAIService.swift` → love note rewriting

After this task, none of them should hit `api.openai.com` directly. They all call Supabase Edge Functions via the Supabase Swift SDK, and the OpenAI key is removed from the iOS app entirely.

---

## Existing Edge Functions (use these — do NOT rebuild)

Already deployed under `supabase/functions/`:

| Function | Purpose | iOS caller (today) |
|---|---|---|
| `generate-date-plan/` | Date plan generation, multi-stop itinerary | `DatePlanGeneratorService.swift` (mostly) |
| `generate-more-gifts/` | Gift suggestion generation | `GiftAIService.swift` |
| `generate-playlist/` | Playlist generation | (already routed correctly — verify) |

**Missing — needs to be created:**
- `supabase/functions/rewrite-love-note/` (or similar name) — for `LoveNoteAIService.swift`

---

## Task breakdown

### Step 1 — Audit current iOS → OpenAI call sites

Read each of these files end-to-end and identify every place that:
- Constructs a URL pointing to `api.openai.com`
- Reads `Config.openAIAPIKey` or `Config.openAIAPIEndpoint`
- Sets a `Bearer ...` header with the OpenAI key

Files to read:
- `ios/YourDateGenie/Managers/DatePlanGeneratorService.swift`
- `ios/YourDateGenie/Managers/GiftAIService.swift`
- `ios/YourDateGenie/Managers/LoveNoteAIService.swift`
- `ios/YourDateGenie/Config.swift` (for the key plumbing)
- `ios/YourDateGenie/Views/Questionnaire/QuestionnaireView.swift` (only references `Config.isOpenAIConfigured` — likely just a feature flag check)
- `ios/YourDateGenie/Views/Gifts/GiftFinderView.swift` (same — feature flag check)

For each call site, document: file, line range, what model + parameters it passes to OpenAI, what response shape it expects.

### Step 2 — Verify Edge Function input/output contracts

Read each Edge Function's `index.ts` and confirm what it expects in the request body and what it returns:

- `supabase/functions/generate-date-plan/index.ts`
- `supabase/functions/generate-more-gifts/index.ts`
- `supabase/functions/generate-playlist/index.ts`

The iOS payload that's currently being sent to OpenAI must be transformable into the Edge Function's expected input. If the Edge Function takes a different shape (e.g. takes structured user/preference IDs and looks data up server-side, vs. taking the full prompt string), we adapt the iOS code.

### Step 3 — Create the missing `rewrite-love-note` Edge Function

Mirror the structure of `generate-more-gifts/` (the simplest existing function). The function should:

- Accept POST with JSON body: `{ "originalText": string, "tone": string, "userId": string }` (adjust based on what `LoveNoteAIService.swift` actually needs)
- Verify the request bearer is a valid Supabase user JWT (use the standard Supabase pattern — see how `generate-more-gifts` does it)
- Read `OPENAI_API_KEY` from `Deno.env.get('OPENAI_API_KEY')`
- Call OpenAI's chat completions endpoint server-side using the same prompt structure currently in `LoveNoteAIService.swift`
- Return JSON: `{ "rewrittenText": string }` (or whatever shape the iOS code expects)
- Include CORS headers (copy from `cors.ts` pattern in `generate-date-plan/`)
- Handle errors gracefully — return `{ error: string }` with appropriate status code

### Step 4 — Refactor each iOS service to call its Edge Function

For each of the three services, replace the direct OpenAI URLSession call with a Supabase functions invocation. Use the existing Supabase Swift client (`SupabaseService.swift` already wraps it).

Pattern (pseudocode — write idiomatic Swift):

```
// BEFORE
let request = URLRequest(url: URL(string: Config.openAIAPIEndpoint)!)
request.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
// ... build OpenAI request body
let (data, _) = try await URLSession.shared.data(for: request)
// parse OpenAI response

// AFTER
let response = try await SupabaseService.shared.client.functions.invoke(
    "generate-date-plan",
    options: FunctionInvokeOptions(body: ourPayload)
)
// parse Edge Function response (much simpler shape)
```

Use the actual API surface of `supabase-swift`'s `functions.invoke` method — Cursor should look at how it's called elsewhere in the codebase (or check `supabase-swift` docs) for the canonical pattern.

Preserve existing error types (`.notConfigured`, `.networkError`, etc.) but update their meanings:
- `.notConfigured` → "Supabase not configured" (instead of "OpenAI key missing")
- Add `.unauthorized` if the user isn't authenticated (Edge Function will reject)
- Add `.rateLimited` for 429 responses (so the UI can show "Try again in a minute")

### Step 5 — Strip OpenAI from iOS app

Once all three services route through Edge Functions:

1. **`ios/YourDateGenie/Config.swift`** — remove:
   - `static let openAIAPIKey`
   - `static let openAIAPIEndpoint`
   - `static let openAIModel`
   - `static var isOpenAIConfigured`
   - The `OPENAI_API_KEY` check in `validateConfiguration()`

2. **`ios/Info.plist`** — remove the `OPENAI_API_KEY` entry (lines that set `<key>OPENAI_API_KEY</key>` and `<string>$(OPENAI_API_KEY)</string>`).

3. **`ios/Secrets.xcconfig`** (and `.example`) — remove the `OPENAI_API_KEY` line.

4. **`ios/YourDateGenie/Views/Questionnaire/QuestionnaireView.swift` and `Views/Gifts/GiftFinderView.swift`** — replace any `Config.isOpenAIConfigured` check with `Config.isSupabaseConfigured` (since the user only needs Supabase to call the Edge Functions now).

5. **`ios/README.md`** — update the "Environment Variables" section to remove `OPENAI_API_KEY` from the iOS-required list. Add a note in the architecture section that AI calls are routed through Supabase Edge Functions.

### Step 6 — Set the OpenAI key in Supabase secrets

This is a one-time CLI step (NOT done in Cursor — Anjela does this):

```bash
# From repo root, with Supabase CLI installed
supabase secrets set OPENAI_API_KEY=sk-...your-key... --project-ref jhpwacmsocjmzhimtbxj
```

Verify it's set:
```bash
supabase secrets list --project-ref jhpwacmsocjmzhimtbxj
```

### Step 7 — Deploy Edge Functions

```bash
supabase functions deploy generate-date-plan --project-ref jhpwacmsocjmzhimtbxj
supabase functions deploy generate-more-gifts --project-ref jhpwacmsocjmzhimtbxj
supabase functions deploy generate-playlist --project-ref jhpwacmsocjmzhimtbxj
supabase functions deploy rewrite-love-note --project-ref jhpwacmsocjmzhimtbxj
```

### Step 8 — Add basic per-user rate limiting (P1, can be a follow-up commit)

In each Edge Function, before calling OpenAI, check a simple in-memory or Postgres-backed counter:
- Max 20 generations per user per hour for `generate-date-plan`
- Max 10 per user per hour for `generate-more-gifts`
- Max 30 per user per hour for `rewrite-love-note`

If exceeded, return HTTP 429 with `{ error: "rate_limited", retryAfterSeconds: ... }`.

Simplest implementation: a `user_api_quotas` table with `user_id`, `endpoint`, `count_this_hour`, `hour_started_at`. Increment on each call; reset when hour rolls over.

This step is **optional for shipping** but high-value for cost protection. Acceptable to ship without it as long as it's tracked as P1.

---

## Verification checklist

Before marking done, confirm all of these pass:

- [ ] No file under `ios/` contains the string `api.openai.com` (other than comments)
- [ ] No file under `ios/` references `Config.openAIAPIKey` or `Config.openAIAPIEndpoint`
- [ ] `Config.swift` has no `OPENAI_*` properties
- [ ] `Info.plist` has no `OPENAI_API_KEY` key
- [ ] All four Edge Functions deploy cleanly: `supabase functions deploy <name>` returns success
- [ ] Generating a date plan from the iOS app (TestFlight build) returns successfully
- [ ] Generating gift suggestions from the iOS app returns successfully
- [ ] Rewriting a love note from the iOS app returns successfully
- [ ] Logging in as user A, calling `/generate-date-plan`, then logging out — manually trying to call the function with no JWT returns 401
- [ ] Build succeeds without OpenAI key in `Secrets.xcconfig`

## What's out of scope for this task

Don't tackle these here — separate Cursor briefs:
- Supabase anon key rotation (separate task — requires Supabase dashboard, not code)
- StoreKit 2 server-side receipt validation (separate Edge Function task)
- The migration `20260425120000_save_plan_date_requirement.sql` `user_id` index bug (15-min separate fix)

## When you're done

Tell me ("chief-of-staff, openai migration done") and I'll mark P0 #5 as complete, update the workflow doc, and route the next task.
