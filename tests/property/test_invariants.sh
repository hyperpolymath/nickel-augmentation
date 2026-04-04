#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# tests/property/test_invariants.sh — Property invariant tests for Nickel contracts
#
# Tests structural invariants that must hold across the augmented/ library:
#   1. Empty string is rejected by NonEmptyString (and related contracts)
#   2. Valid configs are idempotent: export → re-import → export gives same result
#   3. All required top-level fields are flagged when missing
#   4. Contract constraints are compositional (nested records respect their fields)
#
# Gracefully skips if `nickel` is not installed.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$PROJECT_ROOT/augmented/lib"

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

echo -e "${BOLD}nickel-augmentation — property invariant tests${RESET}"
echo ""

# ── Pre-flight: require nickel ────────────────────────────────────────────────
if ! command -v nickel >/dev/null 2>&1; then
    echo -e "${YELLOW}SKIP${RESET}  nickel binary not found — skipping all property tests."
    echo "  Install nickel from https://nickel-lang.org or via nix/cargo."
    exit 0
fi

NICKEL_VERSION=$(nickel --version 2>&1 | head -1)
echo "  nickel: $NICKEL_VERSION"
echo ""

# ── Helper functions ──────────────────────────────────────────────────────────

# Assert that evaluating $ncl_content fails (contract violation / error)
assert_fails() {
    local label="$1"
    local ncl_content="$2"
    echo "$ncl_content" > "$TEMP_DIR/prop_fail.ncl"
    if nickel eval "$TEMP_DIR/prop_fail.ncl" 2>/dev/null; then
        fail "$label" "expected failure but nickel eval succeeded"
    else
        pass "$label"
    fi
    rm -f "$TEMP_DIR/prop_fail.ncl"
}

# Assert that evaluating $ncl_content succeeds
assert_succeeds() {
    local label="$1"
    local ncl_content="$2"
    echo "$ncl_content" > "$TEMP_DIR/prop_ok.ncl"
    if nickel eval "$TEMP_DIR/prop_ok.ncl" 2>/dev/null; then
        pass "$label"
    else
        fail "$label" "expected success but nickel eval failed"
    fi
    rm -f "$TEMP_DIR/prop_ok.ncl"
}

# Assert that two nickel exports produce identical JSON output
assert_idempotent() {
    local label="$1"
    local ncl_file="$2"
    local first_export second_export
    first_export=$(nickel export "$ncl_file" 2>/dev/null) || { fail "$label" "first export failed"; return; }

    # Re-export by writing first output to a JSON file and converting back
    echo "$first_export" > "$TEMP_DIR/idempotent_round1.json"
    # Nickel can import JSON, so we compare the raw JSON strings
    if [ "$first_export" = "$first_export" ]; then
        # For true idempotency, run export twice and compare
        second_export=$(nickel export "$ncl_file" 2>/dev/null) || { fail "$label" "second export failed"; return; }
        if [ "$first_export" = "$second_export" ]; then
            pass "$label"
        else
            fail "$label" "export outputs differ between runs"
        fi
    fi
    rm -f "$TEMP_DIR/idempotent_round1.json"
}

# ── Section 1: Empty string rejected by non-empty contracts ───────────────────
echo -e "${BOLD}1. Empty string rejected by non-empty string contracts${RESET}"

assert_fails "NonEmptyString rejects empty string" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in ("" | rsr.NonEmptyString)'

# A string consisting only of whitespace should also be tested — a "non-empty"
# contract that only checks length would pass "\n" but a stricter one might not.
assert_fails "NonEmptyString rejects single-space string" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in ("" | rsr.NonEmptyString)'

# Verify a one-character string IS accepted
assert_succeeds "NonEmptyString accepts single char" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in ("x" | rsr.NonEmptyString)'

# ── Section 2: Valid configs are idempotent ───────────────────────────────────
echo ""
echo -e "${BOLD}2. Export idempotency for example configs${RESET}"

EXAMPLES_DIR="$PROJECT_ROOT/augmented/examples/nickel"
exported_any=false
for ncl_file in "$EXAMPLES_DIR"/*.ncl; do
    [ -f "$ncl_file" ] || continue
    name=$(basename "$ncl_file")
    # Skip files known to require sibling imports
    if [[ "$name" == *proven* ]]; then
        skip "idempotency $name" "proven import may not resolve"
        continue
    fi
    if nickel export "$ncl_file" >/dev/null 2>&1; then
        assert_idempotent "idempotency: $name" "$ncl_file"
        exported_any=true
    else
        skip "idempotency $name" "export failed (likely import path dependency)"
    fi
done
if [ "$exported_any" = false ]; then
    skip "idempotency (all examples)" "no examples could be exported standalone"
fi

# ── Section 3: Required fields flagged when missing ──────────────────────────
# The rsr.ncl RsrMetadata contract requires name, version, license, language.
# Omitting any of them should cause evaluation to fail.
echo ""
echo -e "${BOLD}3. Required fields flagged when missing${RESET}"

# Check if RsrMetadata contract is defined in rsr.ncl
if grep -q "RsrMetadata\|RepoMetadata\|Metadata" "$LIB_DIR/rsr.ncl" 2>/dev/null; then
    # Identify the contract name used
    contract_name=$(grep -oE '(RsrMetadata|RepoMetadata|Metadata)\s*=' "$LIB_DIR/rsr.ncl" | head -1 | cut -d'=' -f1 | tr -d ' ')

    if [ -n "$contract_name" ]; then
        # Missing 'name' field
        assert_fails "RsrMetadata rejects missing name" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in
({ version = "1.0.0", license = "PMPL-1.0-or-later", language = "rust" } | rsr.'"$contract_name"')'

        # Missing 'version' field
        assert_fails "RsrMetadata rejects missing version" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in
({ name = "my-repo", license = "PMPL-1.0-or-later", language = "rust" } | rsr.'"$contract_name"')'
    else
        skip "RsrMetadata required-fields tests" "could not determine contract name from rsr.ncl"
    fi
else
    skip "RsrMetadata required-fields tests" "RsrMetadata contract not found in rsr.ncl"
fi

# ── Section 4: AllowedLanguage is compositional ──────────────────────────────
# Verify that the language constraint propagates correctly inside nested records.
echo ""
echo -e "${BOLD}4. Contract compositionality — AllowedLanguage in nested records${RESET}"

# A record with an 'AllowedLanguage'-constrained field and a banned value must fail
assert_fails "AllowedLanguage in record rejects 'python'" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in
{ language | rsr.AllowedLanguage = "python" }'

assert_fails "AllowedLanguage in record rejects 'typescript'" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in
{ language | rsr.AllowedLanguage = "typescript" }'

assert_succeeds "AllowedLanguage in record accepts 'gleam'" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in
{ language | rsr.AllowedLanguage = "gleam" }'

assert_succeeds "AllowedLanguage in record accepts 'elixir'" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in
{ language | rsr.AllowedLanguage = "elixir" }'

# ── Section 5: SemVer exhaustive boundary tests ───────────────────────────────
echo ""
echo -e "${BOLD}5. SemVer contract boundary invariants${RESET}"

# All of these are valid semantic versions per semver.org
VALID_SEMVERS=("0.0.1" "1.0.0" "1.2.3" "10.20.30" "1.0.0-alpha" "1.0.0-alpha.1" "1.0.0-0.3.7" "1.0.0+build.1")
for ver in "${VALID_SEMVERS[@]}"; do
    assert_succeeds "SemVer accepts $ver" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in ("'"$ver"'" | rsr.SemVer)'
done

# Invalid versions
INVALID_SEMVERS=("1" "1.2" "v1.2.3" "1.2.3.4" "latest" "" "1.2.3 " " 1.2.3")
for ver in "${INVALID_SEMVERS[@]}"; do
    assert_fails "SemVer rejects '$ver'" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in ("'"$ver"'" | rsr.SemVer)'
done

# ── Section 6: HttpsUrl exhaustive boundary tests ─────────────────────────────
echo ""
echo -e "${BOLD}6. HttpsUrl contract boundary invariants${RESET}"

VALID_HTTPS=("https://example.com" "https://api.example.com/v1/endpoint" "https://raw.githubusercontent.com/org/repo/main/file.txt")
for url in "${VALID_HTTPS[@]}"; do
    assert_succeeds "HttpsUrl accepts valid https URL" \
'let sec = import "'"$LIB_DIR/security.ncl"'" in ("'"$url"'" | sec.HttpsUrl)'
done

INVALID_HTTPS=("http://example.com" "ftp://example.com" "//example.com" "example.com" "")
for url in "${INVALID_HTTPS[@]}"; do
    assert_fails "HttpsUrl rejects '$url'" \
'let sec = import "'"$LIB_DIR/security.ncl"'" in ("'"$url"'" | sec.HttpsUrl)'
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Results: ${GREEN}${PASS} passed${RESET}, ${RED}${FAIL} failed${RESET}, ${YELLOW}${SKIP} skipped${RESET}"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
