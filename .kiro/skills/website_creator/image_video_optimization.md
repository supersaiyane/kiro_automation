---
id: image_video_optimization
version: 1.0.0
owners: [website_creator, frontend_lead]
tags: [images, video, avif, webp, lcp, lazy-loading, responsive-images]
when_to_use: |
  Any web page heavier than 500KB. Images and video are the #1 cause of
  slow load times. Modern formats + responsive sizing + lazy loading
  can cut weight 70-90% without quality loss.
inputs:
  - asset_inventory, target_devices, performance_budget
outputs:
  - "media_strategy: formats + responsive variants + lazy + CDN + delivery"
---

# Image + Video Optimization

> A 4MB hero image is what kills your Core Web Vitals. The fix isn't
> always smaller dimensions — it's the right FORMAT, the right
> RESOLUTION per device, and lazy-loading everything below the fold.

## The 2026 image format hierarchy

| Format | Use | Browser support |
|---|---|---|
| **AVIF** | Default for photos | Universal (Chrome 85+, Safari 16.4+, Firefox 113+) |
| **WebP** | Fallback for photos | Universal since 2020 |
| **JPEG** | Final fallback | Everything |
| **PNG** | Logos, UI with transparency | Everything |
| **SVG** | Logos, icons, illustrations | Everything |

Modern stack: serve AVIF, fall back to WebP, fall back to JPEG via
`<picture>`:

```html
<picture>
  <source srcset="hero.avif" type="image/avif">
  <source srcset="hero.webp" type="image/webp">
  <img src="hero.jpg" alt="..." width="1920" height="1080">
</picture>
```

AVIF averages **50% smaller than WebP, 70% smaller than JPEG** at equivalent
quality.

## Responsive images via srcset + sizes

```html
<img
  src="photo-800.jpg"
  srcset="photo-400.jpg 400w,
          photo-800.jpg 800w,
          photo-1200.jpg 1200w,
          photo-1600.jpg 1600w"
  sizes="(max-width: 768px) 100vw, 50vw"
  alt="..."
  width="800"
  height="600"
  loading="lazy"
  decoding="async">
```

The browser picks the right size based on viewport + device pixel ratio.
Saves 60-80% on mobile.

Generate variants at build time. Tools:
- **Sharp** (Node) — programmatic resizing + format conversion.
- **ImageMagick / Squoosh CLI** — batch.
- **Cloudflare Images / imgix / Cloudinary** — on-demand transformation.

For SSG (Astro, Next, 11ty): built-in image components handle this.

## Art direction — different crops per viewport

```html
<picture>
  <!-- Mobile: vertical crop -->
  <source media="(max-width: 768px)"
    srcset="hero-portrait.avif"
    type="image/avif">
  <!-- Desktop: wide crop -->
  <source srcset="hero-landscape.avif"
    type="image/avif">
  <img src="hero-landscape.jpg" alt="...">
</picture>
```

Don't just shrink — crop intentionally for the form factor.

## LCP optimization

The Largest Contentful Paint image:
- **Don't lazy load it.** `loading="eager"` (default).
- **Preload it** in `<head>`: `<link rel="preload" as="image" href="hero.avif" type="image/avif">`.
- **fetchpriority="high"** on the `<img>`.
- **Embed dimensions** to avoid CLS.
- **AVIF if possible.**
- **Use CDN cache** — served from the edge.

## Lazy loading below the fold

```html
<img src="..." loading="lazy" decoding="async" alt="...">
```

Native lazy loading works in all major browsers. Browser uses heuristics
(viewport-based) to start loading just before the user reaches it.

For background images (CSS) — use `loading="lazy"` doesn't apply. Defer
via JS + intersection observer OR use `<img>` instead with positioning.

## Decoding hints

```html
<img src="..." decoding="async" alt="...">
```

`async` lets browser decode off the main thread; reduces jank during
scroll for image-heavy pages.

## Width + height = no CLS

```html
<img src="..." width="1920" height="1080" alt="...">
```

ALWAYS set explicit `width` + `height` attributes. Browser reserves space
before the image loads → no layout shift.

For unknown aspect ratios: `aspect-ratio` CSS:

```css
img { aspect-ratio: 16 / 9; width: 100%; height: auto; }
```

## Background images — when not to use them

- **Decorative**: fine with CSS `background-image`.
- **Content**: ALWAYS use `<img>` with `alt`.
- **Hero / LCP**: prefer `<img>` for preload + priority hints.

## SVG best practices

```html
<!-- Inline SVG: stylable, accessible, no extra request -->
<svg width="24" height="24" viewBox="0 0 24 24" aria-hidden="true">
  <path d="..."/>
</svg>

<!-- SVG sprite for icon set -->
<svg><use href="/icons/sprite.svg#search"/></svg>
```

Optimize via SVGO (60-80% size reduction). Don't ship sketch / illustrator
exports raw — they have huge metadata.

For decorative SVGs: `aria-hidden="true"`. For meaningful: `role="img"` +
`<title>`.

## Video — the heavyweight

| Codec | Use | Notes |
|---|---|---|
| AV1 | Modern default | 30% smaller than H.265, ~50% than H.264 |
| H.265 (HEVC) | Apple ecosystem | Patent licensing complex |
| H.264 (AVC) | Universal fallback | Settle for it for compat |
| VP9 | YouTube / WebM | Free, good codec |

Container: MP4 (H.264 / AV1) for max compatibility, WebM (VP9 / AV1) for
modern. Stream via HLS (adaptive bitrate) for long videos.

```html
<video autoplay muted loop playsinline preload="metadata"
       width="1920" height="1080" poster="hero-poster.avif">
  <source src="hero.av1.mp4" type="video/mp4; codecs=av01.0.05M.08">
  <source src="hero.h264.mp4" type="video/mp4">
  <!-- Fallback image -->
  <img src="hero-poster.avif" alt="...">
</video>
```

Critical attrs:
- `muted` — required for autoplay.
- `playsinline` — iOS won't fullscreen autoplay.
- `loop` — looping hero.
- `preload="metadata"` — load dimensions, not bytes.
- `poster` — image while video loads.
- Provide a SHORT loop (5-15s) for hero — long videos kill UX + bandwidth.

## HLS for long-form

For tutorials, demos, anything > 30 seconds:

```html
<video controls>
  <source src="video.m3u8" type="application/vnd.apple.mpegurl">
</video>
```

HLS streams adaptive bitrate (ABR) — quality matches connection.
Cloudflare Stream, Mux, AWS MediaConvert handle this.

## CDN delivery

Serve all media from a CDN:
- Edge caching = fast everywhere.
- Bandwidth costs lower than origin egress.
- Transform-on-demand (resize, format) via image services.

Default options:
- **Cloudflare** (R2 + Images) — free tier, simple.
- **Vercel / Netlify** — built-in if hosted there.
- **AWS CloudFront + S3** — flexible, more setup.
- **imgix / Cloudinary** — image-specific, powerful transforms.

## GIFs — replace with video

GIFs are 5-10× larger than equivalent MP4 / WebM. Replace `<img src="*.gif">`
with autoplay muted video:

```html
<video autoplay muted loop playsinline class="gif-replacement">
  <source src="anim.av1.mp4" type="video/mp4">
</video>
```

A 2MB GIF becomes a 200KB MP4. Quick win.

## Performance budget

Set per page type:

| Page type | Total weight | Image weight | Time-to-LCP |
|---|---|---|---|
| Marketing home | ≤ 1 MB | ≤ 500 KB | ≤ 2.5 s |
| Marketing inner | ≤ 600 KB | ≤ 300 KB | ≤ 2.0 s |
| Pricing | ≤ 400 KB | ≤ 100 KB | ≤ 1.5 s |
| Blog post | ≤ 800 KB (text-heavy ok) | ≤ 400 KB | ≤ 2.5 s |
| Landing page (paid traffic) | ≤ 500 KB | ≤ 250 KB | ≤ 1.5 s |

Track via Lighthouse + WebPageTest + RUM (Cloudflare RUM, Vercel Analytics,
SpeedCurve).

## Anti-patterns

- **Raw 4K hero from designer's Figma export.** Resize and convert.
- **Same image at every viewport.** No `srcset`.
- **No width/height** → CLS on every load.
- **Lazy loading the LCP image.** Defeats fastest-paint goal.
- **Inline SVG with embedded JPG.** Defeats SVG's value.
- **AutoplayING heavy video on mobile.** Bandwidth + battery vampire.
- **GIFs for hero animation.** Use MP4.
- **CDN bypass for image transformations.** Doing them per request kills
  origin.
- **No image budget**. Page grows over years; performance silently
  regresses.

## Validation

- [ ] LCP < 2.5s on mobile RUM.
- [ ] CLS < 0.1.
- [ ] All images served as AVIF / WebP with JPEG fallback.
- [ ] Every `<img>` has width + height + alt.
- [ ] LCP image preloaded + fetchpriority="high".
- [ ] Lazy loading on below-the-fold images.
- [ ] Video autoplay muted + playsinline + poster set.
- [ ] CDN serves all media.
- [ ] Performance budget enforced in CI (Lighthouse CI).
