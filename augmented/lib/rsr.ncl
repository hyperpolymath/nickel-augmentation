# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# rsr.ncl — Core RSR (Rhodium Standard Repository) contracts
#
# Enforces the Hyperpolymath language policy, SPDX license validation,
# and repository metadata contracts at configuration time.
{
  # ═══════════════════════════════════════════════════════════════════════
  # PRIMITIVE CONTRACTS
  # ═══════════════════════════════════════════════════════════════════════

  # Non-empty string — rejects "" but accepts any other string
  NonEmptyString =
    std.contract.from_predicate (fun s =>
      std.string.length s > 0
    ),

  # Valid semantic version (major.minor.patch with optional pre-release/build)
  SemVer =
    std.contract.from_predicate (fun version =>
      std.string.is_match "^[0-9]+\\.[0-9]+\\.[0-9]+(-[a-zA-Z0-9.]+)?(\\+[a-zA-Z0-9.]+)?$" version
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # LANGUAGE POLICY
  # ═══════════════════════════════════════════════════════════════════════

  # Languages permitted by the RSR specification.
  # Contracts fail if a banned language is used.
  AllowedLanguage =
    std.contract.from_predicate (fun lang =>
      std.array.elem
        lang
        [
          "rescript",
          "rust",
          "gleam",
          "elixir",
          "deno",
          "bash",
          "javascript",
          "nickel",
          "guile",
          "julia",
          "ocaml",
          "haskell",
          "ada",
          "idris2",
          "zig",
        ]
    ),

  # Languages explicitly banned by RSR policy.
  # This contract succeeds if the input IS a banned language —
  # use it in negative checks, not as a field annotation.
  BannedLanguage =
    std.contract.from_predicate (fun lang =>
      std.array.elem
        lang
        [
          "typescript",
          "nodejs",
          "go",
          "python",
          "java",
          "kotlin",
          "swift",
          "dart",
          "flutter",
        ]
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # LICENSE POLICY
  # ═══════════════════════════════════════════════════════════════════════

  # SPDX license identifiers accepted in Hyperpolymath projects
  SpdxLicense =
    std.contract.from_predicate (fun license =>
      std.array.elem
        license
        [
          "PMPL-1.0-or-later",
          "MPL-2.0",
          "MIT",
          "Apache-2.0",
          "GPL-3.0-or-later",
          "LGPL-3.0-or-later",
          "BSD-2-Clause",
          "BSD-3-Clause",
        ]
    ),

  # The preferred license for all hyperpolymath original code
  PreferredLicense =
    std.contract.from_predicate (fun license =>
      license == "PMPL-1.0-or-later"
    ),

  # Fallback license (for platforms requiring OSI-approved)
  FallbackLicense =
    std.contract.from_predicate (fun license =>
      license == "MPL-2.0"
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # REPOSITORY METADATA
  # ═══════════════════════════════════════════════════════════════════════

  # RSR tier classification
  RsrTier =
    std.contract.from_predicate (fun tier =>
      std.array.elem tier ["tier-1", "tier-2", "infrastructure"]
    ),

  # Repository metadata record contract
  RepoMetadata = {
    name | NonEmptyString,
    version | SemVer,
    description | NonEmptyString,
    license | SpdxLicense,
    tier | RsrTier | default = "tier-2",
    author | NonEmptyString | default = "Jonathan D.A. Jewell",
    repository_url | NonEmptyString | optional,
  },

  # ═══════════════════════════════════════════════════════════════════════
  # BUILD TARGETS
  # ═══════════════════════════════════════════════════════════════════════

  # A build target within an RSR project.
  # The language field is validated against the RSR allowlist.
  BuildTarget = {
    name | NonEmptyString,
    language | AllowedLanguage,
    entry_point | NonEmptyString,
    output_dir | NonEmptyString | default = "dist",
    dependencies | Array NonEmptyString | default = [],
  },

  # ═══════════════════════════════════════════════════════════════════════
  # CHECKPOINT FILES
  # ═══════════════════════════════════════════════════════════════════════

  # Checkpoint file type (STATE, META, ECOSYSTEM)
  CheckpointType =
    std.contract.from_predicate (fun t =>
      std.array.elem t ["STATE", "META", "ECOSYSTEM"]
    ),

  # Checkpoint file format (scm or a2ml)
  CheckpointFormat =
    std.contract.from_predicate (fun f =>
      std.array.elem f ["scm", "a2ml"]
    ),

  # Expected checkpoint file location
  # SCM files MUST be in .machine_readable/ — never in root
  CheckpointFile = {
    type | CheckpointType,
    format | CheckpointFormat | default = "a2ml",
    directory | NonEmptyString | default = ".machine_readable",
  },
}
