---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "components/**"
  - "app/**"
  - "pages/**"
---

# React Rules

> Auto-loaded for `*.tsx` / `*.jsx` / `components/**` / `app/**` / `pages/**`. Extends `typescript.md`.

## Coding Style

### File Extensions

- `.tsx` for any file containing JSX
- `.ts` for pure logic, custom hooks without JSX, type definitions, utilities
- `.jsx` is forbidden unless the project intentionally avoids TypeScript

### Naming

- Components: `PascalCase`, file name matches component name (`UserCard.tsx` → `export function UserCard`)
- Custom hooks: `useCamelCase` (`useDebounce.ts` → `export function useDebounce`)
- Context: `<Domain>Context` + `<Domain>Provider` + `use<Domain>`
- Event handlers: `handleClick`, `handleSubmit` inside the component; the prop is `onClick`, `onSubmit`
- Boolean props: `isLoading`, `hasError`, `canSubmit` — never `loading` or `error` alone

### Component Shape

```tsx
type Props = {
  user: User;
  onSelect: (id: string) => void;
};

export function UserCard({ user, onSelect }: Props) {
  return (
    <button type="button" onClick={() => onSelect(user.id)}>
      {user.name}
    </button>
  );
}
```

- Use `type Props = {}` for closed component prop shapes; `interface` only when declaration merging is needed
- Always destructure props in the parameter list — no `props.user`
- Let TS infer the return type; do not annotate `: JSX.Element`

### JSX

- Self-close tags with no children: `<img />`, `<UserCard user={u} />`
- Use Fragment `<>...</>` when no DOM wrapper is needed
- Conditional rendering: `&&` for simple booleans, ternary for either/or, early return for guard clauses
- Extract multi-line logic from JSX to a `const` or function

```tsx
// Prefer
const greeting = user.isAdmin ? "Welcome, admin" : `Hello ${user.name}`;
return <h1>{greeting}</h1>;

// Avoid
return <h1>{user.isAdmin ? "Welcome, admin" : `Hello ${user.name}`}</h1>;
```

### Import Order

1. React: `import { useState } from "react"`
2. Third-party libraries
3. Absolute project imports
4. Relative imports
5. Type-only imports: `import type { ReactNode } from "react"`

### Class Components

Forbidden in new code. Convert to function components when touching a class component for non-trivial changes.

### File Layout

```
components/UserCard/
  UserCard.tsx
  UserCard.module.css
  UserCard.test.tsx
  index.ts              # re-export only
```

## React Hooks (Component Hooks, not Claude Code Hooks)

### Rules

- Only call hooks at the top level of a function component or custom hook
- Never in loops, conditionals, nested functions, or after early returns
- Enable `eslint-plugin-react-hooks`; `rules-of-hooks: error`, `exhaustive-deps: warn`

### `useEffect` — When NOT to Use

`useEffect` is for synchronizing with external systems. It is **not** the right tool for:

- Derived state → compute it during render
- Data transformation for rendering → compute it during render
- Resetting state when a prop changes → use `key` or derive from props
- Notifying a parent of state changes → call the callback in the event handler
- Initializing app-level singletons → module-top level or `main.tsx`

```tsx
// WRONG: effect for derived state
const [fullName, setFullName] = useState("");
useEffect(() => { setFullName(`${first} ${last}`); }, [first, last]);

// CORRECT: derive during render
const fullName = `${first} ${last}`;
```

### Dependency Arrays

- Include every reactive value referenced inside the effect/callback
- Never silence `exhaustive-deps` without a comment explaining why
- If the dep array grows unwieldy, the effect is doing too much — split it

### Cleanup

Every subscription, interval, event listener, and network request must clean up:

```tsx
useEffect(() => {
  const controller = new AbortController();
  fetch(url, { signal: controller.signal }).then(handleResponse);
  return () => controller.abort();
}, [url]);
```

### `useMemo` / `useCallback` — When Worth It

Default: do not memoize. Add only when:

1. The value is passed to a `React.memo`-wrapped child as a prop, and identity matters
2. The value is a dependency of another `useEffect` / `useMemo` / `useCallback`
3. The computation is measurably expensive (profile before assuming)

Premature memoization adds noise, hides bugs, and can be slower than the recompute it replaces.

### Custom Hooks

**Extract when**: the same hook sequence appears in 2+ components, the logic has a clear nameable purpose, or you need to test it independently.

**Do NOT extract when**: it has a single caller, or it is just `useState` with a different name.

### `useState` Patterns

- Use functional updater when new state depends on old: `setCount(c => c + 1)`
- Group related state into one object only when they always change together; otherwise split into multiple `useState` calls
- 3+ related values with state transitions conditional on previous state → `useReducer`

### `useRef` Patterns

- DOM refs for imperative APIs (focus, scroll, third-party libs)
- Mutable container that does not trigger re-render (timer ids, previous values, "is mounted" flags)
- Never read or write `ref.current` during render

### Stale Closure Trap

Async handlers and intervals capture values from the render where they were created. Fix by:
1. Using the functional updater form of `setState`
2. Putting the changing value in the dep array of `useEffect` and rebuilding the handler
3. Reading from a ref kept in sync

## State Management

### State Location Decision Tree

1. Used by one component → `useState` inside it
2. Used by parent + a few children → lift to nearest common ancestor, pass via props
3. Used across distant branches → React Context (only for low-frequency reads: theme, auth, locale)
4. High-frequency updates shared across the tree → external store (Zustand, Jotai, Redux Toolkit)
5. Server-derived data → server-state library (TanStack Query, SWR, RSC fetch) — not application state

Context misused for frequently changing values causes every consumer to re-render on every update.

### State Categories

| Concern | Tooling |
|---|---|
| Server state | TanStack Query, SWR, tRPC |
| Client state | Zustand, Jotai, signals |
| URL state | search params, route segments |
| Form state | React Hook Form or equivalent |

- Do not duplicate server state into client stores
- Derive values instead of storing redundant computed state

## Component Patterns

### Container / Presentational Split

```tsx
// Container — owns data
export function UserPage({ userId }: { userId: string }) {
  const { data: user, isLoading } = useUser(userId);
  if (isLoading) return <Spinner />;
  if (!user) return <NotFound />;
  return <UserCard user={user} onSelect={handleSelect} />;
}

// Presentational — pure
export function UserCard({ user, onSelect }: Props) {
  return <button onClick={() => onSelect(user.id)}>{user.name}</button>;
}
```

### Server / Client Component Boundary (RSC, Next.js App Router)

- Server Components are the default — they run on the server, do not ship to the client, and can `await` directly
- Client Components opt in with `"use client"` at the top of the file
- Data flows down: a Server Component can render a Client Component and pass serializable props
- A Client Component cannot import a Server Component, but can receive one via `children` or named slots

```tsx
// Server (default)
export default async function Page() {
  const user = await fetchUser();
  return <UserClient user={user} />;
}

// Client
"use client";
export function UserClient({ user }: { user: User }) {
  const [tab, setTab] = useState("profile");
  return <Tabs value={tab} onChange={setTab}>{user.name}</Tabs>;
}
```

- Never import `"server-only"` packages from a Client Component file
- Mark sensitive modules with `import "server-only"`

### Suspense + Error Boundaries

Every Suspense boundary must have an Error Boundary above it:

```tsx
<ErrorBoundary fallback={<ErrorView />}>
  <Suspense fallback={<Skeleton />}>
    <UserDetails id={id} />
  </Suspense>
</ErrorBoundary>
```

### Composition over Inheritance

- Pass `children` for slot-style composition
- Pass render-prop functions for parameterized rendering
- Pass component types for plug-in points: `renderItem={UserRow}`
- Never extend a component class to specialize behavior

### Compound Components

For related controls (Tabs, Accordion, Menu), use compound components sharing state via Context:

```tsx
<Tabs defaultValue="profile">
  <Tabs.List>
    <Tabs.Trigger value="profile">Profile</Tabs.Trigger>
    <Tabs.Trigger value="settings">Settings</Tabs.Trigger>
  </Tabs.List>
  <Tabs.Panel value="profile"><ProfileForm /></Tabs.Panel>
  <Tabs.Panel value="settings"><SettingsForm /></Tabs.Panel>
</Tabs>
```

### Lists and Keys

- `key` must be stable across renders — never use `index` for any list that can reorder, insert, or delete
- `key` must be unique among siblings, not globally
- A reordered list with index keys causes state in child components to attach to the wrong row

### Forms

- **Uncontrolled (React 19 + form actions)**: prefer when there is a clear submit step. The browser owns the value; React reads it via `FormData`
- **Controlled**: use when the value drives other UI, requires real-time validation, or formatting
- **Complex forms** (multi-step, dynamic field arrays, cross-field validation) → React Hook Form / TanStack Form

### Data Fetching

| Strategy | When |
|---|---|
| RSC fetch (`await` in Server Component) | Per-request data in Next.js App Router, no client-side cache needed |
| TanStack Query | Client-side cache, mutations, optimistic updates, polling |
| SWR | Lightweight cache + revalidation, simpler than TanStack Query |
| `fetch` in `useEffect` | Avoid — race conditions, no cache, no retry. Only for one-off fire-and-forget |

## React Security

### XSS via `dangerouslySetInnerHTML`

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

### Unsafe URL Schemes

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

### `target="_blank"` Without `rel`

Always explicitly add `rel="noopener noreferrer"` — do not rely on browser defaults.

### Server Action Input Validation

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

### Authentication / Authorization

- Never store sessions in `localStorage` (readable by any XSS) — use httpOnly secure cookies
- Never trust client-set state to gate sensitive UI — JSX render-gating prevents display, not access; the API must enforce
- Cookie-based auth requires CSRF tokens or `SameSite=Strict` / `Lax` cookies

### Prototype Pollution

```tsx
// WRONG: untrusted JSON spread directly into state
const update = await req.json();
setState({ ...state, ...update });    // attacker controls __proto__

// CORRECT: parse with a schema, or guard keys
const Allowed = z.object({ name: z.string(), email: z.string().email() });
const parsed = Allowed.parse(await req.json());
```

### Source Maps

Production builds should ship without source maps, or with source maps uploaded to an error tracker (Sentry) and stripped from the public bundle.

## React Testing

### Library Choice

- **React Testing Library (RTL)**: standard for component testing. Tests behavior through the rendered DOM
- **Vitest**: preferred runner for Vite projects
- **Jest**: default for Next.js / CRA projects
- **Playwright Component Testing**: when tests need a real browser engine (animation, layout, complex events)
- Pick one component test runner per project

### Core Principle

Test what the user sees and does, not implementation details.

### Query Priority (top-down)

1. **Accessible to everyone**: `getByRole` → `getByLabelText` → `getByPlaceholderText` → `getByText` → `getByDisplayValue`
2. **Semantic queries**: `getByAltText` → `getByTitle` (last resort)
3. **Test IDs**: `getByTestId` (escape hatch only, when none of the above work)

### User Interaction

Prefer `userEvent` over `fireEvent` (`userEvent` simulates real browser sequences):

```tsx
const user = userEvent.setup();
await user.type(screen.getByLabelText("Email"), "user@example.com");
await user.click(screen.getByRole("button", { name: /save/i }));
```

### Async Assertions

```tsx
// Async element appearance
expect(await screen.findByText("Loaded")).toBeInTheDocument();

// Async side effects
await waitFor(() => expect(saveSpy).toHaveBeenCalled());
```

Never use `setTimeout` + assertion.

### Network Mocking (MSW)

Mock at the network layer — components, hooks, and fetch libraries all behave as in production:

```tsx
const server = setupServer(
  http.get("/api/users/:id", ({ params }) =>
    HttpResponse.json({ id: params.id, name: "Alice" })
  ),
);
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

### Custom Hook Testing

```tsx
const { result } = renderHook(() => useCounter());
act(() => result.current.increment());
expect(result.current.count).toBe(1);
```

### Anti-Patterns

- Asserting on `container.querySelector` — bypasses accessibility queries
- Asserting on number of renders — implementation detail
- Mocking React hooks — refactor the component instead
- Mocking child components by default — tests the integration, not the parent in isolation
- Ignoring manual `act()` warnings — they indicate real bugs

### Coverage Targets

| Layer | Target |
|---|---|
| Pure utility functions | ≥ 90% |
| Custom hooks | ≥ 85% |
| Components (presentational) | ≥ 80% |
| Container components | ≥ 70% |
| Pages (E2E covered separately) | Smoke test per route minimum |