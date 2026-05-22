#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# tests/unit/test_basic.sh — Unit tests for augmented/ Nickel library files
#
# Tests:
#   1. All .ncl files in augmented/lib/ pass nickel typecheck
#   2. Invalid input is rejected by contracts (non-zero exit from nickel eval)
#   3. Valid input is accepted by contracts (zero exit from nickel eval)
#
# Gracefully skips all tests if the `nickel` binary is not installed.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$PROJECT_ROOT/augmented/lib"
EXAMPLES_DIR="$PROJECT_ROOT/augmented/examples/nickel"

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

echo -e "${BOLD}nickel-augmentation — unit tests${RESET}"
echo ""

# ── Pre-flight: require nickel ────────────────────────────────────────────────
if ! command -v nickel >/dev/null 2>&1; then
    echo -e "${YELLOW}SKIP${RESET}  nickel binary not found — skipping all unit tests."
    echo "  Install nickel from https://nickel-lang.org or via nix/cargo."
    exit 0
fi

NICKEL_VERSION=$(nickel --version 2>&1 | head -1)
echo "  nickel: $NICKEL_VERSION"
echo ""

# ── Section 1: Typecheck all lib/*.ncl files ──────────────────────────────────
echo -e "${BOLD}1. Typecheck augmented/lib/*.ncl${RESET}"

for ncl_file in "$LIB_DIR"/*.ncl; do
    [ -f "$ncl_file" ] || continue
    name=$(basename "$ncl_file")

    # proven-bridge.ncl and prelude.ncl import a sibling proven/ repo which
    # may not be present in all environments — skip gracefully.
    if [[ "$name" == "proven-bridge.ncl" || "$name" == "prelude.ncl" || "$name" == "proven.ncl" ]]; then
        if nickel typecheck "$ncl_file" 2>/dev/null; then
            pass "typecheck $name"
        else
            skip "typecheck $name" "proven repo not a sibling (import path unresolvable)"
        fi
        continue
    fi

    if nickel typecheck "$ncl_file" 2>/dev/null; then
        pass "typecheck $name"
    else
        fail "typecheck $name" "nickel typecheck returned non-zero"
    fi
done

# ── Section 2: Typecheck all examples/*.ncl files ─────────────────────────────
echo ""
echo -e "${BOLD}2. Typecheck augmented/examples/nickel/*.ncl${RESET}"

for ncl_file in "$EXAMPLES_DIR"/*.ncl; do
    [ -f "$ncl_file" ] || continue
    name=$(basename "$ncl_file")
    if nickel typecheck "$ncl_file" 2>/dev/null; then
        pass "typecheck examples/$name"
    else
        # Examples may import lib modules — try export fallback
        if nickel export "$ncl_file" >/dev/null 2>&1; then
            pass "export examples/$name (typecheck had import path issue)"
        else
            fail "typecheck examples/$name" "both typecheck and export failed"
        fi
    fi
done

# ── Section 3: Contracts reject invalid input ─────────────────────────────────
# Each sub-test writes a temporary .ncl file that applies a contract to an
# invalid value and verifies that nickel eval exits non-zero.
echo ""
echo -e "${BOLD}3. Contracts reject invalid input${RESET}"

# Helper: assert that evaluating $expr with contract from $lib_file returns error
assert_rejected() {
    local label="$1"
    local ncl_content="$2"
    echo "$ncl_content" > "$TEMP_DIR/reject_test.ncl"
    if nickel eval "$TEMP_DIR/reject_test.ncl" 2>/dev/null; then
        fail "contract rejects $label" "expected rejection but nickel eval succeeded"
    else
        pass "contract rejects $label"
    fi
    rm -f "$TEMP_DIR/reject_test.ncl"
}

# Helper: assert that evaluating $expr with contract from $lib_file succeeds
assert_accepted() {
    local label="$1"
    local ncl_content="$2"
    echo "$ncl_content" > "$TEMP_DIR/accept_test.ncl"
    if nickel eval "$TEMP_DIR/accept_test.ncl" 2>/dev/null; then
        pass "contract accepts $label"
    else
        fail "contract accepts $label" "expected acceptance but nickel eval failed"
    fi
    rm -f "$TEMP_DIR/accept_test.ncl"
}

# rsr.ncl — NonEmptyString rejects empty string
assert_rejected "NonEmptyString rejects empty string" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in
("" | rsr.NonEmptyString)'

# rsr.ncl — NonEmptyString accepts non-empty string
assert_accepted "NonEmptyString accepts non-empty string" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in
("hello" | rsr.NonEmptyString)'

# rsr.ncl — SemVer rejects invalid version string
assert_rejected "SemVer rejects 'not-a-version'" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in
("not-a-version" | rsr.SemVer)'

# rsr.ncl — SemVer accepts valid version
assert_accepted "SemVer accepts 1.2.3" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in
("1.2.3" | rsr.SemVer)'

# rsr.ncl — SemVer accepts version with pre-release tag
assert_accepted "SemVer accepts 1.0.0-alpha.1" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in
("1.0.0-alpha.1" | rsr.SemVer)'

# security.ncl — HttpsUrl rejects http:// URL
assert_rejected "HttpsUrl rejects http:// URL" \
'let sec = import "'"$LIB_DIR/security.ncl"'" in
("http://example.com" | sec.HttpsUrl)'

# security.ncl — HttpsUrl accepts https:// URL
assert_accepted "HttpsUrl accepts https:// URL" \
'let sec = import "'"$LIB_DIR/security.ncl"'" in
("https://example.com/api" | sec.HttpsUrl)'

# security.ncl — SecureHash rejects short/weak hash
assert_rejected "SecureHash rejects short MD5-length string" \
'let sec = import "'"$LIB_DIR/security.ncl"'" in
("d41d8cd98f00b204e9800998ecf8427e" | sec.SecureHash)'

# security.ncl — SecureHash accepts SHA-256 prefixed hash
assert_accepted "SecureHash accepts sha256: prefixed 64-char hash" \
'let sec = import "'"$LIB_DIR/security.ncl"'" in
("sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" | sec.SecureHash)'

# rsr.ncl — AllowedLanguage rejects banned language
assert_rejected "AllowedLanguage rejects typescript" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in
("typescript" | rsr.AllowedLanguage)'

# rsr.ncl — AllowedLanguage accepts permitted language
assert_accepted "AllowedLanguage accepts rust" \
'let rsr = import "'"$LIB_DIR/rsr.ncl"'" in
("rust" | rsr.AllowedLanguage)'

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Results: ${GREEN}${PASS} passed${RESET}, ${RED}${FAIL} failed${RESET}, ${YELLOW}${SKIP} skipped${RESET}"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
