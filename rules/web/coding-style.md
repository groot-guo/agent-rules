---
paths:
  - "**/*.html"
  - "**/*.css"
  - "**/*.scss"
  - "**/*.less"
  - "**/*.svg"
---

# Web Coding Style

> CSS, semantic HTML, accessibility. Extends `common/coding-style.md`.

## CSS / Styling

### Design Tokens

Define design tokens as CSS custom properties. Do not hardcode palette, typography, or spacing repeatedly:

```css
:root {
  --color-surface: oklch(98% 0 0);
  --color-text: oklch(18% 0 0);
  --color-accent: oklch(68% 0.21 250);

  --text-base: clamp(1rem, 0.92rem + 0.4vw, 1.125rem);
  --text-hero: clamp(3rem, 1rem + 7vw, 8rem);

  --space-section: clamp(4rem, 3rem + 5vw, 10rem);

  --duration-fast: 150ms;
  --duration-normal: 300ms;
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
}
```

### Animation Properties

Prefer compositor-friendly properties only:
- `transform`
- `opacity`
- `clip-path`
- `filter` (sparingly)

Avoid animating layout-bound properties: `width`, `height`, `top`, `left`, `margin`, `padding`, `border`, `font-size`

### File Organization

Organize by feature or surface area, not by file type:

```
src/
├── components/
│   ├── hero/
│   │   ├── Hero.tsx
│   │   ├── HeroVisual.tsx
│   │   └── hero.css
│   └── ui/
│       ├── Button.tsx
│       └── SurfaceCard.tsx
├── hooks/
│   └── useReducedMotion.ts
├── lib/
│   └── animation.ts
└── styles/
    ├── tokens.css
    ├── typography.css
    └── global.css
```

### Naming

- Components: `PascalCase` (`ScrollySection`, `SurfaceCard`)
- CSS classes: kebab-case or utility classes
- Animation timelines: camelCase with intent (`heroRevealTl`)

## Semantic HTML

Do not reach for generic `div` stacks when a semantic element exists:

```html
<header>
  <nav aria-label="Main navigation">...</nav>
</header>
<main>
  <section aria-labelledby="hero-heading">
    <h1 id="hero-heading">...</h1>
  </section>
</main>
<footer>...</footer>
```
