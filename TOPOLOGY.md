<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-03-16 -->

# nickel-augmentation — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              OPERATOR / AGENT           │
                        │        (Nickel Configs / YAML / JSON)   │
                        └───────────────────┬─────────────────────┘
                                            │
                        ┌───────────────────┼───────────────────┐
                        │                   │                   │
                        ▼                   ▼                   ▼
                ┌───────────────┐  ┌────────────────┐  ┌───────────────┐
                │  augmented/   │  │config-reporter/ │  │ contractiles/ │
                │               │  │                 │  │               │
                │ lib/          │  │ bin/            │  │ k9/           │
                │  rsr.ncl      │  │  config-reporter│  │  templates    │
                │  security.ncl │  │ src/            │  │  examples     │
                │  ci.ncl       │  │  report.ncl     │  │ must/trust/   │
                │  infra.ncl    │  │  rules.ncl      │  │ dust/lust/    │
                │  prelude.ncl  │  │                 │  │               │
                │ examples/     │  │                 │  │               │
                └───────┬───────┘  └────────┬───────┘  └───────────────┘
                        │                   │
                        ▼                   ▼
                ┌─────────────────────────────────────────┐
                │           NICKEL ENVIRONMENT            │
                │      (Type-safe config / Contracts)     │
                └─────────────────────────────────────────┘

                ┌─────────────────────────────────────────┐
                │          REPO INFRASTRUCTURE            │
                │  Justfile Automation  .machine_readable/ │
                │  .bot_directives/     0-AI-MANIFEST.a2ml │
                └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
AUGMENTED (Library)
  lib/rsr.ncl                      ██████████ 100%    Language/license/metadata contracts
  lib/security.ncl                 ██████████ 100%    HTTPS, hashes, actions, secrets
  lib/ci.ncl                       ██████████ 100%    Jobs, steps, matrix, templates
  lib/infra.ncl                    ██████████ 100%    Services, DB, containers, envs
  lib/prelude.ncl                  ██████████ 100%    Re-export all modules
  examples/                        ██████████ 100%    4 working examples (typecheck+export)

CONFIG-REPORTER
  bin/config-reporter              ████████░░  80%    9 rules, JSON output, exit codes
  src/report.ncl                   ██████████ 100%    Report schema definition
  src/rules.ncl                    ██████████ 100%    Rule definitions
  Additional rules                 ████░░░░░░  40%    Need more domain-specific rules

CONTRACTILES
  k9/ templates                    ██████████ 100%    Kennel/Yard/Hunt templates
  k9/ examples                     ██████████ 100%    CI, metadata, setup-repo examples
  must/trust/dust/lust             ██████████ 100%    Template files ready

INFRASTRUCTURE
  Justfile Automation              ██████████ 100%    Nickel-specific recipes wired
  .machine_readable/               ██████████ 100%    STATE tracking active
  0-AI-MANIFEST.a2ml               ██████████ 100%    AI entry point verified

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ██████░░░░  ~55%   Library stable, reporter active
```

## Key Dependencies

```
augmented/lib/ ──────► examples/ ───► Validation (nickel typecheck / export)
     │                     │
     │                     ▼
     │            config-reporter/ ───► Audit Report (JSON / terminal)
     │
     ▼
contractiles/k9/ ──── K9 templates use contracts from lib/
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
