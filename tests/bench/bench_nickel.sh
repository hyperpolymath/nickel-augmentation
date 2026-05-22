#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# tests/bench/bench_nickel.sh — Benchmarks for Nickel config evaluation
#
# Times nickel export/typecheck for each .ncl file in augmented/lib/ and
# augmented/examples/nickel/. Prints results in a formatted table.
#
# Usage:
#   bash tests/bench/bench_nickel.sh
#   bash tests/bench/bench_nickel.sh --runs 5       (default: 3 runs each)
#
# Output format: file | runs | min_ms | avg_ms | max_ms
#
# Gracefully skips if `nickel` is not installed.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$PROJECT_ROOT/augmented/lib"
EXAMPLES_DIR="$PROJECT_ROOT/augmented/examples/nickel"

# ── Parse arguments ───────────────────────────────────────────────────────────
RUNS=3
while [[ $# -gt 0 ]]; do
    case "$1" in
        --runs) RUNS="${2:-3}"; shift 2 ;;
        *) shift ;;
    esac
done

# ── Colour helpers ────────────────────────────────────────────────────────────
if [ -t 1 ]; then
    GREEN='\033[0;32m' YELLOW='\033[1;33m' BOLD='\033[1m' CYAN='\033[0;36m' RESET='\033[0m'
else
    GREEN='' YELLOW='' BOLD='' CYAN='' RESET=''
fi

echo -e "${BOLD}nickel-augmentation — Benchmarks${RESET}"
echo ""

# ── Pre-flight: require nickel ────────────────────────────────────────────────
if ! command -v nickel >/dev/null 2>&1; then
    echo -e "${YELLOW}SKIP${RESET}  nickel binary not found — skipping benchmarks."
    echo "  Install nickel from https://nickel-lang.org or via nix/cargo."
    exit 0
fi

NICKEL_VERSION=$(nickel --version 2>&1 | head -1)
echo "  nickel: $NICKEL_VERSION"
echo "  runs per file: $RUNS"
echo ""

# ── Benchmark function ────────────────────────────────────────────────────────
# bench_file FILE OPERATION
# OPERATION is "export" or "typecheck".
# Returns: min_ms avg_ms max_ms via stdout (space-separated).
bench_file() {
    local file="$1"
    local op="${2:-export}"
    local min_ms=99999
    local max_ms=0
    local total_ms=0
    local succeeded=0

    for (( i=0; i < RUNS; i++ )); do
        local start_ns end_ns elapsed_ms
        start_ns=$(date +%s%N 2>/dev/null || echo 0)

        if [ "$op" = "typecheck" ]; then
            nickel typecheck "$file" >/dev/null 2>&1 || true
        else
            nickel export "$file" >/dev/null 2>&1 || true
        fi

        end_ns=$(date +%s%N 2>/dev/null || echo 0)

        # Fallback if nanosecond timestamps not available (macOS date)
        if [ "$start_ns" = "0" ]; then
            elapsed_ms=0
        else
            elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
        fi

        total_ms=$((total_ms + elapsed_ms))
        succeeded=$((succeeded + 1))

        if [ "$elapsed_ms" -lt "$min_ms" ]; then min_ms=$elapsed_ms; fi
        if [ "$elapsed_ms" -gt "$max_ms" ]; then max_ms=$elapsed_ms; fi
    done

    local avg_ms=0
    [ "$succeeded" -gt 0 ] && avg_ms=$((total_ms / succeeded))

    echo "$min_ms $avg_ms $max_ms"
}

# ── Print header ──────────────────────────────────────────────────────────────
print_header() {
    printf "${BOLD}%-45s  %-10s  %7s  %7s  %7s${RESET}\n" \
        "File" "Operation" "Min(ms)" "Avg(ms)" "Max(ms)"
    printf "%-45s  %-10s  %7s  %7s  %7s\n" \
        "$(printf '%0.s-' {1..45})" "----------" "-------" "-------" "-------"
}

print_row() {
    local name="$1" op="$2" min_ms="$3" avg_ms="$4" max_ms="$5"
    local color=""
    # Colour-code by speed: <50ms green, 50-200ms default, >200ms yellow
    [ "$avg_ms" -lt 50 ]  && color="$GREEN"
    [ "$avg_ms" -gt 200 ] && color="$YELLOW"
    printf "${color}%-45s  %-10s  %7d  %7d  %7d${RESET}\n" \
        "$name" "$op" "$min_ms" "$avg_ms" "$max_ms"
}

# ── Section 1: Benchmark lib/*.ncl (typecheck) ───────────────────────────────
echo -e "${BOLD}augmented/lib/*.ncl — typecheck${RESET}"
print_header

total_lib=0
for ncl_file in "$LIB_DIR"/*.ncl; do
    [ -f "$ncl_file" ] || continue
    name=$(basename "$ncl_file")
    # proven-bridge.ncl may fail typecheck in isolation — still time it
    read -r min_ms avg_ms max_ms <<< "$(bench_file "$ncl_file" typecheck)"
    print_row "$name" "typecheck" "$min_ms" "$avg_ms" "$max_ms"
    total_lib=$((total_lib + avg_ms))
done
echo ""
echo "  Total average (lib typecheck): ${total_lib}ms"

# ── Section 2: Benchmark lib/*.ncl (export where possible) ───────────────────
echo ""
echo -e "${BOLD}augmented/lib/*.ncl — export (files that export cleanly)${RESET}"
print_header

for ncl_file in "$LIB_DIR"/*.ncl; do
    [ -f "$ncl_file" ] || continue
    name=$(basename "$ncl_file")
    # Only benchmark files that export successfully
    if nickel export "$ncl_file" >/dev/null 2>&1; then
        read -r min_ms avg_ms max_ms <<< "$(bench_file "$ncl_file" export)"
        print_row "$name" "export" "$min_ms" "$avg_ms" "$max_ms"
    else
        printf "%-45s  %-10s  %7s  %7s  %7s\n" "$name" "export" "N/A" "N/A" "N/A"
    fi
done

# ── Section 3: Benchmark examples/*.ncl ──────────────────────────────────────
echo ""
echo -e "${BOLD}augmented/examples/nickel/*.ncl — export${RESET}"
print_header

for ncl_file in "$EXAMPLES_DIR"/*.ncl; do
    [ -f "$ncl_file" ] || continue
    name=$(basename "$ncl_file")
    if nickel export "$ncl_file" >/dev/null 2>&1; then
        read -r min_ms avg_ms max_ms <<< "$(bench_file "$ncl_file" export)"
        print_row "$name" "export" "$min_ms" "$avg_ms" "$max_ms"
    else
        printf "%-45s  %-10s  %7s  %7s  %7s\n" "$name" "export" "N/A" "N/A" "N/A"
    fi
done

# ── Section 4: Synthetic complexity benchmark ─────────────────────────────────
# Creates progressively larger Nickel records and measures evaluation scaling.
echo ""
echo -e "${BOLD}Synthetic scaling benchmark — record size growth${RESET}"
print_header

for n_fields in 10 50 100 500; do
    # Generate a Nickel record with n_fields numeric entries
    ncl_content="# SPDX-License-Identifier: MPL-2.0
{"
    for (( i=1; i<=n_fields; i++ )); do
        ncl_content+="
  field_$i = $i,"
    done
    ncl_content="
}"
    echo "$ncl_content" > "$TEMP_DIR/synthetic_${n_fields}.ncl"
    read -r min_ms avg_ms max_ms <<< "$(bench_file "$TEMP_DIR/synthetic_${n_fields}.ncl" export)"
    print_row "synthetic_${n_fields}_fields.ncl" "export" "$min_ms" "$avg_ms" "$max_ms"
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Benchmark complete.${RESET}"
echo "  Each file was evaluated $RUNS times; min/avg/max are reported in milliseconds."
echo "  Times include nickel startup overhead — relative comparisons are more meaningful."
