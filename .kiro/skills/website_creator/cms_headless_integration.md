---
id: cms_headless_integration
version: 1.0.0
owners: [website_creator, frontend_lead]
tags: [cms, headless, contentful, sanity, strapi, storyblok, mdx]
when_to_use: |
  When marketing or content team needs to update site without engineering
  hand-offs. Headless CMS gives them a clean editor; engineers get clean
  API + structured content. Pick the right tool for the team's shape.
inputs:
  - content_volume, editor_count, technical_skill, budget, deploy_model
outputs:
  - "cms_choice: tool + content model + workflow + delivery + preview"
---

# Headless CMS Integration

> Marketing team that has to file a ticket for every typo will rage-quit.
> A good headless CMS gives them direct edit + preview + publish, while
> developers get a clean structured-content API for SSG / SSR.

## Tool landscape (2026)

| CMS | Sweet spot | Pricing |
|---|---|---|
| **Sanity** | Developer-friendly, real-time, customizable | Free tier + scale |
| **Contentful** | Enterprise-grade, ecosystem | $$ |
| **Strapi** | Open-source, self-hostable | Free + paid cloud |
| **Storyblok** | Visual editor, marketing-friendly | $$ |
| **Payload** | Open-source, TypeScript-first, self-host | Free + paid cloud |
| **Hygraph** (GraphCMS) | GraphQL-first | $$ |
| **DatoCMS** | Designer-friendly, visual | $$ |
| **WordPress (headless)** | Familiar editor, vast plugins | Self-host or WP Engine |
| **Markdown / MDX in git** | Best for dev-team-only sites | Free |
| **Notion as CMS** | Quick + dirty for small sites | Free / Notion plan |

Default for a developer-heavy + content-light B2B site: **Markdown/MDX in
git** (commits = changes; PRs = workflow).

Default for marketing-heavy + non-dev editors: **Sanity** or **Storyblok**.

For enterprise + complex roles: **Contentful** or **Strapi self-hosted**.

## Content model design

The biggest mistake: model content as one giant blob ("Page Content:
HTML"). Result: editors paste broken HTML; designers can't enforce design
system.

**Structured content** instead:

```
Page (singleton):
  - slug
  - SEO: title, description, og_image
  - sections[]:  (array of references)
      - Hero            → headline, subhead, cta_label, cta_url, image
      - LogoStrip       → label, logos[]
      - Features        → heading, features[]: {icon, title, body}
      - CaseStudy       → quote, attribution, metrics[], photo
      - PricingTiers    → tiers[]: {name, price, features[]}
      - FAQ             → questions[]: {q, a}
      - CTA             → headline, cta_label, cta_url
```

Each section TYPE is a separate model with TYPED fields. Editors PICK
sections from a menu, fill the fields. Designers control the appearance.

This is the "content blocks" pattern. Sanity / Contentful / Storyblok all
support it.

## Component-to-content mapping

Frontend has a React/Svelte/Astro component per section. CMS section type
↔ component:

```tsx
// React mapping
const SECTION_MAP = {
  hero:        HeroSection,
  logoStrip:   LogoStripSection,
  features:    FeaturesSection,
  caseStudy:   CaseStudySection,
  pricing:     PricingTiersSection,
  faq:         FAQSection,
  cta:         CTASection,
};

function Page({ sections }) {
  return sections.map((s, i) => {
    const Component = SECTION_MAP[s._type];
    return Component ? <Component key={i} {...s} /> : null;
  });
}
```

CMS adds new section type → frontend maps it → instant new layout
without code deploy (for component types you've already defined).

## Preview — non-negotiable for editors

Editor edits → expects to see changes BEFORE publishing.

Implementation:
- Authenticated preview URL: `https://example.com/api/preview?secret=...&slug=/blog/foo`.
- Preview endpoint reads from CMS DRAFT (not published) data.
- Sets a cookie / token enabling draft mode.
- Renders the page with unpublished content.

Frameworks:
- **Next.js**: Draft Mode (App Router) / preview mode (Pages Router).
- **Astro**: `Astro.cookies` + draft API.
- **Nuxt**: preview module.

Live preview (real-time as editor types): supported by Sanity's
Presentation, Storyblok's visual editor, Contentful's compose.

## Rich text — structured, not HTML

Don't store rich text as raw HTML. Store as STRUCTURED data:

```
Portable Text (Sanity):
  [
    { _type: 'block', children: [{ text: 'Hello world', marks: ['bold'] }] },
    { _type: 'image', asset: { _ref: 'image-...' } },
    { _type: 'codeBlock', language: 'js', code: '...' }
  ]
```

Then RENDER per platform — web with `<strong>`, native app with bold span,
PDF with bold weight.

ALL major headless CMSes support this (Portable Text, Rich Text Document
in Contentful, ProseMirror in Storyblok).

## Image handling via CMS

Editor uploads → CMS stores → CDN serves with transformations on demand:

```html
<img
  src="https://cdn.sanity.io/images/.../image.jpg?w=800&fm=webp&q=80"
  srcset="https://cdn.sanity.io/...?w=400 400w,
          https://cdn.sanity.io/...?w=800 800w,
          https://cdn.sanity.io/...?w=1200 1200w"
  sizes="(max-width: 768px) 100vw, 50vw"
  alt={image.alt}
  loading="lazy">
```

CMS auto-generates alt text via AI (Sanity, Contentful) but EDITOR
SHOULD REVIEW. Auto-alt is starting point, not output.

## Localization

Built-in localization:
- **Sanity**: language as a field per document or per-field locales.
- **Contentful**: locale-aware fields, fallback chains.
- **Storyblok**: spaces per locale or per-field localization.

Translation workflow:
- ENGINEERING: locale-aware routing (Next.js i18n, Astro i18n).
- CONTENT: writer interfaces ↔ translation memory tools (Lokalise, Phrase).
- FALLBACK: untranslated content shows EN with notice.

## Workflow + roles

Roles editors expect:
- **Author / Editor** — drafts content.
- **Reviewer / Approver** — checks before publish.
- **Publisher** — deploys to live.
- **Admin** — controls schema + roles.

Build into the CMS workflow (Sanity Workflow plugin, Contentful Workflows,
Strapi Review-Workflow).

## Triggering builds on publish

SSG: rebuild on every content publish.

Webhooks:
- CMS publishes → POST to deploy hook URL.
- Vercel / Netlify / Cloudflare Pages / GitHub Actions kicks build.
- Site live in 30s-2min.

For instant publish: ISR (Incremental Static Regeneration) — Next.js / Astro
can rebuild ONLY the changed pages on-demand.

## Content modeling pitfalls

1. **One "Page" model with a giant rich-text blob.** Loses structure.
2. **All sections in one document.** Editors can't reorder; no reuse.
3. **No "Author" model.** Bylines as strings instead of structured.
4. **Too granular** (every paragraph as its own document). Editor pain.
5. **No `seo` object** (title, description, og_image) per page. SEO gaps.
6. **No globals** for header / footer / nav. Duplicated content.

## Anti-patterns

- **Rich text as HTML in DB.** Locks rendering to one platform.
- **Editors editing raw markdown.** Some teams ok with it; most aren't.
- **No preview**. Editors publish blind → live mistakes.
- **No structured content**. Long forms with one giant text field.
- **No image transformations.** Original uploads served everywhere.
- **No build-on-publish.** Editors wait for next deploy.
- **Hard-coded copy** in code (need eng to change one word).
- **One person knows the schema.** Bus-factor risk.
- **CMS for everything.** Code/templates should still be in git.

## Validation

- [ ] Content model has typed sections, not one giant blob.
- [ ] Preview URL works for editors.
- [ ] Structured rich text (Portable Text or equivalent).
- [ ] Image transformations via CDN.
- [ ] Publish triggers build automatically.
- [ ] Locale + workflow roles wired if needed.
- [ ] Editors can ship a typo fix in < 5 minutes WITHOUT engineering.
- [ ] Schema documented; multiple editors comfortable.
