# nickel-config-reporter
image:https://img.shields.io/badge/License-PMPL--1.0-blue.svg[License: PMPL-1.0,link="https://github.com/hyperpolymath/palimpsest-license"]



A configuration reporter utility with multi-platform SCM mirroring infrastructure.

## Overview

This repository provides automated mirroring infrastructure to synchronize code across multiple Git hosting platforms:

- **GitHub** (primary)
- **GitLab**
- **Codeberg**
- **Bitbucket**

## Features

- **Hub-and-Spoke Mirroring**: GitHub serves as the primary repository with automatic mirroring to secondary platforms
- **Security-First Design**: SSH host key verification, pinned action versions, minimal permissions
- **Conditional Mirroring**: Enable/disable individual mirrors via repository variables
- **Concurrency Safe**: Prevents race conditions during simultaneous push events

## Setup

### Prerequisites

1. GitHub repository with Actions enabled
2. SSH key pairs generated for each mirror target
3. Organization or repository secrets configured

### Configuration

#### 1. Generate SSH Keys

For each mirror platform, generate a dedicated SSH key pair:

```bash
ssh-keygen -t ed25519 -C "mirror-gitlab" -f ~/.ssh/mirror_gitlab
ssh-keygen -t ed25519 -C "mirror-codeberg" -f ~/.ssh/mirror_codeberg
ssh-keygen -t ed25519 -C "mirror-bitbucket" -f ~/.ssh/mirror_bitbucket
```

#### 2. Add Public Keys to Mirror Platforms

Add the public key (`.pub` file contents) to each platform:
- **GitLab**: Settings > SSH Keys
- **Codeberg**: Settings > SSH/GPG Keys
- **Bitbucket**: Personal Settings > SSH Keys

#### 3. Configure GitHub Secrets

Add the private keys as secrets in your GitHub repository or organization:
- `GITLAB_SSH_KEY`
- `CODEBERG_SSH_KEY`
- `BITBUCKET_SSH_KEY`

#### 4. Enable Mirrors

Set repository variables to enable desired mirrors:
- `GITLAB_MIRROR_ENABLED` = `true`
- `CODEBERG_MIRROR_ENABLED` = `true`
- `BITBUCKET_MIRROR_ENABLED` = `true`

## Usage

Once configured, the mirroring workflow runs automatically on:
- Push to `main` or `master` branches
- Manual workflow dispatch from GitHub Actions

## Security

See [SECURITY.md](SECURITY.md) for security policies and best practices.

## Roadmap

See [ROADMAP.adoc](ROADMAP.adoc) for planned features and development priorities.

## License

PMPL-1.0-or-later
