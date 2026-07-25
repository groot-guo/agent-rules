---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# TypeScript Coding Style

> Types, naming, immutability, security. Extends `common/coding-style.md`.

## Types

- Exported functions: explicit param + return types; let TS infer locals
- `interface` for object shapes, `type` for unions/intersections/tuples/mapped/utility
- Never `any` — `unknown` for external input (narrow safely), generics when caller picks the type
- String literal unions over `enum` (unless interop requires `enum`)
- Component props: `type Props = {}` or `interface` — not `React.FC`

## Immutability

New objects, not mutation:
```typescript
// wrong
user.name = name;
return user;

// right
return { ...user, name };
```

## Naming

- Variables/functions: `camelCase`
- Interfaces/types/components: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- Booleans: `is`/`has`/`should`/`can` prefix

## Files

- Many small > few large: 200–400 typical, 800 max
- Organize by feature/domain, not file type
- No `console.log` in prod — use a logging library

## Errors

- Handle explicitly at every level — never silent
- UI: user-friendly messages; server: detailed logs
- `catch` error is `unknown` — narrow before use:
```typescript
function getErrorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return 'Unexpected error';
}
```

## Input Validation

Zod schema → infer types:
```typescript
const userSchema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150),
});
type UserInput = z.infer<typeof userSchema>;
```

## Security

### Secrets

- Env vars only — never hardcode
- Validate at startup:
```typescript
const apiKey = process.env.API_KEY;
if (!apiKey) throw new Error('API_KEY not configured');
```

### Framework Env Prefixes

| Framework | Public | Private |
|---|---|---|
| Next.js | `NEXT_PUBLIC_*` | rest |
| Vite | `VITE_*` | `.env` server-only |
| CRA | `REACT_APP_*` | rest |

Prefixed vars are bundled into the client — treat as public.

### Pre-Commit Security Checklist

- [ ] No hardcoded secrets
- [ ] All user input validated
- [ ] No SQL injection (parameterized)
- [ ] No XSS (escaped)
- [ ] Errors don't leak sensitive data

## General Checklist

- [ ] Exported functions typed
- [ ] No `any`
- [ ] No unnecessary mutation
- [ ] No `console.log`
- [ ] Files < 800 lines, functions < 50 lines
- [ ] Nesting ≤ 4
