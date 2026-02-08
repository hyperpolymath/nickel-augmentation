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
| **ReScript** | Primary application code | Compiles to JS, type-safe |
| **Deno** | Runtime & package management | Replaces Node/npm/bun |
| **Rust** | Performance-critical, systems, WASM | Preferred for CLI tools |
| **Tauri 2.0+** | Mobile apps (iOS/Android) | Rust backend + web UI |
| **Dioxus** | Mobile apps (native UI) | Pure Rust, React-like |
| **Gleam** | Backend services | Runs on BEAM or compiles to JS |
| **Bash/POSIX Shell** | Scripts, automation | Keep minimal |
| **JavaScript** | Only where ReScript cannot | MCP protocol glue, Deno APIs |
| **Nickel** | Configuration language | Typed configs with contracts (see below) |
| **Guile Scheme** | State/meta files | STATE.scm, META.scm, ECOSYSTEM.scm |
| **Julia** | Batch scripts, data processing | Per RSR |
| **OCaml** | AffineScript compiler | Language-specific |
| **Ada** | Safety-critical systems | Where required |

### BANNED - Do Not Use

| Banned | Replacement |
|--------|-------------|
| TypeScript | ReScript |
| Node.js | Deno |
| npm | Deno |
| Bun | Deno |
| pnpm/yarn | Deno |
| Go | Rust |
| Python | Julia/Rust/ReScript |
| Java/Kotlin | Rust/Tauri/Dioxus |
| Swift | Tauri/Dioxus |
| React Native | Tauri/Dioxus |
| Flutter/Dart | Tauri/Dioxus |

### Mobile Development

**No exceptions for Kotlin/Swift** - use Rust-first approach:

1. **Tauri 2.0+** - Web UI (ReScript) + Rust backend, MIT/Apache-2.0
2. **Dioxus** - Pure Rust native UI, MIT/Apache-2.0

Both are FOSS with independent governance (no Big Tech).

### Enforcement Rules

1. **No new TypeScript files** - Convert existing TS to ReScript
2. **No package.json for runtime deps** - Use deno.json imports
3. **No node_modules in production** - Deno caches deps automatically
4. **No Go code** - Use Rust instead
5. **No Python anywhere** - Use Julia for data/batch, Rust for systems, ReScript for apps
6. **No Kotlin/Swift for mobile** - Use Tauri 2.0+ or Dioxus

### Package Management

- **Primary**: Guix (guix.scm)
- **Fallback**: Nix (flake.nix)
- **JS deps**: Deno (deno.json imports)

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
| **Application logic** | ReScript/Rust | Nickel is declarative config, not imperative code |
| **Simple key-value configs** | TOML/JSON | Nickel overhead not justified for flat configs |

#### Boundary Rules

1. **Nickel generates, Scheme governs** - Nickel may produce CI/build artifacts, but `STATE.scm` remains the source of truth for project state
2. **Contracts, not code** - If you're writing loops or complex logic, use ReScript/Rust instead
3. **Augments, doesn't replace** - Nickel configs may import/reference Guix/Nix outputs but don't replace them
4. **Validation at build-time** - Nickel catches config errors during build, not at runtime

