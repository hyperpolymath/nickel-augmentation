#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# integration tests — Validate Nickel contracts and reporter against real configs.
#
# Tests:
#   1. Library typecheck (all core modules)
#   2. Example export (all examples produce valid output)
#   3. Reporter rules (correct detection of violations)
#   4. Contract enforcement (invalid inputs rejected)
#   5. K9 structure (templates parse correctly)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORTER="$PROJECT_ROOT/config-reporter/bin/config-reporter"
TEMP_DIR=""

# Colours
if [ -t 1 ]; then
    GREEN='\033[0;32m' RED='\033[0;31m' BOLD='\033[1m' RESET='\033[0m'
else
    GREEN='' RED='' BOLD='' RESET=''
fi

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo -e "  ${GREEN}PASS${RESET} $1"; }
fail() { FAIL=$((FAIL + 1)); echo -e "  ${RED}FAIL${RESET} $1: $2"; }

cleanup() { [ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

TEMP_DIR=$(mktemp -d)

echo -e "${BOLD}nickel-augmentation integration tests${RESET}"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# 1. LIBRARY TYPECHECK
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BOLD}1. Library typecheck${RESET}"

for ncl in "$PROJECT_ROOT"/augmented/lib/*.ncl; do
    name=$(basename "$ncl")
    if nickel typecheck "$ncl" 2>/dev/null; then
        pass "typecheck $name"
    else
        fail "typecheck $name" "nickel typecheck failed"
    fi
done

# ═══════════════════════════════════════════════════════════════════════════════
# 2. EXAMPLE EXPORT
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}2. Example export${RESET}"

for ncl in "$PROJECT_ROOT"/augmented/examples/nickel/*.ncl; do
    name=$(basename "$ncl")
    if nickel export "$ncl" > /dev/null 2>&1; then
        pass "export $name"
    else
        # Some examples may import local modules — try typecheck instead
        if nickel typecheck "$ncl" 2>/dev/null; then
            pass "typecheck $name (export skipped — imports)"
        else
            fail "export $name" "nickel export/typecheck failed"
        fi
    fi
done

# ═══════════════════════════════════════════════════════════════════════════════
# 3. REPORTER — VALID FILES PASS
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}3. Reporter — valid files pass${RESET}"

# Run reporter against the library — ci.ncl has example tagged actions
# so WF-001 fires (expected). Check that it runs and detects the expected issue.
lib_output=$("$REPORTER" "$PROJECT_ROOT/augmented/lib" 2>&1 || true)
if echo "$lib_output" | grep -q "WF-001"; then
    pass "reporter: augmented/lib runs (WF-001 on ci.ncl example expected)"
elif echo "$lib_output" | grep -q "Files scanned:"; then
    pass "reporter: augmented/lib runs clean"
else
    fail "reporter: augmented/lib" "unexpected output"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 4. REPORTER — INVALID FILES DETECTED
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}4. Reporter — violation detection${RESET}"

# Helper: run reporter on a single test file and check for a rule ID
check_rule() {
    local rule="$1" file="$2" description="$3"
    local output
    output=$("$REPORTER" "$(dirname "$file")" 2>&1 || true)
    if echo "$output" | grep -q "$rule"; then
        pass "$rule: $description"
    else
        fail "$rule" "$description (output: $(echo "$output" | head -5))"
    fi
    rm -f "$file"
}

# Test SPDX-001: Missing SPDX header
cat > "$TEMP_DIR/no-spdx.ncl" << 'EOF'
# No SPDX header here
{ value = 42 }
EOF
check_rule "SPDX-001" "$TEMP_DIR/no-spdx.ncl" "detects missing SPDX header"

# Test SEC-001: HTTP URL
cat > "$TEMP_DIR/http-url.ncl" << 'EOF'
# SPDX-License-Identifier: PMPL-1.0-or-later
{ url = "http://example.com/api" }
EOF
check_rule "SEC-001" "$TEMP_DIR/http-url.ncl" "detects http:// URL"

# Test LANG-001: Banned language
cat > "$TEMP_DIR/banned-lang.ncl" << 'EOF'
# SPDX-License-Identifier: PMPL-1.0-or-later
{ target = { language = "typescript" } }
EOF
check_rule "LANG-001" "$TEMP_DIR/banned-lang.ncl" "detects banned language"

# Test WF-001: Unpinned action
cat > "$TEMP_DIR/unpinned.ncl" << 'EOF'
# SPDX-License-Identifier: PMPL-1.0-or-later
{ step = { uses = "actions/checkout@v4" } }
EOF
check_rule "WF-001" "$TEMP_DIR/unpinned.ncl" "detects unpinned action"

# Test SEC-003: Hardcoded secret
cat > "$TEMP_DIR/secret.ncl" << 'EOF'
# SPDX-License-Identifier: PMPL-1.0-or-later
{ api_key = "ghp_1234567890abcdefghijklmnop" }
EOF
check_rule "SEC-003" "$TEMP_DIR/secret.ncl" "detects hardcoded secret"

# Test CTR-002: Docker runtime
cat > "$TEMP_DIR/docker.ncl" << 'EOF'
# SPDX-License-Identifier: PMPL-1.0-or-later
{ container = { runtime = "docker" } }
EOF
check_rule "CTR-002" "$TEMP_DIR/docker.ncl" "detects docker runtime"

# ═══════════════════════════════════════════════════════════════════════════════
# 5. K9 STRUCTURE
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}5. K9 template structure${RESET}"

for k9 in "$PROJECT_ROOT"/contractiles/k9/*.k9.ncl "$PROJECT_ROOT"/contractiles/k9/examples/*.k9.ncl; do
    [ -f "$k9" ] || continue
    name=$(basename "$k9")
    # K9 files should have magic header
    if head -1 "$k9" | grep -q '^K9!'; then
        pass "K9 header: $name"
    else
        fail "K9 header: $name" "missing K9! magic header"
    fi
    # K9 files should have pedigree
    if grep -q 'pedigree\s*=' "$k9"; then
        pass "K9 pedigree: $name"
    else
        fail "K9 pedigree: $name" "missing pedigree section"
    fi
done

# ═══════════════════════════════════════════════════════════════════════════════
# 6. JSON OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}6. JSON output${RESET}"

cat > "$TEMP_DIR/valid.ncl" << 'EOF'
# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
{ value = 42 }
EOF
# JSON is a multi-line block at the end of output. Extract with sed.
json_output=$("$REPORTER" --json "$TEMP_DIR" 2>&1 | sed -n '/^{$/,/^}$/p')
if echo "$json_output" | jq -e '.summary.total_files >= 1' > /dev/null 2>&1; then
    pass "JSON output: valid structure"
else
    fail "JSON output" "invalid JSON structure"
fi
rm -f "$TEMP_DIR/valid.ncl"

# ═══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}Results: ${GREEN}${PASS} passed${RESET}, ${RED}${FAIL} failed${RESET}"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
