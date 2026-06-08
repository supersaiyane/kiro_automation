# ADR Index

| ADR | Title | Date | Status | Decision |
|-----|-------|------|--------|----------|
| ADR-001 | Mode selection must be explicit and first | 2026-06-06 | Accepted | Always present mode options (1-4) before any pipeline runs; lock for session |
| ADR-002 | Flutter 3.24 + Dart 3.5 for cross-platform | 2026-06-06 | Accepted | Single codebase for iOS+Android+Web; Skia rendering for math; <5% platform-specific code |
| ADR-003 | Supabase over Firebase for backend | 2026-06-06 | Accepted | OSS Postgres, no vendor lock-in, predictable pricing, RLS for multi-tenant sync |
| ADR-004 | Build custom math engine in-house | 2026-06-06 | Accepted | Core differentiator; no vendor provides natural input + arbitrary precision + programmer mode + offline |
| ADR-005 | Isar 4.0 for local storage | 2026-06-06 | Accepted | Native Dart, zero-copy reads, 200μs queries, automatic object mapping for Flutter |
| ADR-006 | RevenueCat for subscription management | 2026-06-06 | Accepted | Handles IAP receipt validation; 1% fee vs $200K custom build; not a differentiator |
| ADR-007 | Pratt parser for expression parsing | 2026-06-06 | Accepted | O(n) parsing, trivial operator extension, rich AST for step generation |
| ADR-008 | LWW with vector clocks for sync | 2026-06-06 | Accepted | Simple, deterministic, no server merge logic; acceptable for append-mostly data |
| ADR-009 | Isar 4.0 over SQLite for local DB | 2026-06-06 | Accepted | Native Dart, zero-copy, built-in FTS, cross-platform from single codebase |
| ADR-010 | Isolate-based computation | 2026-06-06 | Accepted | Non-blocking UI guaranteed; warm pool eliminates spawn latency |
| ADR-011 | PBKDF2 client-side encryption | 2026-06-06 | Accepted | Zero-knowledge sync; pure Dart; no platform dependencies for key derivation |
| ADR-012 | Discovery-first routing before mode selection | 2026-06-06 | Accepted | 7 scoping questions determine complexity score (0-21); score maps to tier + agent subset; prevents overkill |
| ADR-013 | Adopt 5 SOTA discipline patterns (AtomMem, Adaptive Pruning, Continuous Eviction, Acon, Agent Isolation) | 2026-06-06 | Accepted | Memory writes gated by relevance; pruning by task-relevance not time; evict every 10 exchanges; learn from compression failures; subagents get <2000 token summaries only |
| ADR-014 | Testing + discipline reports mandatory in ALL modes (including Mode 3) | 2026-06-06 | Accepted | No code ships without tests; Mode 3 gets inline test+burn report; build incomplete without passing tests |
