---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
---

# React Testing

> Extends `common/testing.md`.

## Library Choice

- **React Testing Library (RTL)**: standard for component testing. Tests behavior through the rendered DOM
- **Vitest**: preferred runner for Vite projects
- **Jest**: default for Next.js / CRA projects
- **Playwright Component Testing**: when tests need a real browser engine (animation, layout, complex events)
- Pick one component test runner per project

## Core Principle

Test what the user sees and does, not implementation details.

## Query Priority (top-down)

1. **Accessible to everyone**: `getByRole` → `getByLabelText` → `getByPlaceholderText` → `getByText` → `getByDisplayValue`
2. **Semantic queries**: `getByAltText` → `getByTitle` (last resort)
3. **Test IDs**: `getByTestId` (escape hatch only, when none of the above work)

## User Interaction

Prefer `userEvent` over `fireEvent` (`userEvent` simulates real browser sequences):

```tsx
const user = userEvent.setup();
await user.type(screen.getByLabelText("Email"), "user@example.com");
await user.click(screen.getByRole("button", { name: /save/i }));
```

## Async Assertions

```tsx
// Async element appearance
expect(await screen.findByText("Loaded")).toBeInTheDocument();

// Async side effects
await waitFor(() => expect(saveSpy).toHaveBeenCalled());
```

Never use `setTimeout` + assertion.

## Network Mocking (MSW)

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

## Custom Hook Testing

```tsx
const { result } = renderHook(() => useCounter());
act(() => result.current.increment());
expect(result.current.count).toBe(1);
```

## Anti-Patterns

- Asserting on `container.querySelector` — bypasses accessibility queries
- Asserting on number of renders — implementation detail
- Mocking React hooks — refactor the component instead
- Mocking child components by default — tests the integration, not the parent in isolation
- Ignoring manual `act()` warnings — they indicate real bugs

## Coverage Targets

| Layer | Target |
|---|---|
| Pure utility functions | ≥ 90% |
| Custom hooks | ≥ 85% |
| Components (presentational) | ≥ 80% |
| Container components | ≥ 70% |
| Pages (E2E covered separately) | Smoke test per route minimum |
