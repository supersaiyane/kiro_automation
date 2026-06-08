---
id: modern_react_nextjs_patterns
version: 1.0.0
owners: [frontend_lead, senior_engineer_fe]
tags: [react, nextjs, server-components, suspense, app-router, ssr, ssg]
when_to_use: |
  Architecting or auditing a React-based frontend in 2026. React 19 +
  Next.js App Router + Server Components changed the model. Sticking
  to 2020 patterns leaves big perf wins on the table.
inputs:
  - existing_stack, target_perf, team_skill, framework_choice
outputs:
  - "react_design: rendering model + state shape + data fetching + caching + bundle"
---

# Modern React + Next.js Patterns (2026)

> The 2020-era React playbook (CSR + Redux + useEffect everywhere) is
> still common but no longer optimal. React 19 + Server Components +
> Suspense + better SSR primitives changed what "good React" looks
> like.

## The rendering model menu

| Model | When | Where rendered |
|---|---|---|
| **SSG** (Static Site Generation) | Marketing pages, blog, docs | Build time → CDN |
| **SSR** (Server-Side Rendering) | Personalized pages, dashboards | Per request, server |
| **ISR** (Incremental Static Regeneration) | Mostly-static with periodic updates | Cached, revalidate on demand |
| **CSR** (Client-Side Rendering) | Highly interactive (in-app surfaces) | Browser |
| **PPR** (Partial Pre-Rendering, Next 15+) | Mixed: static shell + dynamic islands | Hybrid |
| **RSC** (React Server Components) | Data-heavy components | Server, streamed |

Default for marketing site: **SSG**. For SaaS app: **mix of SSR + RSC
for shells + CSR for interactive widgets**.

## React Server Components (RSC) — the 2024+ shift

```tsx
// Server Component (default in App Router)
// Runs on server. Can fetch DB directly. No bundle cost.
async function ProductList({ category }: { category: string }) {
  const products = await db.products.findMany({ where: { category } });
  return (
    <ul>
      {products.map(p => <ProductCard key={p.id} product={p} />)}
    </ul>
  );
}

// Client Component
'use client';
function AddToCartButton({ productId }: { productId: string }) {
  const [adding, setAdding] = useState(false);
  // interactive logic here
}
```

Rules:
- DEFAULT to Server Component.
- Add `'use client'` only when you need state, effects, browser APIs,
  or event handlers.
- Data fetched in Server Components is on the server (no API roundtrip
  from client).
- Bundle stays smaller — server components ship ZERO JS.

## App Router (Next.js 13+ canonical)

File-based routing with layouts + loading + error boundaries:

```
app/
├── layout.tsx                  ← root layout (always)
├── page.tsx                    ← /
├── loading.tsx                 ← suspense fallback for /
├── error.tsx                   ← error boundary for /
├── (marketing)/                ← route group, no URL impact
│   ├── pricing/page.tsx        ← /pricing
│   └── blog/[slug]/page.tsx    ← /blog/:slug
├── (app)/
│   ├── layout.tsx              ← shared layout for /(app)/*
│   └── dashboard/
│       ├── page.tsx
│       └── settings/page.tsx
└── api/
    └── webhook/route.ts        ← API route
```

Benefits:
- Co-located code per route.
- Nested layouts (auth shell, dashboard chrome).
- Streaming + Suspense per segment.
- Built-in error + loading states.

## Data fetching — fetch on the server

```tsx
// Old way (client component fetching)
'use client';
function UserProfile() {
  const [user, setUser] = useState(null);
  useEffect(() => {
    fetch('/api/me').then(r => r.json()).then(setUser);
  }, []);
  if (!user) return <Skeleton />;
  return <div>{user.name}</div>;
}

// New way (server component, no waterfall)
async function UserProfile() {
  const user = await getCurrentUser();   // direct DB / API call
  return <div>{user.name}</div>;
}
```

Wrap in Suspense for streaming:

```tsx
export default function Page() {
  return (
    <>
      <Header />
      <Suspense fallback={<Skeleton />}>
        <UserProfile />
      </Suspense>
      <Footer />
    </>
  );
}
```

Header + Footer ship to browser immediately; UserProfile streams in
when ready.

## Server Actions — forms without API routes

```tsx
// Server Action (no API endpoint needed)
async function createPost(formData: FormData) {
  'use server';
  const title = formData.get('title');
  await db.posts.create({ title });
  revalidatePath('/posts');
}

// Form uses the action directly
function NewPostForm() {
  return (
    <form action={createPost}>
      <input name="title" required />
      <button type="submit">Create</button>
    </form>
  );
}
```

Benefits:
- No /api/posts route + fetch + JSON.
- Type-safe inputs.
- Works without JS (progressive enhancement).
- Optimistic updates via `useOptimistic`.

## Streaming + Suspense

Show what you have; stream the rest:

```tsx
<Suspense fallback={<HeaderSkeleton />}>
  <Header />
</Suspense>
<Suspense fallback={<ContentSkeleton />}>
  <Content />
</Suspense>
<Suspense fallback={<SidebarSkeleton />}>
  <Sidebar />
</Suspense>
```

User sees skeletons immediately; each section pops in when ready.
First-paint < 200ms even with slow data.

## Caching — Next.js caching levels (2024+)

Next 13-14 had aggressive defaults that confused everyone. Next 15
flipped defaults to OFF for most. Know which cache layers exist:

| Layer | What |
|---|---|
| **Request memoization** | Within a render, identical `fetch()` deduped |
| **Data cache** | `fetch()` results cached across requests (opt in via `next: { revalidate: 60 }`) |
| **Full route cache** | Static segments cached on build (default for static) |
| **Router cache** | Client navigation cache |

Cache control:

```tsx
// Force dynamic
export const dynamic = 'force-dynamic';

// Per-fetch
const data = await fetch(url, { next: { revalidate: 3600 } });

// Tag-based invalidation
const data = await fetch(url, { next: { tags: ['products'] } });
// later, in server action:
revalidateTag('products');
```

## React 19 features worth using

- **`use` hook**: suspend on a promise / context directly.
- **`useActionState`**: form state with server actions.
- **`useFormStatus`**: form-submission state in nested components.
- **`useOptimistic`**: optimistic UI updates.
- **`forwardRef` no longer needed**: refs as props.
- **Document metadata**: `<title>` / `<meta>` in components, deduplicated.
- **Async transitions**: `useTransition` works with async functions.
- **Improved hydration errors**: actually diagnostic.

## Patterns to STOP doing

- **`useEffect` for data fetching.** Use server components or
  TanStack Query.
- **Redux for everything.** Use Zustand or Jotai for client state; let
  RSC handle server data.
- **CSS-in-JS (Emotion, styled-components).** SSR-incompatible with
  RSC. Use Tailwind, CSS Modules, vanilla-extract, or Panda CSS.
- **Default exports for everything.** Named exports survive
  refactoring.
- **Class components.** Hooks won.
- **PropTypes.** TypeScript.
- **Manual code-splitting via React.lazy.** Next does this automatically
  per route.
- **Wrapping everything in `useMemo`.** Often premature.
- **`useEffect` for derived state.** Compute during render.
- **`window.location.href = ...`** for navigation. Use `next/link` +
  router.push.

## Bundle optimization

Modern budget: < 200KB JS on first load for marketing, < 500KB for SaaS
shell.

Tools:
- `next build` + analyze (`@next/bundle-analyzer`).
- Webpack-bundle-analyzer for non-Next apps.
- Identify top 5 largest deps; consider lighter alternatives.

Common bloat:
- moment.js (40KB) → date-fns or dayjs (2KB).
- lodash full (70KB) → lodash-es with tree-shake, or just write the
  helper.
- Large icon libs → import only used icons.
- AntD / MUI full lib import.

## Choose: Next.js / Remix / TanStack Start / Astro

| Framework | Use |
|---|---|
| **Next.js** | Default for full-stack React; biggest ecosystem |
| **Remix** | Form-first, web standards, simpler model |
| **TanStack Start** | Newer, file-based router for TanStack Query users |
| **Astro** | Best for content-heavy / mostly-static (blogs, docs) — supports React islands |
| **Vite + React** | SPA with no SSR needs; lightweight |
| **Vue / Svelte / Solid** | Different ecosystems; consider only if team strength |

Default for B2B SaaS marketing: **Astro** (perf-first, MDX support).
Default for SaaS app: **Next.js App Router**.

## State management taxonomy

Server state (data from backend): **TanStack Query** or RSC.
Client state (UI toggles, form drafts): **useState** / **Zustand**.
URL state (filters, current tab): **searchParams** via router.
Form state: **React Hook Form** + Server Actions.

NEVER use Redux for what TanStack Query handles (most data fetching).
Old Redux apps can stay; new ones should not start there.

## Performance checklist

- [ ] LCP image preloaded + fetchpriority="high".
- [ ] Above-fold CSS inlined (Next does automatically).
- [ ] Lazy-load below-fold images + iframes.
- [ ] Server Components for static / data-heavy parts.
- [ ] Suspense + streaming for slow sections.
- [ ] No JS framework on marketing pages where possible (Astro).
- [ ] Routes code-split per file (automatic in App Router).
- [ ] Bundle analyzer reviewed; top deps justified.
- [ ] Core Web Vitals green in CrUX.

## Anti-patterns

- **Mixing pages/ and app/ directories** unnecessarily.
- **'use client' at the top of every component.** Defaults to RSC.
- **Server Action that returns sensitive data without authz.**
- **`fetch` without cache discipline** — accidental over-caching or
  thrashing.
- **State in 3 places** (URL + Redux + useState) for the same data.
- **Custom server abstraction** that fights the framework.
- **SSR for everything when SSG works** — slower + costs more.
- **Going full-CSR for "interactivity"** when an Astro island would do.

## Validation

- [ ] Rendering model documented per route.
- [ ] RSC + Server Actions used where applicable.
- [ ] Suspense + streaming for slow boundaries.
- [ ] Cache strategy explicit per fetch.
- [ ] React 19 features adopted where they fit.
- [ ] Bundle size measured + budgeted.
- [ ] No use-effect data fetching in new code.
- [ ] Linter rules block class components + outdated patterns.
