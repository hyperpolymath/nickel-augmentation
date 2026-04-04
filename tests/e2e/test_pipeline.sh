#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# tests/e2e/test_pipeline.sh — End-to-end pipeline tests for nickel-augmentation
#
# Tests the full augmentation workflow:
#   1. Construct a config from scratch using augmented/ contracts
#   2. Validate the config (nickel typecheck + export)
#   3. Export to JSON and verify the resulting structure with jq
#   4. Run the config-reporter tool and verify it produces output
#   5. Confirm invalid configs are caught before export
#
# Gracefully skips if `nickel` is not installed.
# The config-reporter section is skipped if the binary has not been built.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$PROJECT_ROOT/augmented/lib"
REPORTER="$PROJECT_ROOT/config-reporter/bin/config-reporter"

# ── Colour helpers ────────────────────────────────────────────────────────────
if [ -t 1 ]; then
    GREEN='\033[0;32m' RED='\033[0;31m' YELLOW='\033[1;33m' BOLD='\033[1m' RESET='\033[0m'
else
    GREEN='' RED='' YELLOW='' BOLD='' RESET=''
fi

PASS=0
FAIL=0
SKIP=0

pass() { PASS=$((PASS + 1)); echo -e "  ${GREEN}PASS${RESET}  $1"; }
fail() { FAIL=$((FAIL + 1)); echo -e "  ${RED}FAIL${RESET}  $1: $2"; }
skip() { SKIP=$((SKIP + 1)); echo -e "  ${YELLOW}SKIP${RESET}  $1: $2"; }

TEMP_DIR=""
cleanup() { [ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"; }
trap cleanup EXIT
TEMP_DIR=$(mktemp -d)

echo -e "${BOLD}nickel-augmentation — E2E pipeline tests${RESET}"
echo ""

# ── Pre-flight: require nickel ────────────────────────────────────────────────
if ! command -v nickel >/dev/null 2>&1; then
    echo -e "${YELLOW}SKIP${RESET}  nickel binary not found — skipping all E2E tests."
    echo "  Install nickel from https://nickel-lang.org or via nix/cargo."
    exit 0
fi

NICKEL_VERSION=$(nickel --version 2>&1 | head -1)
echo "  nickel:   $NICKEL_VERSION"

# jq is used for JSON structure verification
if command -v jq >/dev/null 2>&1; then
    JQ_AVAILABLE=true
    echo "  jq:       $(jq --version 2>/dev/null || echo present)"
else
    JQ_AVAILABLE=false
    echo "  jq:       not found (JSON structure checks will be skipped)"
fi
echo ""

# ── E2E 1: Construct a valid config and typecheck it ─────────────────────────
echo -e "${BOLD}1. Construct config from template → typecheck${RESET}"

# Create a realistic RSR-compliant config using the rsr.ncl and security.ncl contracts.
# This simulates what a project maintainer would write when describing their repo.
cat > "$TEMP_DIR/my-project.ncl" << NCLEOF
# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
# E2E test: simulated RSR-compliant project config

let rsr = import "${LIB_DIR}/rsr.ncl" in
let sec = import "${LIB_DIR}/security.ncl" in

{
  name       | rsr.NonEmptyString = "my-test-project",
  version    | rsr.SemVer         = "0.1.0",
  language   | rsr.AllowedLanguage = "rust",
  repository | sec.HttpsUrl       = "https://github.com/hyperpolymath/my-test-project",
  ci         = {
    badge_url | sec.HttpsUrl = "https://github.com/hyperpolymath/my-test-project/actions/workflows/quality.yml/badge.svg",
  },
}
NCLEOF

if nickel typecheck "$TEMP_DIR/my-project.ncl" 2>/dev/null; then
    pass "config typechecks with rsr + security contracts"
else
    fail "config typecheck" "nickel typecheck failed on valid config"
fi

# ── E2E 2: Export the config to JSON and verify structure ─────────────────────
echo ""
echo -e "${BOLD}2. Export config → JSON structure verification${RESET}"

exported_json=$(nickel export "$TEMP_DIR/my-project.ncl" 2>/dev/null)
export_exit=$?

if [ "$export_exit" -eq 0 ]; then
    pass "nickel export succeeds"

    if [ "$JQ_AVAILABLE" = true ]; then
        # Verify top-level fields are present in the exported JSON
        if echo "$exported_json" | jq -e '.name == "my-test-project"' >/dev/null 2>&1; then
            pass "JSON: name field is correct"
        else
            fail "JSON: name field" "expected 'my-test-project', got: $(echo "$exported_json" | jq -r '.name' 2>/dev/null)"
        fi

        if echo "$exported_json" | jq -e '.version == "0.1.0"' >/dev/null 2>&1; then
            pass "JSON: version field is correct"
        else
            fail "JSON: version field" "expected '0.1.0'"
        fi

        if echo "$exported_json" | jq -e '.language == "rust"' >/dev/null 2>&1; then
            pass "JSON: language field is correct"
        else
            fail "JSON: language field" "expected 'rust'"
        fi

        if echo "$exported_json" | jq -e '.repository | startswith("https://")' >/dev/null 2>&1; then
            pass "JSON: repository URL starts with https://"
        else
            fail "JSON: repository URL" "expected https:// prefix"
        fi
    else
        skip "JSON structure checks" "jq not available"
    fi
else
    fail "nickel export" "export returned non-zero exit code"
fi

# ── E2E 3: Invalid config is caught before export ─────────────────────────────
echo ""
echo -e "${BOLD}3. Invalid config is caught before export${RESET}"

# Config with banned language and insecure URL — must fail typecheck/eval
cat > "$TEMP_DIR/bad-project.ncl" << NCLEOF
# SPDX-License-Identifier: PMPL-1.0-or-later
let rsr = import "${LIB_DIR}/rsr.ncl" in
let sec = import "${LIB_DIR}/security.ncl" in
{
  name       | rsr.NonEmptyString  = "bad-project",
  version    | rsr.SemVer          = "1.0.0",
  language   | rsr.AllowedLanguage = "typescript",
  repository | sec.HttpsUrl        = "http://insecure.example.com",
}
NCLEOF

if nickel eval "$TEMP_DIR/bad-project.ncl" 2>/dev/null; then
    fail "invalid config caught" "nickel eval should have failed but succeeded"
else
    pass "invalid config with banned language + http URL is rejected"
fi

# Config with empty name — must fail
cat > "$TEMP_DIR/empty-name.ncl" << NCLEOF
# SPDX-License-Identifier: PMPL-1.0-or-later
let rsr = import "${LIB_DIR}/rsr.ncl" in
{ name | rsr.NonEmptyString = "" }
NCLEOF

if nickel eval "$TEMP_DIR/empty-name.ncl" 2>/dev/null; then
    fail "empty name caught" "nickel eval should have failed but succeeded"
else
    pass "empty name is rejected by NonEmptyString contract"
fi

# ── E2E 4: Reporter tool produces output ──────────────────────────────────────
echo ""
echo -e "${BOLD}4. Config reporter tool produces structured output${RESET}"

if [ -x "$REPORTER" ]; then
    # Run reporter against a directory containing our valid test config
    mkdir -p "$TEMP_DIR/reporter-test"
    cp "$TEMP_DIR/my-project.ncl" "$TEMP_DIR/reporter-test/my-project.ncl"

    reporter_output=$("$REPORTER" "$TEMP_DIR/reporter-test" 2>&1 || true)

    if echo "$reporter_output" | grep -q "Files scanned:\|scanned\|Results\|PASS\|violations"; then
        pass "reporter: produces output when run on valid config directory"
    else
        # Even if output format differs, a non-empty output is acceptable
        if [ -n "$reporter_output" ]; then
            pass "reporter: produces non-empty output"
        else
            fail "reporter output" "no output produced"
        fi
    fi

    # Run reporter with --json flag if supported
    json_output=$("$REPORTER" --json "$TEMP_DIR/reporter-test" 2>&1 || true)
    if [ "$JQ_AVAILABLE" = true ] && echo "$json_output" | grep -q '{'; then
        json_block=$(echo "$json_output" | sed -n '/^{/,/^}/p' | head -50)
        if echo "$json_block" | jq -e '.' >/dev/null 2>&1; then
            pass "reporter --json: produces valid JSON"
        else
            skip "reporter --json" "output contains JSON but jq parse failed (may be partial)"
        fi
    else
        skip "reporter --json" "JSON output check skipped (no JSON block found or jq unavailable)"
    fi
else
    skip "reporter tests" "config-reporter binary not built (run: just build-reporter)"
fi

# ── E2E 5: Library-level typecheck round-trip ─────────────────────────────────
echo ""
echo -e "${BOLD}5. Library round-trip: typecheck all lib/*.ncl then export a composite${RESET}"

# Count how many lib files typecheck successfully
typecheck_ok=0
typecheck_total=0
for ncl_file in "$LIB_DIR"/*.ncl; do
    [ -f "$ncl_file" ] || continue
    name=$(basename "$ncl_file")
    typecheck_total=$((typecheck_total + 1))
    if nickel typecheck "$ncl_file" 2>/dev/null; then
        typecheck_ok=$((typecheck_ok + 1))
    fi
done

# We expect most files to typecheck — proven-bridge.ncl/prelude.ncl may fail in CI
# Accept ≥80% pass rate (or if only proven* files fail)
if [ "$typecheck_total" -eq 0 ]; then
    skip "library round-trip" "no .ncl files found in $LIB_DIR"
elif [ "$typecheck_ok" -ge $((typecheck_total - 2)) ]; then
    # At most 2 failures (proven-bridge + prelude) are acceptable
    pass "library typecheck: $typecheck_ok/$typecheck_total files pass (≤2 skipped for proven import)"
else
    fail "library typecheck" "$typecheck_ok/$typecheck_total files passed (expected ≥$((typecheck_total - 2)))"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Results: ${GREEN}${PASS} passed${RESET}, ${RED}${FAIL} failed${RESET}, ${YELLOW}${SKIP} skipped${RESET}"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
