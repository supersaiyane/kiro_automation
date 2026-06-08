---
id: state_management_patterns
version: 1.0.0
owners: [frontend_lead]
tags: [state, react, redux, zustand, jotai, react-query, server-state, client-state]
when_to_use: |
  About to pick a state library for a new frontend, or auditing
  a codebase where state has sprawled. The 2024-2026 lesson:
  server state and client state are different problems with
  different tools. Most "state management" bugs come from using
  one tool for both.
inputs:
  - app_complexity, team_size, server_state_volume
outputs:
  - "state_strategy: server-state lib + client-state lib + when to use which + escape hatches"
---

# State Management — Server State vs Client State

> The biggest insight of the last few years: 80% of your "state"
> is a cache of server data. Treat it as such — with a cache
> library (React Query, SWR, Apollo). The remaining 20% is real
> client state — use a small library for that.

## The two kinds of state

| Server state | Client state |
|---|---|
| Source of truth lives elsewhere | App-only (UI toggles, form drafts, theme) |
| Becomes stale | Doesn't expire |
| Shared by many users | Per-user, per-session |
| Needs cache, invalidation, retries | Needs subscriptions, persistence maybe |
| TOOLS: React Query, SWR, Apollo, RTK Query | TOOLS: Zustand, Jotai, useState, Redux |

Redux managing your user list, with manual fetch, loading, error,
and refetch logic is fighting fire with a manual: a cache library
solves it in 3 lines.

## Server state — use a query library

```tsx
import { useQuery } from '@tanstack/react-query';

function UserList() {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['users'],
    queryFn: () => fetch('/api/users').then(r => r.json()),
    staleTime: 5 * 60_000, // fresh for 5 min
  });

  if (isLoading) return <Spinner />;
  if (error) return <Error onRetry={refetch} />;
  return <List items={data} />;
}
```

That's it. Free:
- Automatic refetch on window focus / network reconnect / interval.
- Stale-while-revalidate.
- Request deduplication (10 components asking for same data → 1 fetch).
- Optimistic updates.
- Pagination, infinite scroll, mutations with cache invalidation.
- DevTools.

Redux + thunks doing the same thing is 5x the code and reinvents
the wheel.

## Client state — pick by complexity

### useState + useReducer (built-in)
For state local to one component or one subtree. Default. Never
reach for a library when this works.

### Context (built-in)
For state that propagates down a subtree. Theme, locale, current user.
**Pitfall**: context re-renders ALL consumers on any change. Don't
put rapidly-changing values in context (form input values, mouse
position).

### Zustand
For app-wide client state that needs to be readable/writable from
anywhere. Minimal API, ~3kb, no provider.

```tsx
import { create } from 'zustand';

const useCart = create((set) => ({
  items: [],
  add: (item) => set((s) => ({ items: [...s.items, item] })),
  remove: (id) => set((s) => ({ items: s.items.filter(i => i.id !== id) })),
}));

function CartBadge() {
  const count = useCart((s) => s.items.length); // selector → only re-renders when count changes
  return <span>{count}</span>;
}
```

### Jotai
Atomic state — fine-grained reactive primitives. Great for forms
or canvas-like apps where many small pieces of state interact.

### Redux Toolkit (RTK)
For very large apps where you want a strict architectural style.
RTK is the modern Redux — boilerplate is minimal. RTK Query is
their server-state lib (good).

### XState
For genuinely state-machine-shaped problems: wizards, multi-step
forms, complex feature flows. If your state has clear modes /
states with transitions between them, XState makes the FSM explicit.

## The decision tree

```
Do you fetch this from a server?
  ├─ YES → React Query / SWR. Don't think about it more.
  └─ NO → Is it local to one component?
            ├─ YES → useState
            └─ NO → Is it deeply shared / persisted?
                      ├─ NO → Lift state up, useState, pass down
                      └─ YES → Zustand (default) / Jotai (atoms) / RTK (large)
```

When in doubt, START LOCAL. Hoist only when actual coupling demands it.

## Forms — a special case

Don't manage form fields in a global store. The state library that
fits forms best is a form library: React Hook Form (most popular),
Formik, TanStack Form. They handle:
- Uncontrolled inputs (perf).
- Validation (zod / yup integration).
- Submission state.
- Field arrays, conditional fields.

Using Redux for "name input value" is the classic over-engineering.

## URL as state

The URL is also state. Filter values, current tab, modal-open
flags often belong in the URL — shareable, back-button-able, no
state-loss on refresh.

```tsx
// Use the router as state
const [searchParams, setSearchParams] = useSearchParams();
const filter = searchParams.get('filter') ?? 'all';
```

Tools: TanStack Router or Next.js searchParams API handle
type-safety. Don't sync URL → store → URL → store; just read the
URL.

## Persisting state (localStorage, IndexedDB)

For state that must survive a refresh (theme, draft notes,
unsubmitted forms):

```tsx
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

const useTheme = create(persist(
  (set) => ({ theme: 'light', toggle: () => set(s => ({ theme: s.theme === 'light' ? 'dark' : 'light' })) }),
  { name: 'theme' }
));
```

Rules:
- Never persist server-cache data; let the query lib do it
  (`persistQueryClient`).
- Never persist secrets, tokens, PII in localStorage.
- Bound the size; localStorage is 5-10MB.

## Anti-patterns

- **Redux for server state.** You're building a worse React Query.
- **Context for high-frequency values.** Mouse position, form
  input. Re-renders every consumer.
- **Global state by default.** Most state is local. Lift only
  when shared.
- **Prop drilling 8 levels.** That's a smell that something needs
  to be lifted OR a context boundary belongs there.
- **Two libs for the same kind of state.** Pick ONE for server,
  ONE for client. Mixing Zustand + Redux + Jotai in the same app
  is choice fatigue.
- **Storing derived values.** `total = items.length * price` is a
  computation, not state. Re-derive each render or memoize.
- **No selector functions.** Components that subscribe to the
  WHOLE store re-render on any change. Always select narrowly.

## Performance — selectors and memoization

```tsx
// bad — re-renders on ANY store change
const state = useCart();
return <div>{state.items.length}</div>;

// good — re-renders only when length changes
const count = useCart((s) => s.items.length);
return <div>{count}</div>;
```

For complex derived state, use `shallow` equality from Zustand or
`useMemo` to memoize the projection.

## Migration when state has sprawled

Don't rewrite. Migrate incrementally:

1. Identify the worst pain (usually: a manual fetch + loading +
   error in Redux that everyone hates).
2. Add React Query for ONE endpoint. Coexist with Redux.
3. Migrate other endpoints over weeks, one at a time.
4. Once server state is out of Redux, evaluate what's left. If
   it's small, swap Redux for Zustand. If it's still complex, keep
   RTK.

Big-bang state lib migrations break things you didn't expect.

## Validation that state is well-managed

- [ ] Server state lives in a query library, not a manual reducer.
- [ ] Mutations invalidate the right cache keys; no manual refetch
      everywhere.
- [ ] No component subscribes to the WHOLE store — selectors are used.
- [ ] Form state lives in a form library.
- [ ] URL state is the URL's job; not duplicated in a store.
- [ ] Devtools can show every state change with the action that
      caused it.
- [ ] New engineer can locate "where does X live?" in < 5 minutes.
