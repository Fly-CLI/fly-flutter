# Security Policy

## Reporting Security Issues

- **Email:** security@fly-cli.dev
- **Response Time:** < 24 hours for critical, < 72 hours for non-critical
- **Disclosure:** Coordinated disclosure after 90 days

## Template Security

- Official templates are signed with checksums
- Custom templates are sandboxed and require user confirmation
- Templates are scanned for hardcoded secrets, suspicious imports, file system access

## Dependency Security

- All dependencies scanned for known vulnerabilities (GitHub Dependabot)
- Critical vulnerabilities patched within 48 hours
- Security advisories published for all CVEs

## Update Security

- CLI updates verified via checksums
- Auto-update mechanism uses HTTPS with certificate pinning
