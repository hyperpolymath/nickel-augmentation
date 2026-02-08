# SPDX-FileCopyrightText: 2024 Hyperpolymath
# SPDX-License-Identifier: MIT OR AGPL-3.0-or-later

# Build configuration example for RSR-compliant projects
# Demonstrates: contracts validating targets and dependencies

let contracts = import "./contracts.ncl" in

{
  # Project metadata
  project = {
    name | contracts.NonEmptyString = "my-rsr-project",
    version | contracts.SemVer = "0.1.0",
    license | contracts.SpdxLicense = "MIT",
    repository | contracts.HttpsUrl = "https://github.com/hyperpolymath/my-project",
  },

  # Build targets - contracts ensure only allowed languages
  targets = {
    # ReScript frontend
    frontend | contracts.BuildTarget = {
      name = "frontend",
      language = "rescript",
      entry_point = "src/App.res",
      output_dir = "dist/js",
      dependencies = ["@rescript/core", "@rescript/react"],
    },

    # Rust CLI tool
    cli | contracts.BuildTarget = {
      name = "cli",
      language = "rust",
      entry_point = "src/main.rs",
      output_dir = "target/release",
      dependencies = ["clap", "tokio", "serde"],
    },

    # Gleam backend service
    backend | contracts.BuildTarget = {
      name = "backend",
      language = "gleam",
      entry_point = "src/app.gleam",
      output_dir = "build/erlang",
      dependencies = ["gleam_http", "gleam_json"],
    },
  },

  # Build profiles with environment-specific settings
  profiles = {
    development = {
      optimize = false,
      source_maps = true,
      debug_symbols = true,
    },
    release = {
      optimize = true,
      source_maps = false,
      debug_symbols = false,
      strip = true,
    },
  },

  # Dependency pinning with secure hashes (SHA-256+)
  pinned_dependencies = {
    "rescript" = {
      version | contracts.SemVer = "11.1.0",
      hash | contracts.SecureHash = "sha256:a1b2c3d4e5f6789012345678901234567890123456789012345678901234abcd",
    },
    "gleam" = {
      version | contracts.SemVer = "1.0.0",
      hash | contracts.SecureHash = "sha256:b2c3d4e5f6789012345678901234567890123456789012345678901234abcdef",
    },
  },

  # Output: commands to run for each target
  # This demonstrates Nickel generating build commands
  commands =
    let make_build_cmd = fun target =>
      if target.language == "rescript" then
        "deno task rescript:build"
      else if target.language == "rust" then
        "cargo build --release"
      else if target.language == "gleam" then
        "gleam build"
      else
        "echo 'Unknown target'"
    in
    {
      frontend = make_build_cmd targets.frontend,
      cli = make_build_cmd targets.cli,
      backend = make_build_cmd targets.backend,
    },
}
