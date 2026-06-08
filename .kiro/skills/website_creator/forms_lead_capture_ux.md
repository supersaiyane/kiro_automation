---
id: forms_lead_capture_ux
version: 1.0.0
owners: [website_creator, designer, product_manager]
tags: [forms, lead-capture, ux, validation, conversion, autocomplete]
when_to_use: |
  Designing or auditing any form on a marketing site — signup, contact,
  demo request, newsletter. Forms are the #1 conversion killer: every
  field costs 5-10% completion rate. Get the design right.
inputs:
  - lead_data_needs, target_completion_rate, downstream_workflow
outputs:
  - "form_design: field selection + flow + validation + post-submit + a11y"
---

# Forms + Lead Capture UX

> Every form is a tax on conversion. The fewer fields, the higher the
> rate. Senior craft: ask only what you need NOW, get the rest later.

## Reduce fields ruthlessly

Pre-form check: for EVERY field, ask "why do we need this AT SIGNUP, not
in onboarding or a profile completion later?"

Typical signup → drop to email + password (or magic link):

```
BAD (8 fields, 4% conversion):
  First name, Last name, Email, Password, Company, Title,
  Phone, Source (how did you hear about us)

GOOD (2 fields, 14% conversion):
  Email
  Password (or 'Send magic link')
  → ask the rest in onboarding
```

Industry data: every extra field cuts completion 5-10%.

## Email-only / magic link signup

Modern pattern (Slack, Linear, Notion):

```
[Email                                    ]
[Continue with email]
─── or ───
[Continue with Google]   [Continue with GitHub]   [SAML/SSO]
```

Server sends magic link → user clicks → logged in. Eliminates password
problem entirely. Pair with OAuth + SSO for power users.

## Single-column layout

| Layout | Completion rate (industry) |
|---|---|
| Single column | Highest |
| Two columns | 15-25% lower |
| Multi-page wizard | Higher than long single page IF clearly progressing |
| Modal mid-page | Lower (interruption) |

Default: single column. Use multi-page only when truly long (10+ fields)
with progress indicator.

## Field types — the boring details that matter

```html
<!-- Email -->
<input type="email"
       name="email"
       autocomplete="email"
       inputmode="email"
       required
       placeholder="you@company.com">

<!-- Phone -->
<input type="tel"
       name="phone"
       autocomplete="tel"
       inputmode="tel"
       pattern="[0-9-+() ]{10,}">

<!-- Company -->
<input type="text"
       name="company"
       autocomplete="organization">

<!-- Title -->
<input type="text"
       name="title"
       autocomplete="organization-title">

<!-- Numeric -->
<input type="text"
       inputmode="numeric"
       pattern="[0-9]*">
```

Critical attributes:
- `type` matches data (`email`, `tel`, `url`, `date`).
- `autocomplete` uses standard tokens (mdn list).
- `inputmode` selects mobile keyboard.
- `pattern` validates client-side.
- `required` for must-have.

These reduce friction on mobile dramatically (right keyboard = faster
input).

## Labels — visible, not placeholder

```html
<!-- BAD: placeholder as label -->
<input type="email" placeholder="Email">

<!-- BAD: invisible label "for screen readers only" -->
<label for="email" class="sr-only">Email</label>
<input id="email" placeholder="Email">

<!-- GOOD: visible label above input -->
<label for="email" class="text-sm font-medium">Email address</label>
<input id="email" type="email" placeholder="you@company.com">

<!-- GOOD: floating label (animates up on focus) -->
<div class="relative">
  <input id="email" type="email" placeholder=" "
         class="peer pt-5 pb-1 ...">
  <label for="email" class="absolute top-0 left-3 text-xs
         peer-placeholder-shown:top-3 peer-placeholder-shown:text-base
         peer-focus:top-0 peer-focus:text-xs transition-all">
    Email address
  </label>
</div>
```

Placeholder as label is a usability anti-pattern (disappears on focus,
hard for screen readers). Always provide a visible label.

## Inline validation

Validate AS the user types (or on blur), not just on submit.

```js
input.addEventListener('blur', () => {
  if (!input.checkValidity()) {
    showError(input, getErrorMessage(input));
  } else {
    showSuccess(input);
  }
});
```

Show:
- ❌ icon + helpful message for error.
- ✓ icon for valid filled fields.
- Helpful TEXT, not just "Invalid email."

```
"someone@" → "Please enter the rest of your email."
"someone@gmail.con" → "Did you mean gmail.com?"
```

Don't validate too aggressively — single keystroke validation feels
adversarial. Validate on blur or after a short pause.

## Required vs optional markers

For mostly-required forms: mark OPTIONAL fields:

```
Email *
Password *
Company (optional)
Phone (optional)
```

For mostly-optional forms: mark REQUIRED:

```
First name *
Last name *
Bio
Avatar
```

DON'T use red asterisks alone — accessibility issue. Include text or
`aria-required`.

## Submit button copy

```
BAD: "Submit"  /  "Send"  /  "Click here"
GOOD: "Start free trial"  /  "Book demo"  /  "Get the guide"
```

Match the EXPECTATION of what happens. "Submit" is software-speak.

While submitting:

```
[● Sending…]   ← spinner, disabled state, same text
```

NEVER:
- Disable button on form-incomplete (frustrating; tell them what's
  missing).
- Hide button until form valid.
- Submit on Enter for non-form contexts.

## Post-submit experience

Three patterns:
1. **Redirect to thank-you page**: enables conversion tracking,
   server-side render. Best for marketing.
2. **Inline success message**: faster perceived speed. Best for in-app.
3. **Modal confirmation**: nice for downloads (link in modal).

Always:
- Acknowledge success VISUALLY.
- State what happens next ("Check your inbox for a confirmation link").
- Provide a NEXT action (link to docs, schedule a call, follow on social).

Don't:
- Leave user staring at the form.
- Auto-redirect with no acknowledgment.
- Tell them the request is "being processed" with no follow-up.

## Error states

```
[Email: not_an_email           ]
❌ Please enter a valid email address.
```

Show errors:
- INLINE under the field, not at top of form.
- With both ICON + TEXT (icon-only fails for some assistive tech).
- SPECIFIC ("This email is already registered. Sign in?" not "Email
  invalid").
- WITH ACTION ("Sign in" link if email exists).

Don't lose user input on error. Validate, show error, keep the data.

## Multi-step forms (wizards)

```
Step 1 of 3                    [progress bar 33%]
Step 1: Tell us about you
[Email][Company]
[Continue →]
```

Rules:
- Show progress (step indicator + bar).
- Allow BACK navigation.
- Save progress (don't lose if user closes tab).
- Estimate time ("This takes 3 minutes").
- Don't shame ("Almost done!" — feels like the end of pain).

Better for many-field flows than single long form. Conversion data
typically higher.

## Spam + bot mitigation

Spam pixels + bot traffic submit forms heavily. Mitigations:

| Tool | UX impact | Effectiveness |
|---|---|---|
| **Cloudflare Turnstile** | Invisible most of the time | Excellent |
| **hCaptcha** | Visible challenge | Excellent + privacy-friendly |
| **reCAPTCHA v3** | Invisible | Good but Google data flow |
| **Honeypot** (hidden field) | Zero UX | Decent against simple bots |
| **Email verification** | High UX cost | Excellent |
| **Rate limit by IP** | Zero UX | Decent |

Default: Cloudflare Turnstile + honeypot field. Add CAPTCHA only if seeing
real spam.

## Downstream — where does the lead go?

Form → ???:

```
1. POST to your backend
2. Backend validates
3. Insert into CRM (HubSpot, Salesforce, Pipedrive)
4. Insert into email tool (Mailchimp, Customer.io)
5. Trigger Slack alert (#sales channel)
6. Trigger webhook for downstream automation
7. Respond to user
```

Tools to glue:
- **Zapier / Make** (low-code automation).
- **Segment** (event-stream to multiple destinations).
- **Direct CRM webhook** (HubSpot's free form API is excellent).

Always:
- Log every submission (audit + retry queue).
- Retry failed downstream calls.
- Don't make the user wait for ALL downstream — respond fast, process
  async.

## Newsletter / waitlist signup

```
Be the first to know
[Your email                       ] [Notify me]
```

Single field. Even less friction. Pair with progressive profiling
(later, ask "what industry are you in?").

Confirm via:
- Inline message ("You're on the list — we'll email when we launch").
- Double opt-in for GDPR / spam compliance.

## Anti-patterns

- **10+ fields on initial signup.** Cuts conversion 60-80%.
- **Placeholder as label.** Disappears on focus, a11y broken.
- **Validation on every keystroke.** Adversarial.
- **Lost input on error.** Make them re-type? Conversion killer.
- **"Submit" button copy.** Generic.
- **No success state.** User unsure if it worked.
- **No autocomplete attributes.** Frustrating on mobile.
- **CAPTCHA before user committed.** Show only on suspicion.
- **Required marker only via color.** A11y fail.
- **Form hidden behind modal that auto-pops in 5s.** Hostile.

## Validation

- [ ] Form has minimum viable fields (typically email + 1-2 others).
- [ ] Single-column layout (unless multi-step).
- [ ] Labels visible above each input.
- [ ] autocomplete + inputmode on every input.
- [ ] Inline validation on blur (not every keystroke).
- [ ] Submit button has outcome-led copy + loading state.
- [ ] Success state acknowledges + next action.
- [ ] Errors specific + actionable + inline.
- [ ] Bot protection (Turnstile + honeypot).
- [ ] CRM + email-tool integrated.
- [ ] Mobile completion rate > 5%.
