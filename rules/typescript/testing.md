---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# TypeScript Testing

> Extends `common/testing.md`.

## Coverage: 80%+

- Pure utilities ≥ 90%
- Custom hooks ≥ 85%
- Presentational components ≥ 80%
- Container components ≥ 70%

## TDD

1. Write test (RED)
2. Run — fails
3. Minimal impl (GREEN)
4. Run — passes
5. Refactor (IMPROVE)
6. Verify ≥ 80%

## AAA Pattern

```typescript
test('calculates similarity correctly', () => {
  // Arrange
  const v1 = [1, 0, 0];
  const v2 = [0, 1, 0];
  // Act
  const sim = calculateCosineSimilarity(v1, v2);
  // Assert
  expect(sim).toBe(0);
});
```

## E2E

Playwright for critical user flows.

## Claude Code Hooks

### PostToolUse

- **Prettier**: auto-format after edit
- **ESLint**: `--fix` after edit
- **TypeScript**: `tsc --noEmit --incremental`
- **console.log**: warn after edit

### Stop

- **console.log audit**: check modified files before session end
