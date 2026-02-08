# SPDX-FileCopyrightText: 2024 Hyperpolymath
# SPDX-License-Identifier: MIT OR AGPL-3.0-or-later

# CI/CD pipeline configuration example
# Demonstrates: merge semantics for matrix builds, generates YAML

let contracts = import "./contracts.ncl" in

# Base job templates - Nickel's merge semantics shine here
let base_job = {
  runs_on = "ubuntu-latest",
  timeout_minutes = 30,
} in

let checkout_step = {
  name = "Checkout",
  uses = "actions/checkout@v4",
} in

let cache_step = fun name path key => {
  name = "Cache %{name}",
  uses = "actions/cache@v4",
  with = {
    path = path,
    key = key,
  },
} in

{
  # Pipeline metadata
  name = "RSR CI Pipeline",

  on = {
    push = { branches = ["main", "develop"] },
    pull_request = { branches = ["main"] },
  },

  # Jobs using Nickel merge semantics
  jobs = {
    # Lint job - merges base_job with specific config
    lint = base_job & {
      name = "Lint & Format",
      steps = [
        checkout_step,
        {
          name = "Check ReScript format",
          run = "deno task rescript:format --check",
        },
        {
          name = "Check Rust format",
          run = "cargo fmt --check",
        },
        {
          name = "Clippy",
          run = "cargo clippy -- -D warnings",
        },
      ],
    },

    # Security scanning
    security = base_job & {
      name = "Security Scan",
      steps = [
        checkout_step,
        {
          name = "TruffleHog secrets scan",
          uses = "trufflesecurity/trufflehog@main",
          with = { extra_args = "--only-verified" },
        },
        {
          name = "Cargo audit",
          run = "cargo audit",
        },
      ],
    },

    # Test matrix - demonstrates Nickel's power for matrix builds
    test = base_job & {
      name = "Test",
      needs = ["lint"],
      strategy = {
        matrix = {
          # Only RSR-allowed languages
          target = ["frontend", "cli", "backend"],
          os = ["ubuntu-latest", "macos-latest"],
        },
        fail_fast = false,
      },
      steps = [
        checkout_step,
        cache_step "Cargo" "~/.cargo" "${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}",
        {
          name = "Run tests for ${{ matrix.target }}",
          run = "just test-${{ matrix.target }}",
        },
      ],
    },

    # Build job
    build = base_job & {
      name = "Build",
      needs = ["test", "security"],
      steps = [
        checkout_step,
        {
          name = "Build all targets",
          run = "just build-all",
        },
        {
          name = "Upload artifacts",
          uses = "actions/upload-artifact@v4",
          with = {
            name = "build-artifacts",
            path = "dist/",
          },
        },
      ],
    },

    # RSR compliance check
    rsr_validate = base_job & {
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
  },

  # Export function to generate GitHub Actions YAML
  # Usage: nickel export --format yaml ci.ncl > .github/workflows/ci.yml
  to_github_actions = {
    name = name,
    on = on,
    jobs = std.record.map (fun _name job =>
      std.record.remove "timeout_minutes" job
    ) jobs,
  },
}
