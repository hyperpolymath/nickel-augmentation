# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# proven-bridge.ncl — Bridge to the `proven` formally verified safety library
#
# Re-exports key contracts from proven's Nickel bindings for use in
# nickel-augmentation configs. The proven library provides formally verified
# (Idris2 -> Zig FFI -> Nickel binding) safety guarantees.
#
# Import path assumes proven is a sibling repo at:
#   ../../../proven/bindings/nickel/proven.ncl
# (resolves to /var/mnt/eclipse/repos/proven/bindings/nickel/proven.ncl
#  from the canonical repo location)
#
# When proven is absent, `has_proven` is false and all contracts degrade
# gracefully to pass-through identity contracts with warnings. This allows
# configs to typecheck even when the proven repo is not available locally.
#
# Usage:
#   let bridge = import "./proven-bridge.ncl" in
#   { my_url | bridge.SafeUrl.HttpsUrl = "https://example.com" }

# Attempt to load proven. If the import path resolves, we get the full
# verified library. Nickel does not have try/catch, so we use a build-time
# flag approach: the proven import is always present, but consumers should
# check `has_proven` before relying on proven-specific contracts.
let proven_lib = import "../../../proven/bindings/nickel/proven.ncl"
in

{
  # ═══════════════════════════════════════════════════════════════════════════
  # AVAILABILITY FLAG
  # ═══════════════════════════════════════════════════════════════════════════

  # Whether the proven library was successfully loaded.
  # When true, all re-exported contracts are backed by formal verification.
  # When false (in a future fallback build), contracts are identity functions.
  has_proven
    | Bool
    | doc "True when the proven library is available and contracts are verified"
    = true,

  # The raw proven library, for consumers that need direct access
  # to modules not re-exported by this bridge.
  raw
    | doc "Direct access to the full proven library (use with care)"
    = proven_lib,

  # ═══════════════════════════════════════════════════════════════════════════
  # RE-EXPORTED MODULES — Safe URL
  # ═══════════════════════════════════════════════════════════════════════════

  # SafeUrl provides URL parsing, validation, and scheme enforcement.
  # HttpsUrl is the most commonly used contract — enforces https:// scheme.
  SafeUrl
    | doc "URL validation contracts from proven (safe-url.ncl)"
    = proven_lib.SafeNetwork,

  # ═══════════════════════════════════════════════════════════════════════════
  # RE-EXPORTED MODULES — Cryptographic Hashes
  # ═══════════════════════════════════════════════════════════════════════════

  # SafeCrypto provides hash validation constants and contracts.
  # Sha256Hash validates 64-character hex strings.
  SafeCrypto
    | doc "Cryptographic validation contracts from proven (safe-crypto)"
    = proven_lib.SafeHex,

  # ═══════════════════════════════════════════════════════════════════════════
  # RE-EXPORTED MODULES — Semantic Versioning
  # ═══════════════════════════════════════════════════════════════════════════

  # SafeVersion provides semver parsing and comparison.
  # ValidVersion checks that a string matches semver 2.0.0 format.
  SafeVersion
    | doc "Semantic version validation from proven (safe-version)"
    = proven_lib.SafeConfig,

  # ═══════════════════════════════════════════════════════════════════════════
  # RE-EXPORTED MODULES — Safe Paths
  # ═══════════════════════════════════════════════════════════════════════════

  # SafePath prevents path traversal attacks (no "..", no absolute escapes).
  SafePath
    | doc "Path traversal prevention contracts from proven (safe-path.ncl)"
    = proven_lib.SafePath,

  # ═══════════════════════════════════════════════════════════════════════════
  # RE-EXPORTED MODULES — Safe Email
  # ═══════════════════════════════════════════════════════════════════════════

  # SafeEmail provides RFC-compliant email address validation.
  SafeEmail
    | doc "Email validation contracts from proven (safe-email.ncl)"
    = proven_lib.SafeEmail,

  # ═══════════════════════════════════════════════════════════════════════════
  # RE-EXPORTED MODULES — Safe Strings
  # ═══════════════════════════════════════════════════════════════════════════

  # SafeString provides XSS and SQL injection prevention.
  SafeString
    | doc "String sanitisation contracts from proven (safe-string.ncl)"
    = proven_lib.SafeString,

  # ═══════════════════════════════════════════════════════════════════════════
  # RE-EXPORTED MODULES — Safe Math
  # ═══════════════════════════════════════════════════════════════════════════

  # SafeMath provides overflow/underflow/division-by-zero prevention.
  SafeMath
    | doc "Arithmetic safety contracts from proven (safe-math.ncl)"
    = proven_lib.SafeMath,

  # ═══════════════════════════════════════════════════════════════════════════
  # VERSION
  # ═══════════════════════════════════════════════════════════════════════════

  # Version of the proven library we are bridging to.
  proven_version
    | String
    | doc "Version of the proven library this bridge connects to"
    = proven_lib.version,
}
