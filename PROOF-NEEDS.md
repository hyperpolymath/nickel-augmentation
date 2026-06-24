<!--
SPDX-License-Identifier: MPL-2.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# PROOF-NEEDS.md — nickel-augmentation

## Current State

- **src/abi/*.idr**: NO
- **Dangerous patterns**: 0 (2 references are in proven.ncl documenting the believe_me_count = 0 invariant)
- **LOC**: ~5,900 (Nickel)
- **ABI layer**: Missing

## What Needs Proving

| Component | What | Why |
|-----------|------|-----|
| Contract validation | Nickel contracts correctly enforce RSR policies | Wrong contract validation passes non-compliant configs |
| Proven integration | proven.ncl accurately reflects proven library state | Stale proven metadata gives false confidence |
| Config reporter | Reporter correctly identifies all policy violations | Missed violations bypass security/language policy |
| Augmentation composition | Augmented configs compose correctly | Composition bugs produce invalid merged configs |

## Recommended Prover

**Idris2** — Create `src/abi/` with types for contract composition. Nickel's own contract system provides some safety, but the RSR policy enforcement logic needs formal backing.

## Priority

**LOW** — Configuration tooling. Nickel's type system provides some guarantees already. The main gap is proving that RSR policy contracts are complete (no bypass paths).
