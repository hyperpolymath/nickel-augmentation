# SPDX-FileCopyrightText: 2024 Hyperpolymath
# SPDX-License-Identifier: MIT OR AGPL-3.0-or-later

# Infrastructure configuration example
# Demonstrates: type-safe secrets references, environment configs

let contracts = import "./contracts.ncl" in

# Secret reference - never contains actual secrets, only references
# Actual values come from environment variables or secret managers
let SecretRef = {
  type | [| 'env, 'vault, 'sops |],
  key | contracts.NonEmptyString,
} in

# Environment-specific configuration using Nickel merge
let base_config = {
  log_level = "info",
  metrics_enabled = true,
  tracing_enabled = true,
} in

{
  # Services configuration with contracts
  services = {
    api | contracts.Service = {
      name = "api-gateway",
      port = 8080,
      health_check = "/health",
      environment = "production",
      replicas = 3,
    },

    backend | contracts.Service = {
      name = "gleam-backend",
      port = 4000,
      health_check = "/api/health",
      environment = "production",
      replicas = 2,
    },

    worker | contracts.Service = {
      name = "rust-worker",
      port = 9000,
      environment = "production",
      replicas = 1,
    },
  },

  # Environment configurations using merge semantics
  environments = {
    development = base_config & {
      log_level = "debug",
      database = {
        host = "localhost",
        port = 5432,
        name = "myapp_dev",
        # Secret reference - actual password from environment
        password | SecretRef = { type = 'env, key = "DEV_DB_PASSWORD" },
      },
    },

    staging = base_config & {
      database = {
        host = "staging-db.internal",
        port = 5432,
        name = "myapp_staging",
        password | SecretRef = { type = 'vault, key = "secret/staging/db-password" },
      },
    },

    production = base_config & {
      log_level = "warn",
      database = {
        host = "prod-db.internal",
        port = 5432,
        name = "myapp_prod",
        # Production uses SOPS-encrypted secrets
        password | SecretRef = { type = 'sops, key = "db_password" },
        ssl_mode = "verify-full",
        pool_size = 20,
      },
      # Production-specific settings
      rate_limiting = {
        enabled = true,
        requests_per_minute = 1000,
      },
    },
  },

  # Container configuration (nerdctl + Wolfi per RSR)
  container = {
    base_image | contracts.HttpsUrl = "https://cgr.dev/chainguard/wolfi-base:latest",
    registry | contracts.HttpsUrl = "https://ghcr.io/hyperpolymath",

    # Image tags with secure hashes
    images = {
      api = {
        tag = "api:1.0.0",
        digest | contracts.SecureHash = "sha256:abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
      },
      backend = {
        tag = "backend:1.0.0",
        digest | contracts.SecureHash = "sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
      },
    },
  },

  # Network policies
  network = {
    ingress = {
      allowed_origins = [
        "https://app.example.com",
        "https://api.example.com",
      ],
      # All URLs must be HTTPS per security policy
      validate_https = std.array.all (fun url => std.string.is_match "^https://" url) ingress.allowed_origins,
    },

    internal = {
      service_mesh = "linkerd",
      mtls_enabled = true,
    },
  },

  # Generate environment-specific configs
  # This shows Nickel generating output for different environments
  export = fun env_name =>
    let env = environments."%{env_name}" in
    {
      services = services,
      config = env,
      container = container,
      network = network,
    },
}
