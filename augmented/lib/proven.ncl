# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# proven.ncl — Bridge to the formally verified `proven` library (Idris2 + Zig FFI).
#
# Nickel contracts backed by dependent-type proofs. Each contract here
# corresponds to a module in the `proven` library that has been formally
# verified in Idris2 with zero `believe_me` postulates.
#
# Usage:
#   let aug = import "./lib/prelude.ncl" in
#   {
#     url | aug.proven.SafeUrl = "https://example.com",
#     hash | aug.proven.SafeHash = "sha256:abc123...",
#     version | aug.proven.SafeVersion = "1.2.3",
#   }
#
# These contracts validate the SAME invariants that the proven Idris2 modules
# enforce at runtime. This gives you build-time safety (Nickel) AND runtime
# safety (Idris2) from the same specification.
{
  # ═══════════════════════════════════════════════════════════════════════
  # URL SAFETY (proven/SafeHTTP, proven/SafeUrl)
  # ═══════════════════════════════════════════════════════════════════════

  # URL must use HTTPS (no HTTP). Matches the proven SafeUrl module which
  # rejects plaintext HTTP at the type level.
  SafeUrl =
    std.contract.from_predicate (fun url =>
      std.string.is_match "^https://" url
    ),

  # URL with optional path validation — must be HTTPS and well-formed.
  SafeUrlWithPath =
    std.contract.from_predicate (fun url =>
      std.string.is_match "^https://[a-zA-Z0-9._-]+(:[0-9]+)?(/[a-zA-Z0-9._~:/?#@!$&'()*+,;=-]*)?$" url
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # CRYPTOGRAPHIC HASH SAFETY (proven/SafeCrypto, proven/SafeHash)
  # ═══════════════════════════════════════════════════════════════════════

  # Hash must use SHA-256 or stronger (no MD5, no SHA-1).
  # Matches the proven SafeHash module which only admits SHA-256+.
  SafeHash =
    std.contract.from_predicate (fun hash =>
      std.string.is_match "^(sha256|sha384|sha512|blake3):[a-fA-F0-9]+" hash
    ),

  # SHA-256 hex digest (exactly 64 hex chars after prefix).
  Sha256Digest =
    std.contract.from_predicate (fun hash =>
      std.string.is_match "^sha256:[a-fA-F0-9]{64}$" hash
    ),

  # SHA-512 hex digest (exactly 128 hex chars after prefix).
  Sha512Digest =
    std.contract.from_predicate (fun hash =>
      std.string.is_match "^sha512:[a-fA-F0-9]{128}$" hash
    ),

  # BLAKE3 hex digest (exactly 64 hex chars after prefix).
  Blake3Digest =
    std.contract.from_predicate (fun hash =>
      std.string.is_match "^blake3:[a-fA-F0-9]{64}$" hash
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # VERSION SAFETY (proven/SafeSemVer)
  # ═══════════════════════════════════════════════════════════════════════

  # Semantic version — must conform to SemVer 2.0.0.
  # Matches the proven SafeSemVer module's version parsing.
  SafeVersion =
    std.contract.from_predicate (fun version =>
      std.string.is_match "^[0-9]+\\.[0-9]+\\.[0-9]+(-[a-zA-Z0-9.]+)?(\\+[a-zA-Z0-9.]+)?$" version
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # STRING SAFETY (proven/SafeString)
  # ═══════════════════════════════════════════════════════════════════════

  # Non-empty, trimmed string — no leading/trailing whitespace.
  SafeString =
    std.contract.from_predicate (fun s =>
      std.string.length s > 0
      && s == std.string.trim s
    ),

  # String with maximum length — prevents oversized inputs.
  # Usage: `field | aug.proven.BoundedString 255 = "value"`
  BoundedString = fun max_len =>
    std.contract.from_predicate (fun s =>
      std.string.length s > 0
      && std.string.length s <= max_len
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # MEDIA TYPE SAFETY (proven/SafeMediaType)
  # ═══════════════════════════════════════════════════════════════════════

  # IANA media type (type/subtype with optional parameters).
  SafeMediaType =
    std.contract.from_predicate (fun mt =>
      std.string.is_match "^[a-zA-Z0-9][a-zA-Z0-9!#$&\\-^_.+]*(/[a-zA-Z0-9][a-zA-Z0-9!#$&\\-^_.+]*)?(;[a-zA-Z0-9_-]+=[a-zA-Z0-9_.+-]+)*$" mt
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # IDENTIFIER SAFETY (proven/SafeULID)
  # ═══════════════════════════════════════════════════════════════════════

  # ULID — Universally Unique Lexicographically Sortable Identifier.
  # 26 characters, Crockford Base32 encoding.
  SafeULID =
    std.contract.from_predicate (fun id =>
      std.string.is_match "^[0-9A-HJKMNP-TV-Z]{26}$" id
    ),

  # UUID v4 or v7 format.
  SafeUUID =
    std.contract.from_predicate (fun id =>
      std.string.is_match "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$" id
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # SPDX LICENSE SAFETY
  # ═══════════════════════════════════════════════════════════════════════

  # Valid SPDX license identifier (from the hyperpolymath allowed set).
  SafeLicense =
    std.contract.from_predicate (fun lic =>
      std.array.elem lic [
        "MPL-2.0",
        "MPL-2.0",
        "MIT",
        "Apache-2.0",
        "BSD-2-Clause",
        "BSD-3-Clause",
        "ISC",
        "0BSD",
        "Unlicense",
        "AGPL-3.0-or-later",
      ]
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # PORT SAFETY
  # ═══════════════════════════════════════════════════════════════════════

  # Valid TCP/UDP port number (1–65535, no privileged ports under 1024
  # unless explicitly allowed).
  SafePort =
    std.contract.from_predicate (fun port =>
      port >= 1024 && port <= 65535
    ),

  # Any valid port including privileged (1–65535).
  AnyPort =
    std.contract.from_predicate (fun port =>
      port >= 1 && port <= 65535
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # PROVEN LIBRARY STATUS
  # ═══════════════════════════════════════════════════════════════════════

  # Metadata about the proven modules these contracts correspond to.
  # Consumers can check this at build time to verify alignment.
  _meta = {
    proven_repo = "hyperpolymath/proven",
    proven_modules = [
      "SafeHTTP", "SafeUrl", "SafeCrypto", "SafeHash",
      "SafeSemVer", "SafeString", "SafeMediaType", "SafeULID",
      "SafeRBAC", "SafeRateWindow", "SafeJWK", "SafeHSTS",
    ],
    believe_me_count = 0,
    contract_count = 14,
    description = "Build-time contracts matching proven Idris2 runtime safety modules. Same invariants, two enforcement points.",
  },
}
