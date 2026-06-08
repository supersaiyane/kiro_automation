---
id: animation_choreography
version: 1.0.0
owners: [website_creator, designer, frontend_lead]
tags: [animation, motion-design, framer-motion, gsap, prefers-reduced-motion, easing]
when_to_use: |
  Building any marketing site, product landing page, or interactive
  hero. Animation done well = perceived quality, focus, delight.
  Animation done poorly = motion sickness, abandonment, accessibility
  failures. The discipline is restraint + intent.
inputs:
  - brand_personality, page_purpose, key_moments
outputs:
  - "motion_spec: choreography sheet + easing palette + duration tokens + reduced-motion fallback"
---

# Animation Choreography — Motion With Intent

> "Easing functions don't move things. They communicate WHY they
> moved." — Val Head. Animation is information design with time
> as a dimension. The default should be: a little, and only when
> it carries meaning.

## The five jobs of motion (Disney → web)

1. **Direct attention** — a subtle pulse on the CTA after content
   loads.
2. **Show causality** — clicking a card expands it from itself,
   not from a random corner.
3. **Indicate state** — a button transitioning into a checkmark
   says "saved."
4. **Imply hierarchy** — large elements move slower than small
   (per Material Design).
5. **Convey personality** — energetic bounce vs. understated fade.

If a motion isn't doing one of these, it's noise.

## The duration palette (Material 3 / IBM Carbon — adapt)

```
ultra-fast    100ms    micro-interactions (button press)
fast          150ms    in-page micro (focus, hover)
moderate      250ms    state changes (toggle, expand)
deliberate    400ms    page elements entering
expressive    600ms    hero / brand moments (rare)
```

A motion-duration system, like a color system. Tokens, not magic
numbers. Stay within a max of 5; more and the page feels chaotic.

## The easing palette

```
ease-standard      cubic-bezier(0.2, 0, 0, 1)        most UI transitions
ease-emphasized    cubic-bezier(0.2, 0, 0, 1.2)      attention-getter
ease-in            cubic-bezier(0.4, 0, 1, 1)        EXIT — element leaving
ease-out           cubic-bezier(0, 0, 0.2, 1)        ENTER — element arriving
linear             linear                            for spinners, progress
```

Rules:
- **Enter**: ease-OUT (starts fast, slows to land). Things arriving
  feel natural that way.
- **Exit**: ease-IN (starts slow, accelerates away). Things leaving
  feel natural that way.
- **In-place**: ease-standard.
- **Bounces / overshoots**: use sparingly. Almost never on text.

Never use linear except for indeterminate loaders. Real motion has
inertia; linear feels mechanical.

## prefers-reduced-motion — non-negotiable

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

About 35% of users have it on. Vestibular-disorder users get
nauseous from parallax and aggressive transforms. Accessibility
is law (ADA, EAA), not opinion.

For motion that's PART OF THE BRAND (the hero animation), provide
a STATIC alternative — a strong illustration, not a placeholder.

## Stagger choreography

Multiple elements entering at once = chaos. Stagger them by
50-100ms:

```tsx
<motion.div variants={container} initial="hidden" animate="visible">
  {items.map(item => (
    <motion.div key={item.id} variants={item} />
  ))}
</motion.div>

const container = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.06, delayChildren: 0.1 }
  }
};

const item = {
  hidden: { y: 16, opacity: 0 },
  visible: { y: 0, opacity: 1, transition: { duration: 0.4, ease: [0.2, 0, 0, 1] } }
};
```

Stagger creates a perceived "wave" instead of a wall of motion.
60ms is the sweet spot for ~5 items; tighten to 30ms for 20+.

## Scroll-driven animation (ScrollTrigger, GSAP, CSS view timeline)

```js
// GSAP ScrollTrigger
gsap.to('.feature-card', {
  y: 0, opacity: 1,
  scrollTrigger: {
    trigger: '.feature-card',
    start: 'top 80%',     // when card top hits 80% from viewport top
    toggleActions: 'play none none reverse',
  }
});
```

Rules:
- **Trigger ONCE on first reveal** by default. Repeated re-animation
  on every scroll-by is fatiguing.
- **Respect reduced-motion** — skip the animation entirely.
- **Avoid scroll-jacking** (hijacking the user's scroll speed).
  Almost always feels broken.
- **Performance**: prefer `transform` and `opacity` only.
  Animating `top`/`width` triggers layout and tanks frame rate.

CSS `@scroll-timeline` is now broadly supported and removes the JS
dependency for simple cases:

```css
.feature-card {
  animation: fade-up linear;
  animation-timeline: view();
  animation-range: entry 0% cover 30%;
}
@keyframes fade-up {
  from { opacity: 0; transform: translateY(16px); }
  to   { opacity: 1; transform: translateY(0); }
}
```

## The 60fps budget

Each frame has 16.67ms to render. To stay smooth:

- Animate `transform` and `opacity`. Both are compositor-only;
  no layout, no paint.
- AVOID animating: `width`, `height`, `top`, `left`, `margin`,
  `box-shadow`, `filter` (sometimes). These trigger layout/paint.
- `will-change: transform` for upcoming animations — but use
  sparingly; it costs memory.
- Use `transform: translate3d(0,0,0)` to force GPU compositing if
  needed.

If `requestAnimationFrame` callbacks consistently exceed 8-10ms,
the animation will drop frames on mid-range devices.

## Lottie / Rive / video

For complex character animations or branded motion: pre-rendered
formats win.

- **Lottie** — vector animation from AfterEffects. Small files,
  scalable. Watch out for outdated effects that don't translate.
- **Rive** — state-machine driven, interactive. Smaller runtime
  than Lottie. Better for stateful animations.
- **Video (mp4/webm)** — for photoreal, or anything > 200 frames.
  Always autoplay + muted + loop + playsinline; provide a poster.

Avoid GIFs. Worse compression than mp4, worse colors, larger
files. The web hasn't needed GIFs since 2015.

## Anti-patterns

- **Animation on EVERY element entry.** Page feels like it's
  buffering forever. Pick the 2-3 moments that matter.
- **Long durations (> 600ms) for UI feedback.** Feels broken;
  users tap again.
- **Parallax everywhere.** Tasteful in 2014; tired in 2026. One
  parallax moment, used precisely, is enough.
- **Skipping reduced-motion fallbacks.** Inaccessible AND illegal
  in many jurisdictions.
- **Animating box-shadow.** Eats frame budget. Use opacity on a
  pre-blurred pseudo-element instead.
- **Different durations per component.** No system; feels arbitrary.
- **Continuous animation (loops in view).** Drains attention and
  battery. Use only as a brand element.
- **Animation timed to a specific browser/CPU.** Test on a budget
  Android phone.

## Choreography sheet (the artifact you produce)

| Moment | Element | Trigger | Duration | Easing | Stagger | Reduced motion |
|---|---|---|---|---|---|---|
| Page enter | Hero text | onMount | 400 | ease-out | — | static |
| Page enter | Hero CTA | +200ms | 300 | ease-out | — | static |
| Feature grid scroll | Card | viewport 80% | 400 | ease-out | 60ms | static |
| Modal open | Modal | onOpen | 250 | ease-emphasized | — | fade only |
| Form submit | Button → check | onSuccess | 300 | ease-standard | — | static checkmark |

This is the spec a frontend can implement against and a designer
can review.

## Validation that animation is intentional

- [ ] You have a duration token system; no inline magic numbers.
- [ ] You have an easing token palette; not every component picks
      its own.
- [ ] `prefers-reduced-motion` is honored everywhere; verified by
      simulating it in DevTools.
- [ ] No animation runs continuously without user-initiated trigger.
- [ ] First Contentful Paint is not delayed by hero animations.
- [ ] All animations stay above 50fps on a mid-range Android device.
- [ ] Removing every animation does not break any user task (motion
      is enhancement, not function).
