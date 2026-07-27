# Security Standards

> Mandatory checks for all code changes. Language specifics in `rules/<lang>.md`.

## Secrets & Credentials

Never in source code:
- No API keys, tokens, passwords, private keys, connection strings in repo
- `.env` / config files with secrets → `.gitignore`, committed as `.example` only
- Use env vars, secret managers, or vaults at runtime
- Found committed → rotate immediately, purge from git history

## Input Validation

At every system boundary:
- All external input validated before processing: user input, API payloads, file uploads, query params
- Validate: type, length, range, format, allowed characters — not just existence
- SQL / shell / OS commands → never concatenate user input; use parameterized queries
- File uploads: check MIME type, size limit, scan content; store outside web root

## Injection Prevention

- **SQL**: parameterized queries only — no string interpolation, no `fmt.Sprintf` for WHERE/IN
- **Shell**: avoid shelling out; if unavoidable, `exec` with arg array, never `system(userInput + "...")`
- **HTML/JS**: output-encode on render; no `innerHTML` with user data; Content-Security-Policy header
- **Path traversal**: sanitize file paths from user input; resolve, then verify stays within allowed root

## Authentication & Authorization

- Authentication happens at the outermost layer, not in business logic
- Authorization check on every protected operation — not just at route level
- Session tokens: secure, HttpOnly, SameSite; no sensitive data in JWT payload
- Fail closed: deny by default, allow explicitly

## Data Exposure

- Never return internal errors / stack traces to clients
- Log sensitive operations but mask PII / secrets in logs
- API responses: only fields the caller needs — no ORM entity passthrough
- Rate-limit public endpoints; no unbounded list without pagination

## Dependencies

- Audit before adding: check license, maintenance status, known CVEs
- Pin versions; lockfile committed; no `latest` / `*` in deps
- Dependabot / Renovate enabled; apply security patches promptly

## Cryptography

- Never roll your own crypto; use standard libraries only
- bcrypt / argon2 for passwords; AES-GCM for symmetric; TLS 1.3 for transport
- No MD5 / SHA1 for security; no hardcoded salts/IVs
