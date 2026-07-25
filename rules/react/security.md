---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "components/**"
  - "app/**"
  - "pages/**"
---

# React Security

> Extends `common/security.md`. React-specific vulnerabilities and mitigations.

## XSS via `dangerouslySetInnerHTML`

CRITICAL. Treat every usage as a code review halt:

```tsx
// CRITICAL: unsanitized user input
<div dangerouslySetInnerHTML={{ __html: userBio }} />

// CORRECT: render as text
<div>{userBio}</div>

// Or: sanitize first with DOMPurify when raw HTML is required
import DOMPurify from "isomorphic-dompurify";
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userBio) }} />
```

Audit checklist: is the input under our control? If user-derived, is it sanitized at the same call site? Is the sanitizer config allowlisting, not denylisting?

## Unsafe URL Schemes

`javascript:` and `data:` URLs in `href` / `src` execute arbitrary code:

```tsx
function safeUrl(url: string): string | undefined {
  try {
    const parsed = new URL(url);
    if (["http:", "https:", "mailto:"].includes(parsed.protocol)) return url;
  } catch { return undefined; }
  return undefined;
}
```

## `target="_blank"` Without `rel`

Always explicitly add `rel="noopener noreferrer"` — do not rely on browser defaults.

## Server Action Input Validation

Server Actions run with the same trust level as a public API endpoint. Validate every input:

```tsx
"use server";
const Input = z.object({ email: z.string().email(), age: z.number().int().min(0).max(120) });

export async function updateUser(_state: unknown, formData: FormData) {
  const parsed = Input.safeParse({ email: formData.get("email"), age: Number(formData.get("age")) });
  if (!parsed.success) return { error: parsed.error.flatten() };
}
```

- Authenticate inside the action — do not trust the client-side route gate
- Authorize: confirm the current user has permission for the specific record they are mutating
- Rate limit sensitive actions

## Authentication / Authorization

- Never store sessions in `localStorage` (readable by any XSS) — use httpOnly secure cookies
- Never trust client-set state to gate sensitive UI — JSX render-gating prevents display, not access; the API must enforce
- Cookie-based auth requires CSRF tokens or `SameSite=Strict` / `Lax` cookies

## Prototype Pollution

```tsx
// WRONG: untrusted JSON spread directly into state
const update = await req.json();
setState({ ...state, ...update });    // attacker controls __proto__

// CORRECT: parse with a schema, or guard keys
const Allowed = z.object({ name: z.string(), email: z.string().email() });
const parsed = Allowed.parse(await req.json());
```

## Source Maps

Production builds should ship without source maps, or with source maps uploaded to an error tracker (Sentry) and stripped from the public bundle.
