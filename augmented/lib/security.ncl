# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# security.ncl — Security contracts for RSR-compliant projects
#
# Enforces HTTPS-only URLs, secure hash algorithms (SHA-256+),
# SHA-pinned GitHub Actions, and secret reference patterns.
{
  # ═══════════════════════════════════════════════════════════════════════
  # URL SECURITY
  # ═══════════════════════════════════════════════════════════════════════

  # HTTPS-only URL — rejects http:// and other insecure schemes.
  # Per RSR security policy, all external URLs must use TLS.
  HttpsUrl =
    std.contract.from_predicate (fun url =>
      std.string.is_match "^https://" url
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # CRYPTOGRAPHIC HASHES
  # ═══════════════════════════════════════════════════════════════════════

  # SHA-256 or stronger hash — rejects MD5 and SHA-1.
  # Accepts: sha256:<64hex>, sha384:<96hex>, sha512:<128hex>
  # Also accepts bare hex strings of appropriate length.
  SecureHash =
    std.contract.from_predicate (fun hash =>
      std.string.is_match "^(sha256:|sha384:|sha512:)?[a-fA-F0-9]{64,128}$" hash
    ),

  # Specifically SHA-256 (64 hex characters)
  Sha256 =
    std.contract.from_predicate (fun hash =>
      std.string.is_match "^(sha256:)?[a-fA-F0-9]{64}$" hash
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # GITHUB ACTIONS
  # ═══════════════════════════════════════════════════════════════════════

  # SHA-pinned GitHub Action reference.
  # Format: "owner/action@<40-char SHA>"
  # Rejects version tags like @v4 — only full commit SHAs are acceptable
  # for supply chain security.
  ShaPinnedAction =
    std.contract.from_predicate (fun ref =>
      std.string.is_match "^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+@[a-fA-F0-9]{40}$" ref
    ),

  # GitHub Action with version tag (less secure, but documented).
  # Use ShaPinnedAction for production workflows.
  TaggedAction =
    std.contract.from_predicate (fun ref =>
      std.string.is_match "^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+@v[0-9]+" ref
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # SECRET REFERENCES
  # ═══════════════════════════════════════════════════════════════════════

  # Secret provider type — never store actual secrets in Nickel configs.
  # Only store references to where secrets live.
  SecretProvider = [| 'env, 'vault, 'sops, 'aws_ssm, 'gcp_secret_manager |],

  # A reference to a secret stored externally.
  # The key field points to the secret's location in the provider.
  SecretRef = {
    type | SecretProvider,
    key
      | String
      | std.contract.from_predicate (fun k => std.string.length k > 0),
  },

  # ═══════════════════════════════════════════════════════════════════════
  # TLS / CERTIFICATE CONTRACTS
  # ═══════════════════════════════════════════════════════════════════════

  # TLS version — only 1.2 and 1.3 are acceptable
  TlsVersion =
    std.contract.from_predicate (fun v =>
      std.array.elem v ["1.2", "1.3"]
    ),

  # SSL mode for database connections
  SslMode =
    std.contract.from_predicate (fun mode =>
      std.array.elem mode ["require", "verify-ca", "verify-full"]
    ),
}
