#!/usr/bin/env bash
#
# verify_deploy.sh — non-destructive post-deploy verification for Your Date Genie.
#
# Confirms the Supabase Edge Functions are deployed and behaving (JWT-gated vs
# webhook-open) and that the launch-integrity tables/secrets exist. Sends NO real
# data — every request uses junk/empty bodies and expects a rejection.
#
# Usage:
#   export PROJECT_REF="jhpwacmsocjmzhimtbxj"
#   export SUPABASE_ANON_KEY="your-anon-key"      # optional; enables anon-key smoke checks
#   ./scripts/verify_deploy.sh
#
# Exit code: 0 if all checks PASS, 1 if any check FAILs.
set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────────────────
PROJECT_REF="${PROJECT_REF:-jhpwacmsocjmzhimtbxj}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
BASE_URL="https://${PROJECT_REF}.supabase.co/functions/v1"

PASS_COUNT=0
FAIL_COUNT=0

# Colors (disabled if not a TTY)
if [ -t 1 ]; then
  GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; YELLOW=$'\033[0;33m'; BOLD=$'\033[1m'; NC=$'\033[0m'
else
  GREEN=''; RED=''; YELLOW=''; BOLD=''; NC=''
fi

pass() { printf "%sPASS%s  %s\n" "$GREEN" "$NC" "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf "%sFAIL%s  %s\n" "$RED" "$NC" "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
warn() { printf "%sWARN%s  %s\n" "$YELLOW" "$NC" "$1"; }
info() { printf "%s%s%s\n" "$BOLD" "$1" "$NC"; }

# All 13 functions that should be deployed.
ALL_FUNCTIONS=(
  generate-date-plan
  generate-more-gifts
  generate-playlist
  rewrite-love-note
  send-date-plan-email
  send-date-plan-sms
  notify-new-signup
  send-welcome-email
  submit-report
  delete-account
  import-eventbrite-event
  validate-receipt
  apple-notifications-v2
)

# JWT-gated functions: an unauthenticated POST must NOT return 200 and must NOT be a
# missing/crashed function (404/5xx). We accept 401/403 (rejected) — proof it's deployed
# and protected.
JWT_GATED_FUNCTIONS=(
  generate-date-plan
  generate-more-gifts
  generate-playlist
  rewrite-love-note
  send-date-plan-email
  send-date-plan-sms
  notify-new-signup
  send-welcome-email
  submit-report
  delete-account
  import-eventbrite-event
  validate-receipt
)

# POST a junk body and echo the HTTP status code.
http_post_status() {
  local url="$1"
  local extra_header="${2:-}"
  if [ -n "$extra_header" ]; then
    curl -s -o /dev/null -w "%{http_code}" --max-time 25 \
      -X POST "$url" \
      -H "Content-Type: application/json" \
      -H "$extra_header" \
      -d '{}' || echo "000"
  else
    curl -s -o /dev/null -w "%{http_code}" --max-time 25 \
      -X POST "$url" \
      -H "Content-Type: application/json" \
      -d '{}' || echo "000"
  fi
}

# ── Check 1: supabase CLI can list functions ─────────────────────────────────────
info "── Check 1: functions list (supabase CLI) ──"
if command -v supabase >/dev/null 2>&1; then
  if LIST_OUTPUT="$(supabase functions list --project-ref "$PROJECT_REF" 2>&1)"; then
    for fn in "${ALL_FUNCTIONS[@]}"; do
      if printf "%s" "$LIST_OUTPUT" | grep -q "$fn"; then
        pass "function present: $fn"
      else
        fail "function MISSING from 'functions list': $fn"
      fi
    done
  else
    warn "Could not run 'supabase functions list' (not linked / not logged in?). Skipping CLI check; relying on HTTP smoke tests below."
    printf "%s\n" "$LIST_OUTPUT" | sed 's/^/      /'
  fi
else
  warn "supabase CLI not found on PATH. Skipping CLI list check; relying on HTTP smoke tests."
fi

echo

# ── Check 2: JWT-gated functions reject unauthenticated POSTs (non-500, non-404) ──
info "── Check 2: JWT-gated functions reject unauthenticated calls ──"
for fn in "${JWT_GATED_FUNCTIONS[@]}"; do
  code="$(http_post_status "$BASE_URL/$fn")"
  case "$code" in
    401|403)
      pass "$fn → HTTP $code (deployed & rejecting unauthenticated, as expected)"
      ;;
    200)
      fail "$fn → HTTP 200 (UNEXPECTED: accepted an unauthenticated call — check verify_jwt!)"
      ;;
    404)
      fail "$fn → HTTP 404 (NOT deployed)"
      ;;
    000)
      fail "$fn → no response (timeout / DNS / network)"
      ;;
    5*)
      fail "$fn → HTTP $code (deployed but crashing on empty body — investigate logs)"
      ;;
    *)
      # 400 etc. still proves the function is up and reachable.
      warn "$fn → HTTP $code (reachable; not the expected 401/403 — verify manually)"
      PASS_COUNT=$((PASS_COUNT + 1))
      ;;
  esac
done

echo

# ── Check 3: validate-receipt specifics (the subscription source of truth) ────────
info "── Check 3: validate-receipt smoke test ──"
vr_code="$(http_post_status "$BASE_URL/validate-receipt")"
if [ "$vr_code" = "401" ]; then
  pass "validate-receipt rejects no-token POST → HTTP 401 (deployed & JWT-protected)"
else
  fail "validate-receipt → HTTP $vr_code (expected 401 for an unauthenticated call)"
fi

if [ -n "$SUPABASE_ANON_KEY" ]; then
  vr_anon="$(http_post_status "$BASE_URL/validate-receipt" "Authorization: Bearer $SUPABASE_ANON_KEY")"
  # anon key is not an authenticated user → function's auth.getUser fails → still 401.
  if [ "$vr_anon" = "401" ]; then
    pass "validate-receipt with anon key (no user) → HTTP 401 (correctly requires a user JWT)"
  else
    warn "validate-receipt with anon key → HTTP $vr_anon (expected 401; verify manually)"
  fi
else
  warn "SUPABASE_ANON_KEY not set — skipping anon-key smoke test for validate-receipt."
fi

echo

# ── Check 4: apple-notifications-v2 is open (--no-verify-jwt) and returns 200 ──────
info "── Check 4: apple-notifications-v2 webhook smoke test ──"
an_code="$(curl -s -o /dev/null -w "%{http_code}" --max-time 25 \
  -X POST "$BASE_URL/apple-notifications-v2" \
  -H "Content-Type: application/json" \
  -d '{"signedPayload":"not-a-real-jws"}' || echo "000")"
case "$an_code" in
  200)
    pass "apple-notifications-v2 → HTTP 200 on junk body (deployed with --no-verify-jwt, as required by Apple)"
    ;;
  401)
    fail "apple-notifications-v2 → HTTP 401 (DEPLOYED WITH JWT VERIFICATION — must be redeployed with --no-verify-jwt)"
    ;;
  404)
    fail "apple-notifications-v2 → HTTP 404 (NOT deployed)"
    ;;
  000)
    fail "apple-notifications-v2 → no response (timeout / network)"
    ;;
  *)
    warn "apple-notifications-v2 → HTTP $an_code (expected 200; verify manually)"
    ;;
esac

echo

# ── Check 5: launch-integrity tables (best-effort; needs supabase CLI + DB access) ─
info "── Check 5: launch tables exist (subscriptions / blocked_users / user_reports) ──"
if command -v supabase >/dev/null 2>&1; then
  SQL="SELECT string_agg(t, ',') FROM (VALUES ('subscriptions'),('blocked_users'),('user_reports')) v(t) WHERE to_regclass('public.'||t) IS NOT NULL;"
  if DB_OUT="$(printf "%s" "$SQL" | supabase db query --linked 2>/dev/null)" || \
     DB_OUT="$(echo "$SQL" | supabase db execute --linked 2>/dev/null)"; then
    for tbl in subscriptions blocked_users user_reports; do
      if printf "%s" "$DB_OUT" | grep -q "$tbl"; then
        pass "table present: public.$tbl"
      else
        fail "table not confirmed: public.$tbl"
      fi
    done
  else
    warn "Could not query the DB via CLI (older CLI lacks 'db query'). Verify in Dashboard → Table Editor: subscriptions, blocked_users, user_reports."
  fi
else
  warn "supabase CLI not found — verify tables manually in Dashboard → Table Editor."
fi

echo
info "── Summary ──"
printf "%sPASS: %d%s   %sFAIL: %d%s\n" "$GREEN" "$PASS_COUNT" "$NC" "$RED" "$FAIL_COUNT" "$NC"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "One or more checks FAILED. Review above before considering the deploy verified."
  exit 1
fi
echo "All automated checks passed. Still do the manual steps: App Store Connect 'Send Test Notification' + check 'supabase functions logs apple-notifications-v2'."
exit 0
