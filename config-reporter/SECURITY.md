# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

1. **Do not** create a public GitHub issue for security vulnerabilities
2. Email the maintainer directly at: jonathan.jewell@open.ac.uk
3. Include as much detail as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We aim to respond to security reports within 48 hours and will work with you to address the issue promptly.

## Security Measures in This Repository

### CI/CD Pipeline Security

- **Action Version Pinning**: All GitHub Actions are pinned to specific commit SHAs, not tags
- **Minimal Permissions**: Workflows use `permissions: read-all` (principle of least privilege)
- **SSH Host Key Verification**: Known hosts are verified before SSH connections to prevent MITM attacks
- **Secret Management**: Credentials are stored as GitHub organization secrets, never in code
- **Concurrency Controls**: Mirror operations are serialized to prevent race conditions
- **Job Timeouts**: All jobs have explicit timeouts to prevent runaway processes

### Repository Mirroring

The multi-platform mirroring workflow includes:
- SSH key-based authentication (no password storage)
- Force push capability (required for true mirroring, documented)
- Conditional execution based on repository variables
- Independent mirror jobs that can fail without affecting others

### Secrets Required

This repository requires the following secrets at the organization or repository level:
- `GITLAB_SSH_KEY`: Private SSH key for GitLab mirror
- `CODEBERG_SSH_KEY`: Private SSH key for Codeberg mirror
- `BITBUCKET_SSH_KEY`: Private SSH key for Bitbucket mirror

### Repository Variables

- `GITLAB_MIRROR_ENABLED`: Set to `'true'` to enable GitLab mirroring
- `CODEBERG_MIRROR_ENABLED`: Set to `'true'` to enable Codeberg mirroring
- `BITBUCKET_MIRROR_ENABLED`: Set to `'true'` to enable Bitbucket mirroring

## Best Practices

When contributing to this repository:

1. Never commit secrets, credentials, or API keys
2. Review workflow changes carefully before merging
3. Keep action versions pinned to commit SHAs
4. Use minimal permissions for any new workflows
5. Document any security-sensitive changes

## License

This project is licensed under PMPL-1.0-or-later. See the [LICENSE](LICENSE) file for details.
