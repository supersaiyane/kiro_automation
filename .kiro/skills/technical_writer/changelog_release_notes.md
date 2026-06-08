---
id: changelog_release_notes
version: 1.0.0
owners: [technical_writer, product_manager]
tags: [changelog, release-notes, semver, communication, deprecation]
when_to_use: |
  Every release, every API change, every product update. Two
  audiences with two artifacts: changelog (engineers / integrators)
  and release notes (end users). Don't merge them.
inputs:
  - shipped_changes_in_window
outputs:
  - changelog_entry: machine-friendly, exhaustive, semver-tagged
  - release_notes: human-friendly, prioritized, outcome-framed
---

# Changelog vs Release Notes

## They're different documents

| | Changelog | Release Notes |
|---|---|---|
| **Audience** | Developers, integrators, SREs | End users, customers, sales, support |
| **Tone** | Factual, terse | Warm, outcome-focused |
| **Format** | One bullet per change, tagged | Narrative + screenshots |
| **Order** | Reverse chronological by version | Highlights first, full list below |
| **Linked from** | Docs, API reference, GitHub releases | Blog, in-product banner, email |
| **Update frequency** | Every release | Major releases (weekly / monthly) |

You need **both**. A changelog that reads like marketing is useless to
integrators. Release notes that read like a git log are useless to
customers.

## Changelog format — Keep a Changelog convention

```
# Changelog

All notable changes to this project are documented here.
Format: Keep a Changelog (https://keepachangelog.com/).
Versioning: Semantic Versioning (https://semver.org/).

## [Unreleased]

## [2.4.0] — 2026-01-15

### Added
- `POST /v1/orders/:id/refund` endpoint for partial refunds (#1234)
- Webhook event `order.refunded` with the refund payload (#1234)
- `currency` parameter on order creation (defaults to account currency) (#1289)

### Changed
- Increase default pagination limit from 10 to 25 on `GET /v1/orders` (#1305)
- Rate-limit `POST /v1/orders` to 100/min per token (was 200/min) (#1290)

### Deprecated
- `amount` field on order response — use `total_cents` instead.
  Removal scheduled for v3.0.0 (2026-07-15).

### Removed
- Legacy `POST /v0/orders` endpoint (deprecated since v1.0.0, 2024-06-01)

### Fixed
- Idempotency key with whitespace was silently truncated (#1322)
- Order webhook delivery retried indefinitely on 4xx (now stops at 24h) (#1308)

### Security
- CVE-2026-1234: SSRF in `POST /v1/orders` via the `webhook_url` field.
  Patched; no exploitation observed. (#1330)
```

Six categories — Added, Changed, Deprecated, Removed, Fixed, Security.
Don't add more.

## Semver — what the version number commits you to

Given `MAJOR.MINOR.PATCH`:
- **MAJOR** — breaking changes (removed endpoint, changed contract,
  required new field). Plan + announce, never surprise.
- **MINOR** — additive features, backward compatible.
- **PATCH** — bug fixes, no behavior change for correct users.

For APIs with a date-based version pin (`API-Version: 2026-01-15`),
the same discipline applies: break only on a new date pin.

## Deprecation policy (write it down)

```
DEPRECATION POLICY

When a field, endpoint, or behavior is deprecated:
1. Annotated in the API response with a `Deprecation` header.
2. Documented in the changelog under "Deprecated."
3. Email + in-app announcement to integrators using it (we know who
   from access logs).
4. Minimum 6 months between deprecation and removal for SaaS APIs;
   12 months for installed software.
5. Final 30 days: HTTP 410 Gone returned periodically (10% of requests)
   to confirm clients have migrated.
6. Removal: tracked in the changelog as a MAJOR version bump.

We will NOT remove without all five steps.
```

The point isn't bureaucracy — it's that integrators can plan. An
unannounced removal is a service outage from their perspective.

## Release notes — the human version

```
# January 2026 Release Notes

## What's new

### Partial refunds, finally
You can now issue partial refunds on any order. We've heard from
hundreds of customers that all-or-nothing refunds didn't match how
their support team operates. **Try it in the dashboard** → click any
order → click "Refund a portion."

[screenshot]

### Webhooks for refunds
If you integrate with our API, refunds now fire an
`order.refunded` webhook. [Developer docs →](link)

## Improvements
- Order list pages now show 25 orders by default (was 10).
- We doubled email delivery speed for receipts and notifications.

## Bug fixes
- Fixed a rare crash on iPhone 12 when opening the order detail page.
- Order webhook delivery now stops retrying after 24h.

## Looking ahead
We're working on **multi-currency support** for the dashboard. If
you'd like early access, [join the beta](link).
```

Rules:
- **One outcome-framed headline per major change.** Don't lead with
  the technical name.
- **Screenshots / GIFs for UI changes.** Words alone leave readers
  guessing.
- **Bug fixes briefly.** Customers don't need the JIRA-id detail; they
  need to know it's fixed.
- **"Looking ahead" closes warmly.** Builds anticipation, gives
  trust.

## Anti-patterns

- A changelog that reads "Misc improvements and bug fixes." No-info
  entry; train customers that the changelog is worthless.
- Release notes that brag about implementation ("Rewrote the order
  engine in Rust"). Unless that's the product, customers don't care.
- "We've improved performance." By how much? Where? When? Specifics
  build credibility.
- Mixing security advisories with feature highlights. Securities go
  in their own page + email; not buried in the marketing copy.
- Removing a deprecated thing without the deprecation steps. The
  email you'll get from a $200K customer was avoidable.
- Skipping a release because "it's just a patch." Patches deserve a
  changelog entry — they're how you signal that the platform is alive
  and being maintained.
- A changelog that's not chronological. Readers can't tell what's new.
- One mega-document for both audiences. Either the engineers won't
  read it (too marketing) or the customers won't (too technical).
