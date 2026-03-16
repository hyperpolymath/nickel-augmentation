# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# infra.ncl — Infrastructure contracts for RSR-compliant deployments
#
# Provides contracts for service definitions, environment configuration,
# container images, and network policies.
let rsr = import "./rsr.ncl" in
let security = import "./security.ncl" in

{
  # ═══════════════════════════════════════════════════════════════════════
  # ENVIRONMENT
  # ═══════════════════════════════════════════════════════════════════════

  # Deployment environment name
  Environment =
    std.contract.from_predicate (fun env =>
      std.array.elem env ["development", "staging", "production"]
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # NETWORKING
  # ═══════════════════════════════════════════════════════════════════════

  # TCP/UDP port number (1–65535)
  Port =
    std.contract.from_predicate (fun port =>
      port >= 1 && port <= 65535
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # SERVICE DEFINITIONS
  # ═══════════════════════════════════════════════════════════════════════

  # A deployable service within the infrastructure
  Service = {
    name | rsr.NonEmptyString,
    port | Port,
    health_check | rsr.NonEmptyString | optional,
    environment | Environment | default = "development",
    replicas | std.number.Nat | default = 1,
  },

  # ═══════════════════════════════════════════════════════════════════════
  # DATABASE
  # ═══════════════════════════════════════════════════════════════════════

  # Database connection configuration.
  # Password is a SecretRef — actual credentials never appear in config.
  DatabaseConfig = {
    host | rsr.NonEmptyString,
    port | Port | default = 5432,
    name | rsr.NonEmptyString,
    password | security.SecretRef,
    ssl_mode | security.SslMode | optional,
    pool_size | std.number.Nat | default = 5,
  },

  # ═══════════════════════════════════════════════════════════════════════
  # CONTAINERS
  # ═══════════════════════════════════════════════════════════════════════

  # Container runtime — RSR mandates Podman, never Docker
  ContainerRuntime =
    std.contract.from_predicate (fun rt =>
      std.array.elem rt ["podman", "nerdctl"]
    ),

  # Container image reference with digest for integrity
  ContainerImage = {
    registry | security.HttpsUrl | default = "https://ghcr.io/hyperpolymath",
    tag | rsr.NonEmptyString,
    digest | security.SecureHash | optional,
  },

  # Base image policy — Chainguard images only per RSR
  BaseImage =
    std.contract.from_predicate (fun image =>
      std.string.is_match "^(cgr\\.dev/chainguard/|ghcr\\.io/hyperpolymath/)" image
    ),

  # ═══════════════════════════════════════════════════════════════════════
  # ENVIRONMENT CONFIG TEMPLATES
  # ═══════════════════════════════════════════════════════════════════════

  # Base configuration shared across all environments.
  # Merge with & to override per-environment.
  base_env_config = {
    log_level = "info",
    metrics_enabled = true,
    tracing_enabled = true,
  },

  # Development defaults
  dev_config =
    base_env_config
    & {
      log_level = "debug",
    },

  # Production defaults — stricter logging, larger pools
  prod_config =
    base_env_config
    & {
      log_level = "warn",
    },
}
