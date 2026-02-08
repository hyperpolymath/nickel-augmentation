# SPDX-FileCopyrightText: 2024 Hyperpolymath
# SPDX-License-Identifier: MIT OR AGPL-3.0-or-later

# Shared contracts for RSR-compliant Nickel configurations
# These contracts enforce the Hyperpolymath language policy at config-time

{
  # Allowed languages per RSR specification
  AllowedLanguage = std.contract.from_predicate (fun lang =>
    std.array.elem lang [
      "rescript",
      "rust",
      "gleam",
      "deno",
      "bash",
      "javascript",
      "nickel",
      "guile",
      "julia",
      "ocaml",
      "ada",
      "python-saltstack",
    ]
  ),

  # Banned languages - will fail contract if used
  BannedLanguage = std.contract.from_predicate (fun lang =>
    std.array.elem lang [
      "typescript",
      "nodejs",
      "go",
      "python",
      "java",
      "kotlin",
      "swift",
      "dart",
    ]
  ),

  # Valid semantic version string
  SemVer = std.contract.from_predicate (fun version =>
    std.string.is_match "^[0-9]+\\.[0-9]+\\.[0-9]+(-[a-zA-Z0-9.]+)?(\\+[a-zA-Z0-9.]+)?$" version
  ),

  # HTTPS-only URL (no HTTP allowed per security policy)
  HttpsUrl = std.contract.from_predicate (fun url =>
    std.string.is_match "^https://" url
  ),

  # SHA-256 or stronger hash (no MD5/SHA1 per security policy)
  SecureHash = std.contract.from_predicate (fun hash =>
    # SHA-256 (64 hex chars), SHA-384 (96 hex chars), SHA-512 (128 hex chars)
    std.string.is_match "^(sha256:|sha384:|sha512:)?[a-fA-F0-9]{64,128}$" hash
  ),

  # SPDX license identifier
  SpdxLicense = std.contract.from_predicate (fun license =>
    std.array.elem license [
      "MIT",
      "AGPL-3.0-or-later",
      "Apache-2.0",
      "GPL-3.0-or-later",
      "LGPL-3.0-or-later",
      "BSD-3-Clause",
      "MPL-2.0",
    ]
  ),

  # Environment name contract
  Environment = std.contract.from_predicate (fun env =>
    std.array.elem env ["development", "staging", "production"]
  ),

  # Non-empty string
  NonEmptyString = std.contract.from_predicate (fun s =>
    std.string.length s > 0
  ),

  # Port number (1-65535)
  Port = std.contract.from_predicate (fun port =>
    port >= 1 && port <= 65535
  ),

  # Build target configuration
  BuildTarget = {
    name | NonEmptyString,
    language | AllowedLanguage,
    entry_point | NonEmptyString,
    output_dir | NonEmptyString | default = "dist",
    dependencies | Array NonEmptyString | default = [],
  },

  # CI job configuration
  CiJob = {
    name | NonEmptyString,
    runs_on | NonEmptyString | default = "ubuntu-latest",
    steps | Array { .. },
    needs | Array NonEmptyString | default = [],
    if_condition | NonEmptyString | optional,
  },

  # Service configuration
  Service = {
    name | NonEmptyString,
    port | Port,
    health_check | NonEmptyString | optional,
    environment | Environment | default = "development",
    replicas | std.number.Nat | default = 1,
  },
}
