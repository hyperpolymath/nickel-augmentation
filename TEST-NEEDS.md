# TEST-NEEDS.md — nickel-augmentation

> Generated 2026-03-29 by punishing audit.

## Current State

| Category     | Count | Notes |
|-------------|-------|-------|
| Unit tests   | 0     | None |
| Integration  | 1     | tests/integration/test_contracts.sh |
| E2E          | 0     | None |
| Benchmarks   | 0     | None |

**Source modules:** ~19 Nickel (.ncl) files in augmented/ and config-reporter/ directories. Config language library and reporter tool.

## What's Missing

### P2P (Property-Based) Tests
- [ ] Contract validation: property tests for all Nickel contracts
- [ ] Config generation: arbitrary input config property tests

### E2E Tests
- [ ] Full augmentation pipeline: input config -> augment -> validate -> output
- [ ] Reporter: generate report from augmented config
- [ ] Contract enforcement: valid and invalid config rejection/acceptance

### Aspect Tests
- **Security:** No tests for config injection, contract bypass
- **Performance:** No config evaluation benchmarks
- **Concurrency:** N/A
- **Error handling:** No tests for malformed Nickel, invalid contracts, missing dependencies

### Build & Execution
- [ ] `nickel typecheck` for all .ncl files
- [ ] Shell integration test execution

### Benchmarks Needed
- [ ] Config evaluation time by complexity
- [ ] Contract validation overhead

### Self-Tests
- [ ] All .ncl files typecheck cleanly
- [ ] Contract self-consistency verification

## Priority

**MEDIUM.** 19 Nickel files with 1 shell integration test. Small project but the contracts are meant to enforce correctness — they need their own correctness verified. The integration test is a start but unit-level contract testing is missing.

## FAKE-FUZZ ALERT

- `tests/fuzz/placeholder.txt` is a scorecard placeholder inherited from rsr-template-repo — it does NOT provide real fuzz testing
- Replace with an actual fuzz harness (see rsr-template-repo/tests/fuzz/README.adoc) or remove the file
- Priority: P2 — creates false impression of fuzz coverage
