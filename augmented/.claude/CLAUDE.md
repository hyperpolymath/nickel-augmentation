<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
## Machine-Readable Artefacts

The following files in `.machine_readable/` contain structured project metadata:

- `STATE.scm` - Current project state and progress
- `META.scm` - Architecture decisions and development practices
- `ECOSYSTEM.scm` - Position in the ecosystem and related projects
- `AGENTIC.scm` - AI agent interaction patterns
- `NEUROSYM.scm` - Neurosymbolic integration config
- `PLAYBOOK.scm` - Operational runbook

---

# CLAUDE.md - AI Assistant Instructions

## Language Policy (Hyperpolymath Standard)

### ALLOWED Languages & Tools

| Language/Tool | Use Case | Notes |
|---------------|----------|-------|
| **AffineScript** | Primary application code | Compiles to JS, type-safe |
| **Bun** | JS runtime & package management (tier 1) | Default for all new work. Runs compiled ESM/JS directly — no bundler step. Uses an npm-compatible `package.json` plus `bun.lock` — both are expected, not anti-patterns. |
| **Rust** | Performance-critical, systems, WASM | Preferred for CLI tools |
| **Tauri 2.0+** | Mobile apps (iOS/Android) | Rust backend + web UI |
| **Dioxus** | Mobile apps (native UI) | Pure Rust, React-like |
| **Gleam** | Backend services | Runs on BEAM or compiles to JS |
| **Bash/POSIX Shell** | Scripts, automation | Keep minimal |
| **JavaScript** | Only where AffineScript cannot | MCP protocol glue, Bun APIs |
| **Nickel** | Configuration language | Typed configs with contracts (see below) |
| **Guile Scheme** | State/meta files | STATE.scm, META.scm, ECOSYSTEM.scm |
| **Julia** | Batch scripts, data processing | Per RSR |
| **OCaml** | AffineScript compiler | Language-specific |
| **Ada** | Safety-critical systems | Where required |

### BANNED - Do Not Use

| Banned | Replacement |
|--------|-------------|
| TypeScript | AffineScript |
| ReScript | AffineScript |
| Deno | Bun |
| Node.js | Bun |
| npm | Bun |
| pnpm/yarn | Bun |
| Go | Rust |
| Python | Julia/Rust/AffineScript |
| Java/Kotlin | Rust/Tauri/Dioxus |
| Swift | Tauri/Dioxus |
| React Native | Tauri/Dioxus |
| Flutter/Dart | Tauri/Dioxus |

### Mobile Development

**No exceptions for Kotlin/Swift** - use Rust-first approach:

1. **Tauri 2.0+** - Web UI (AffineScript) + Rust backend, MIT/Apache-2.0
2. **Dioxus** - Pure Rust native UI, MIT/Apache-2.0

Both are FOSS with independent governance (no Big Tech).

### Enforcement Rules

1. **No new TypeScript files** - Convert existing TS to AffineScript
2. **Use `package.json` + `bun.lock` for JS runtime deps** - Bun is npm-compatible; a manifest is REQUIRED
3. **`bun install --production --frozen-lockfile` for production deps** - resolved from `package.json` and pinned via `bun.lock`; `--frozen-lockfile` makes a lockfile mismatch a build failure rather than a silent re-resolve
4. **No Go code** - Use Rust instead
5. **No Python anywhere** - Use Julia for data/batch, Rust for systems, AffineScript for apps
6. **No Kotlin/Swift for mobile** - Use Tauri 2.0+ or Dioxus

### Package Management

- **Primary**: Guix (guix.scm)
- **Fallback**: Nix (flake.nix)
- **JS deps**: Bun (`package.json` + `bun.lock`). Declare tooling as a devDependency and run `bunx --no-install --bun <tool>` — a bare `bunx <tool>` can fetch an unpinned package and may start Node via its shebang.

### Security Requirements

- No MD5/SHA1 for security (use SHA256+)
- HTTPS only (no HTTP URLs)
- No hardcoded secrets
- SHA-pinned dependencies
- SPDX license headers on all files

### Nickel Augmentation Boundary

Nickel "augments" RSR templates by providing typed, validated configuration where contracts and merging semantics add value. This section clarifies what Nickel handles versus what remains in other systems.

#### What Nickel DOES (In Scope)

| Use Case | Example | Why Nickel |
|----------|---------|------------|
| **Build configuration** | `build.ncl` | Contracts validate targets, dependencies |
| **CI/CD pipelines** | `ci.ncl` → generates YAML | Merge semantics for matrix builds |
| **Infrastructure config** | `infra.ncl` | Type-safe secrets references, environment configs |
| **Cross-cutting concerns** | Shared linting/formatting rules | Single source of truth with overrides |
| **Complex validation** | Config schemas with invariants | Contracts catch errors before runtime |

#### What Nickel DOES NOT Do (Out of Scope)

| Responsibility | Stays In | Reason |
|----------------|----------|--------|
| **State/meta governance** | Guile Scheme | `STATE.scm`, `META.scm`, `ECOSYSTEM.scm` are Scheme by RSR spec |
| **Package definitions** | Guix/Nix | `guix.scm`, `flake.nix` use native languages |
| **Runtime configuration** | Environment vars / JSON | Nickel is build-time, not runtime |
| **Application logic** | AffineScript/Rust | Nickel is declarative config, not imperative code |
| **Simple key-value configs** | TOML/JSON | Nickel overhead not justified for flat configs |

#### Boundary Rules

1. **Nickel generates, Scheme governs** - Nickel may produce CI/build artifacts, but `STATE.scm` remains the source of truth for project state
2. **Contracts, not code** - If you're writing loops or complex logic, use AffineScript/Rust instead
3. **Augments, doesn't replace** - Nickel configs may import/reference Guix/Nix outputs but don't replace them
4. **Validation at build-time** - Nickel catches config errors during build, not at runtime

