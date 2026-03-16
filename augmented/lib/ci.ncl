# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# ci.ncl — CI/CD contracts and templates for RSR-compliant workflows
#
# Provides contracts for GitHub Actions / GitLab CI job definitions,
# matrix build configurations, and workflow step validation.
let rsr = import "./rsr.ncl" in
let security = import "./security.ncl" in

{
  # ═══════════════════════════════════════════════════════════════════════
  # WORKFLOW METADATA
  # ═══════════════════════════════════════════════════════════════════════

  # CI platform identifier
  CiPlatform = [| 'GitHubActions, 'GitLabCI |],

  # GitHub Actions event triggers
  GhTrigger = [| 'push, 'pull_request, 'schedule, 'workflow_dispatch |],

  # Workflow permissions — use read-all by default per RSR
  GhPermission = [| 'read, 'write, 'none |],

  # ═══════════════════════════════════════════════════════════════════════
  # WORKFLOW STEPS
  # ═══════════════════════════════════════════════════════════════════════

  # A single step in a CI job.
  # Either `run` (shell command) or `uses` (action reference) must be present.
  Step = {
    name | rsr.NonEmptyString,
    run | String | optional,
    uses | String | optional,
    with | { .. } | optional,
    env | { .. } | optional,
    if_condition | String | optional,
  },

  # ═══════════════════════════════════════════════════════════════════════
  # JOB DEFINITIONS
  # ═══════════════════════════════════════════════════════════════════════

  # A CI job that runs on a single runner
  Job = {
    name | rsr.NonEmptyString,
    runs_on | rsr.NonEmptyString | default = "ubuntu-latest",
    steps | Array Step,
    needs | Array rsr.NonEmptyString | default = [],
    timeout_minutes | Number | default = 30,
    if_condition | String | optional,
  },

  # ═══════════════════════════════════════════════════════════════════════
  # MATRIX BUILDS
  # ═══════════════════════════════════════════════════════════════════════

  # Build matrix for cross-platform / cross-version testing
  Matrix = {
    os | Array String | default = ["ubuntu-latest"],
    "%{"include"}" | Array Dyn | optional,
    "%{"exclude"}" | Array Dyn | optional,
    fail_fast | Bool | default = false,
  },

  # ═══════════════════════════════════════════════════════════════════════
  # REUSABLE STEP TEMPLATES
  # ═══════════════════════════════════════════════════════════════════════

  # Standard checkout step (SHA-pinned)
  checkout_step = {
    name = "Checkout",
    uses = "actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5",
  },

  # Cache step factory — produces a step that caches a given path
  cache_step = fun label path key =>
    {
      name = "Cache %{label}",
      uses = "actions/cache@v4",
      with = {
        path = path,
        key = key,
      },
    },

  # ═══════════════════════════════════════════════════════════════════════
  # RSR-REQUIRED WORKFLOWS
  # ═══════════════════════════════════════════════════════════════════════

  # The 17 workflows every RSR repo must have
  required_workflows = [
    "hypatia-scan",
    "codeql",
    "scorecard",
    "quality",
    "mirror",
    "instant-sync",
    "guix-nix-policy",
    "rsr-antipattern",
    "security-policy",
    "wellknown-enforcement",
    "workflow-linter",
    "npm-bun-blocker",
    "ts-blocker",
    "jekyll-gh-pages",
    "jekyll",
    "scorecard-enforcer",
    "secret-scanner",
  ],

  # ═══════════════════════════════════════════════════════════════════════
  # BASE JOB TEMPLATES
  # ═══════════════════════════════════════════════════════════════════════

  # Default job configuration — merge with & to customise
  base_job = {
    runs_on = "ubuntu-latest",
    timeout_minutes = 30,
    steps = [checkout_step],
  },

  # Security-scanning job template
  security_job =
    base_job
    & {
      name = "Security Scan",
      steps = [
        checkout_step,
        {
          name = "TruffleHog secrets scan",
          uses = "trufflesecurity/trufflehog@7ee2e0fdffec27d19ccbb8fb3dcf8a83b9d7f9e8",
          with = { extra_args = "--only-verified" },
        },
      ],
    },

  # RSR compliance check job template
  rsr_validate_job =
    base_job
    & {
      name = "RSR Compliance",
      steps = [
        checkout_step,
        {
          name = "Validate RSR compliance",
          run = "just validate-rsr",
        },
        {
          name = "Check for banned languages",
          run = "just check-banned-languages",
        },
      ],
    },
}
