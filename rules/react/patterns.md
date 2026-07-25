---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
---

# React Patterns

> State management, component architecture, data fetching. Extends `common/patterns.md`.

## State Location Decision Tree

1. Used by one component → `useState` inside it
2. Used by parent + a few children → lift to nearest common ancestor, pass via props
3. Used across distant branches → React Context (only for low-frequency reads: theme, auth, locale)
4. High-frequency updates shared across the tree → external store (Zustand, Jotai, Redux Toolkit)
5. Server-derived data → server-state library (TanStack Query, SWR, RSC fetch) — not application state

Context misused for frequently changing values causes every consumer to re-render on every update.

## State Categories

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
