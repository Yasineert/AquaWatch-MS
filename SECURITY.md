# Security Policy

## Reporting a vulnerability

Please do not open a public issue for security problems. Use GitHub's
[private vulnerability reporting](../../security/advisories/new) instead.
You will receive an answer within 7 days.

## Guidelines for contributors

- Never commit `.env`, `.env.alertes`, `.env.api_sig` or any file containing credentials. Only `*.example` templates belong in Git.
- Use dedicated, revocable credentials (Gmail app passwords, Sentinel Hub OAuth clients, Copernicus keys) and rotate them if they are ever exposed.
- Every push is scanned for committed secrets with Gitleaks.
