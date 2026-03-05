<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# nickel-augmentation — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              OPERATOR / AGENT           │
                        │        (Nickel Configs / YAML / JSON)   │
                        └───────────────────┬─────────────────────┘
                                            │
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           NICKEL TOOLING HUB            │
                        │                                         │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │ augmented/ │  │ config-reporter/  │  │
                        │  │ (Tools)    │  │ (Analysis)        │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        └────────│─────────────────│──────────────┘
                                 │                 │
                                 ▼                 ▼
                        ┌─────────────────────────────────────────┐
                        │           NICKEL ENVIRONMENT            │
                        │      (Type-safe config / Contracts)     │
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Justfile Automation  .machine_readable/  │
                        │  .bot_directives/     0-AI-MANIFEST.a2ml  │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
NICKEL TOOLS
  augmented/                        ████████░░  80%    Augmentation primitives stable
  config-reporter/                  ██████░░░░  60%    Audit report generation active
  Schema Validation                 ██████████ 100%    Nickel contracts verified

INFRASTRUCTURE
  Justfile Automation               ██████████ 100%    Standard build/lint tasks
  .machine_readable/                ██████████ 100%    STATE tracking active
  0-AI-MANIFEST.a2ml                ██████████ 100%    AI entry point verified

REPO INFRASTRUCTURE
  .bot_directives/                  ██████████ 100%    Tool hygiene rules
  Test Suite                        ██████░░░░  60%    Integration tests expanding

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ████████░░  ~80%   Nickel toolset stable
```

## Key Dependencies

```
Nickel Source ───► augmented/ ──────► config-reporter/ ───► Audit Report
     │                │                   │
     ▼                ▼                   ▼
 Contract ───────► Validation ────────► Analysis
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
