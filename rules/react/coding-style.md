---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "components/**"
  - "app/**"
  - "pages/**"
---

# React Coding Style

> Components, hooks, JSX. Extends `typescript/coding-style.md` and `common/coding-style.md`.

## File Extensions

- `.tsx` for any file containing JSX
- `.ts` for pure logic, custom hooks without JSX, type definitions, utilities
- `.jsx` is forbidden unless the project intentionally avoids TypeScript

## Naming

- Components: `PascalCase`, file name matches component name (`UserCard.tsx` → `export function UserCard`)
- Custom hooks: `useCamelCase` (`useDebounce.ts` → `export function useDebounce`)
- Context: `<Domain>Context` + `<Domain>Provider` + `use<Domain>`
- Event handlers: `handleClick`, `handleSubmit` inside the component; the prop is `onClick`, `onSubmit`
- Boolean props: `isLoading`, `hasError`, `canSubmit` — never `loading` or `error` alone

## Component Shape

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

## JSX

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

## Import Order

1. React: `import { useState } from "react"`
2. Third-party libraries
3. Absolute project imports
4. Relative imports
5. Type-only imports: `import type { ReactNode } from "react"`

## Class Components

Forbidden in new code. Convert to function components when touching a class component for non-trivial changes.

## File Layout

```
components/UserCard/
  UserCard.tsx
  UserCard.module.css
  UserCard.test.tsx
  index.ts              # re-export only
```

## React Hooks

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
