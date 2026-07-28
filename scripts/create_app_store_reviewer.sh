#!/usr/bin/env bash
# Creates (or updates) the App Store review demo account in Supabase.
#
# Required env:
#   SUPABASE_SERVICE_ROLE_KEY  — from Supabase Dashboard → Settings → API
#   REVIEWER_PASSWORD          — password Apple reviewers will use
#
# Optional env:
#   REVIEWER_EMAIL             — default appstore.review@yourdategenie.com
#   SUPABASE_URL               — default https://jhpwacmsocjmzhimtbxj.supabase.co

set -euo pipefail

PROJECT_URL="${SUPABASE_URL:-https://jhpwacmsocjmzhimtbxj.supabase.co}"
REVIEWER_EMAIL="${REVIEWER_EMAIL:-appstore.review@yourdategenie.com}"

if [[ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  echo "error: set SUPABASE_SERVICE_ROLE_KEY (Supabase Dashboard → Settings → API → service_role)" >&2
  exit 1
fi

if [[ -z "${REVIEWER_PASSWORD:-}" ]]; then
  echo "error: set REVIEWER_PASSWORD to the password for Apple reviewers" >&2
  exit 1
fi

AUTH_HEADER="Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}"
APIKEY_HEADER="apikey: ${SUPABASE_SERVICE_ROLE_KEY}"

echo "→ Review account email: ${REVIEWER_EMAIL}"

# ── 1. Create or locate auth user ────────────────────────────────────────────
CREATE_BODY=$(jq -n \
  --arg email "$REVIEWER_EMAIL" \
  --arg password "$REVIEWER_PASSWORD" \
  '{email: $email, password: $password, email_confirm: true, user_metadata: {display_name: "App Store Review"}}')

CREATE_RESP=$(curl -sS -w "\n%{http_code}" -X POST "${PROJECT_URL}/auth/v1/admin/users" \
  -H "$AUTH_HEADER" -H "$APIKEY_HEADER" -H "Content-Type: application/json" \
  -d "$CREATE_BODY")

CREATE_HTTP=$(echo "$CREATE_RESP" | tail -n1)
CREATE_JSON=$(echo "$CREATE_RESP" | sed '$d')

USER_ID=""

if [[ "$CREATE_HTTP" == "200" || "$CREATE_HTTP" == "201" ]]; then
  USER_ID=$(echo "$CREATE_JSON" | jq -r '.id // empty')
  echo "✓ Created auth user ${USER_ID}"
else
  echo "→ Create returned HTTP ${CREATE_HTTP}; looking up existing user…"
  LIST_RESP=$(curl -sS -G "${PROJECT_URL}/auth/v1/admin/users" \
    -H "$AUTH_HEADER" -H "$APIKEY_HEADER" \
    --data-urlencode "email=${REVIEWER_EMAIL}")

  USER_ID=$(echo "$LIST_RESP" | jq -r --arg email "$REVIEWER_EMAIL" '
    (.users // [])[] | select(.email == $email) | .id' | head -n1)

  if [[ -z "$USER_ID" ]]; then
    echo "error: could not create or find user. Response:" >&2
    echo "$CREATE_JSON" >&2
    exit 1
  fi

  echo "→ Found existing user ${USER_ID}; updating password…"
  UPDATE_RESP=$(curl -sS -w "\n%{http_code}" -X PUT "${PROJECT_URL}/auth/v1/admin/users/${USER_ID}" \
    -H "$AUTH_HEADER" -H "$APIKEY_HEADER" -H "Content-Type: application/json" \
    -d "$(jq -n --arg password "$REVIEWER_PASSWORD" '{password: $password, email_confirm: true}')")
  UPDATE_HTTP=$(echo "$UPDATE_RESP" | tail -n1)
  if [[ "$UPDATE_HTTP" != "200" ]]; then
    echo "error: failed to update password (HTTP ${UPDATE_HTTP})" >&2
    exit 1
  fi
  echo "✓ Password updated and email confirmed"
fi

# ── 2. Seed preferences ──────────────────────────────────────────────────────
PREFS_BODY=$(jq -n \
  --arg uid "$USER_ID" \
  '{
    user_id: $uid,
    default_city: "New York, NY",
    default_starting_point: "Times Square, New York, NY",
    default_neighborhood: "Manhattan",
    energy_level: "moderate",
    transportation_mode: "walking",
    travel_radius: "30min",
    cuisine_types: ["italian", "american"],
    activity_types: ["dining", "drinks", "entertainment"],
    drink_preferences: ["wine", "cocktails"],
    budget_range: "$$",
    gender: "woman",
    partner_gender: "man",
    love_languages: ["quality_time", "acts_of_service"],
    relationship_stage: "dating"
  }')

PREFS_HTTP=$(curl -sS -o /tmp/ydg_prefs_resp.txt -w "%{http_code}" -X POST "${PROJECT_URL}/rest/v1/preferences" \
  -H "$AUTH_HEADER" -H "$APIKEY_HEADER" -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates,return=minimal" \
  -d "$PREFS_BODY")

if [[ "$PREFS_HTTP" != "200" && "$PREFS_HTTP" != "201" && "$PREFS_HTTP" != "204" ]]; then
  echo "⚠ Preferences seed failed (HTTP ${PREFS_HTTP}). Login still works — reviewer can pick NYC in the questionnaire."
  echo "  Details: $(cat /tmp/ydg_prefs_resp.txt 2>/dev/null || true)"
  echo "  Fix: apply pending Supabase migrations (user_preferences.default_starting_point sync trigger)."
else
  echo "✓ Preferences seeded (NYC, questionnaire defaults)"
fi

# ── 3. Grant trialing Premium subscription ───────────────────────────────────
curl -sS -o /dev/null -X DELETE \
  "${PROJECT_URL}/rest/v1/subscriptions?user_id=eq.${USER_ID}&platform=eq.ios&original_transaction_id=eq.appstore-review-demo" \
  -H "$AUTH_HEADER" -H "$APIKEY_HEADER"

SUB_BODY=$(jq -n \
  --arg uid "$USER_ID" \
  '{
    user_id: $uid,
    platform: "ios",
    product_id: "com.yourdategenie.premium.annual",
    original_transaction_id: "appstore-review-demo",
    latest_transaction_id: "appstore-review-demo",
    status: "trialing",
    tier: "premium",
    started_at: "2026-07-04T00:00:00Z",
    current_period_start: "2026-07-04T00:00:00Z",
    current_period_end: "2027-07-04T00:00:00Z",
    trial_end_at: "2027-07-04T00:00:00Z"
  }')

SUB_HTTP=$(curl -sS -o /dev/null -w "%{http_code}" -X POST "${PROJECT_URL}/rest/v1/subscriptions" \
  -H "$AUTH_HEADER" -H "$APIKEY_HEADER" -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$SUB_BODY")

if [[ "$SUB_HTTP" != "200" && "$SUB_HTTP" != "201" && "$SUB_HTTP" != "204" ]]; then
  echo "error: subscription insert failed (HTTP ${SUB_HTTP})" >&2
  exit 1
fi
echo "✓ Premium trialing subscription granted"

# ── 4. Profile display name ──────────────────────────────────────────────────
PROFILE_BODY=$(jq -n --arg uid "$USER_ID" '{user_id: $uid, display_name: "App Store Review"}')
curl -sS -o /dev/null -X POST "${PROJECT_URL}/rest/v1/profiles" \
  -H "$AUTH_HEADER" -H "$APIKEY_HEADER" -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates,return=minimal" \
  -d "$PROFILE_BODY" || true

echo ""
echo "Done. Add these credentials to App Store Connect → App Review Information:"
echo "  Username: ${REVIEWER_EMAIL}"
echo "  Password: (your REVIEWER_PASSWORD value)"
echo ""
echo "Full notes template: app-store/APP_STORE_REVIEW_ACCOUNT.md"
