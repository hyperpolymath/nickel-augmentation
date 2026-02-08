# Nickel Policy Examples

Example Nickel configurations demonstrating the RSR augmentation boundary.

## Files

| File | Purpose | Demonstrates |
|------|---------|--------------|
| `contracts.ncl` | Shared contracts library | RSR language policy enforcement, secure hash validation |
| `build.ncl` | Build configuration | Contract-validated targets and dependencies |
| `ci.ncl` | CI/CD pipelines | Merge semantics for matrix builds, YAML generation |
| `infra.ncl` | Infrastructure config | Type-safe secret references, environment configs |

## Usage

```bash
# Validate a config
nickel typecheck build.ncl

# Export CI config to YAML
nickel export --format yaml ci.ncl | yq '.to_github_actions' > .github/workflows/ci.yml

# Generate environment-specific infra config
nickel export infra.ncl --field 'export "production"'
```

## Boundary Reminder

Nickel handles **build-time configuration with contracts**. It does NOT replace:

- `STATE.scm` / `META.scm` → Guile Scheme (RSR governance)
- `guix.scm` / `flake.nix` → Native package managers
- Runtime config → Environment variables / JSON
- Application logic → ReScript / Rust
