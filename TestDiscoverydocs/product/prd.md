# PRD: CalcApp — Cross-Platform Smart Calculator

**Version:** 1.0  
**Author:** Product Manager  
**Date:** 2025-01-15  
**Status:** Living Document  
**Upstream Dependencies:** Market Research Report, CTO Strategy Document

---

## 1. Problem

Students, professionals, and engineers perform calculations daily across multiple devices but lack a unified tool that:

- Preserves calculation history across sessions and devices
- Supports multiple mathematical domains (arithmetic, algebra, programmer math) in one app
- Works reliably offline while syncing when connectivity returns
- Shows step-by-step solutions for learning

Today's users bounce between 3-4 apps (phone calculator, spreadsheet, programmer calc, graphing tool), losing context and history each time. Students cannot review their work. Professionals lose calculations mid-meeting. Engineers constantly switch between hex/dec/bin converters.

---

## 2. Target Users

### Student (Sarah) — Phase 1, Growth Segment
- 18-25, university STEM major
- Performs 20-50 calculations daily for homework/labs
- Wants to see HOW answers are derived, not just results
- Frustrated by: losing work, no history, needing multiple apps
- Tech comfort: high (mobile-native), budget: zero

### Professional (Marcus) — Phase 2, Revenue Segment
- 28-45, finance/sales/consulting role
- Quick arithmetic during calls and meetings, needs instant recall
- Wants: history search, unit conversions, tip/split calculations
- Frustrated by: can't find "that number from Tuesday's call"
- Tech comfort: moderate, willing to pay $2.99/mo for productivity

### Engineer (Priya) — Phase 3, Premium Segment
- 25-40, software developer / embedded engineer
- Needs hex/binary/octal simultaneously, bitwise operations
- Wants: multi-base live view, bit manipulation, register visualization
- Frustrated by: separate tools for each base, no persistent workspace
- Tech comfort: expert, willing to pay $4.99/mo for specialized tools

---

## 3. Vision

One calculator that grows with you — from learning algebra to shipping firmware — with every calculation remembered and available everywhere.

---

## 4. Product Goals (Outcome-Shaped)

| # | Goal | Measurable Outcome | Phase |
|---|------|--------------------|-------|
| G1 | Students can trace mathematical reasoning to improve comprehension | 70% of students report improved understanding in post-use survey; avg session length >5min | Phase 1 |
| G2 | All users retain and retrieve past calculations without manual note-taking | 80% of returning users access history at least 1x/week; search-to-result <3s | Phase 1-2 |
| G3 | Professionals complete numeric tasks without leaving their workflow | Time-to-answer <5s for common calculations; 60% DAU/MAU ratio | Phase 2 |
| G4 | Engineers evaluate multi-base expressions without switching tools | 90% of programmer-mode sessions use simultaneous base view; NPS >50 | Phase 3 |
| G5 | Users trust their data persists across devices and sessions | Sync conflict rate <0.1%; zero data loss incidents per quarter | Phase 2-3 |

---

## 5. User Stories


### Phase 1 — Student Foundation (Free Tier)

---

#### US-001: Natural Math Expression Input
**As a** Student, **I want** to type expressions using natural notation (fractions, exponents, square roots), **so that** I can input problems as they appear in my textbook without learning special syntax.

**Story Points:** 5  
**Priority:** P1  
**Phase:** 1

**Acceptance Criteria:**

```gherkin
Given the user is on the standard calculator screen
When they type "sqrt(144)"
Then the display renders √144 with the result 12 shown within 50ms of expression completion

Given the user types "2^10"
When the expression is evaluated
Then the display shows 2¹⁰ = 1024 with proper superscript rendering

Given the user types an incomplete expression "3 + (2 *"
When they press evaluate
Then an inline error highlights the unclosed parenthesis at position 8
And no crash or unexpected behavior occurs

Given the user types an expression exceeding 200 characters
When they attempt to add the 201st character
Then input is blocked and a "max length reached" indicator appears
And the existing expression remains unmodified
```

---

#### US-002: Step-by-Step Solution Display
**As a** Student, **I want** to see each intermediate step of a calculation's evaluation, **so that** I can understand the mathematical process and learn from it.

**Story Points:** 8  
**Priority:** P1  
**Phase:** 1

**Acceptance Criteria:**

```gherkin
Given the user enters the expression "(3 + 5) * 2 - 4 / 2"
When they tap the "Show Steps" button
Then the display shows each evaluation step in order:
  | Step | Expression       | Result |
  | 1    | (3 + 5)          | 8      |
  | 2    | 8 * 2            | 16     |
  | 3    | 4 / 2            | 2      |
  | 4    | 16 - 2           | 14     |
And total render time for all steps is under 200ms

Given the user enters a simple expression "5 + 3"
When they tap "Show Steps"
Then a single step is shown (no unnecessary decomposition)

Given the user enters an expression resulting in a division by zero at step 3
When "Show Steps" is activated
Then steps 1-2 render normally
And step 3 shows "undefined — division by zero" with the problematic sub-expression highlighted

Given the user enters an expression with nested functions "sin(cos(pi/4))"
When they tap "Show Steps"
Then inner functions evaluate first (cos(π/4) = 0.7071...)
And outer function evaluates on the result (sin(0.7071...) = 0.6496...)
```

---

#### US-003: Calculation History (Local)
**As a** Student, **I want** my calculations saved automatically on my device, **so that** I can review my work from earlier study sessions without re-entering expressions.

**Story Points:** 5  
**Priority:** P1  
**Phase:** 1

**Acceptance Criteria:**

```gherkin
Given the user completes a calculation
When the result displays
Then the expression and result are persisted to local storage within 100ms
And appear at the top of the history list

Given the user has 500 history entries
When they open the history panel
Then the list renders within 300ms showing the 20 most recent entries
And supports infinite scroll loading 20 more per page

Given the user force-kills the app mid-calculation
When they reopen the app
Then the last completed calculation is in history
And any in-progress expression is restored in the input field

Given the device storage is full (< 5MB remaining)
When a new calculation completes
Then the oldest 100 history entries are archived to compressed storage
And the user sees a "storage optimized" notification
```

---

#### US-004: Basic Arithmetic with Operator Precedence
**As a** Student, **I want** the calculator to correctly handle order of operations (PEMDAS/BODMAS), **so that** I get mathematically correct results without manual parenthesization.

**Story Points:** 3  
**Priority:** P1  
**Phase:** 1

**Acceptance Criteria:**

```gherkin
Given the user enters "2 + 3 * 4"
When the expression evaluates
Then the result is 14 (not 20)
And computation completes in under 50ms

Given the user enters "10 / 2 + 3"
When the expression evaluates
Then the result is 8 (division before addition)

Given the user enters a chain of 50 operators "1+1+1+...+1"
When the expression evaluates
Then the result is 51 and completes within 50ms

Given the user enters "0.1 + 0.2"
When the expression evaluates
Then the result displays as 0.3 (not 0.30000000000000004)
And floating-point precision is handled to 15 significant digits
```

---

#### US-005: Scientific Functions
**As a** Student, **I want** access to trigonometric, logarithmic, and exponential functions, **so that** I can solve STEM homework problems in one app.

**Story Points:** 5  
**Priority:** P1  
**Phase:** 1

**Acceptance Criteria:**

```gherkin
Given the user is in scientific mode
When they enter "sin(90)" with angle mode set to degrees
Then the result is 1

Given the user switches angle mode from degrees to radians
When they enter "sin(pi/2)"
Then the result is 1

Given the user enters "log(-1)"
When the expression evaluates
Then the result shows "undefined for real numbers"
And a tooltip suggests "Switch to complex mode for imaginary results"

Given the user enters "factorial(170)"
When the expression evaluates
Then the result displays in scientific notation (7.257... × 10³⁰⁶)
And "factorial(171)" shows "overflow — exceeds max representable value"
```

---

#### US-006: Offline-First Operation
**As a** Student, **I want** all calculator functions to work without internet connectivity, **so that** I can use the app during exams, commutes, or in areas with poor signal.

**Story Points:** 3  
**Priority:** P1  
**Phase:** 1

**Acceptance Criteria:**

```gherkin
Given the device has no network connectivity
When the user performs any calculation available in their tier
Then the calculation completes with identical results as online mode
And no error messages related to connectivity are shown

Given the device transitions from online to airplane mode mid-session
When the user continues working
Then there is zero interruption to input or calculation
And a subtle offline indicator appears in the status area

Given the user has been offline for 30 days
When they reopen the app
Then all local data and functionality remain intact
And no "login required" or "sync needed" gates block usage

Given the device has no connectivity and the user attempts a sync-dependent action
When the action fails
Then the operation is queued silently
And executes automatically when connectivity returns (within 30s of reconnection)
```

---

### Phase 2 — Professional Productivity (Pro Tier — $2.99/mo)

---

#### US-007: Cross-Device Sync
**As a** Professional, **I want** my calculation history and favorites to sync across my phone, tablet, and desktop, **so that** I can start a calculation on one device and reference it on another.

**Story Points:** 8  
**Priority:** P2  
**Phase:** 2

**Acceptance Criteria:**

```gherkin
Given the user is logged in on Device A and Device B
When they complete a calculation on Device A
Then the calculation appears in Device B's history within 5 seconds (when both online)

Given Device A is offline when a calculation is performed
When Device A reconnects
Then the calculation syncs to Device B within 30 seconds of reconnection
And chronological order is preserved based on original creation timestamp

Given the user modifies the same history entry on two devices simultaneously while offline
When both devices reconnect
Then the conflict is resolved using last-write-wins with both versions preserved in a "conflict" drawer
And the user can choose which version to keep

Given the user has 10,000 history entries across devices
When initial sync occurs on a new device
Then only the most recent 500 entries sync immediately (< 10s)
And remaining entries sync in background within 5 minutes
```

---

#### US-008: History Search and Filtering
**As a** Professional, **I want** to search my calculation history by expression content, result, or date, **so that** I can find "that number from last Tuesday's meeting" in under 3 seconds.

**Story Points:** 5  
**Priority:** P2  
**Phase:** 2

**Acceptance Criteria:**

```gherkin
Given the user has 1,000+ history entries
When they type "425" in the search field
Then results matching expression OR result containing "425" appear within 500ms
And results are ordered by recency

Given the user applies a date filter for "last 7 days"
When combined with a search term
Then only entries from the past 7 days matching the term are shown
And the count of filtered results is displayed

Given the user searches for a term with zero matches
When the search completes
Then "No results" is shown with a suggestion: "Try broader terms or expand date range"
And the search field remains active for refinement

Given the user searches with special characters "2^10"
When the search executes
Then the caret is treated as literal text (not regex)
And entries containing "2^10" are returned correctly
```

---

#### US-009: Favorites and Pinned Calculations
**As a** Professional, **I want** to pin frequently-used calculations (tax rates, conversion formulas), **so that** I can reuse them with one tap instead of re-entering.

**Story Points:** 3  
**Priority:** P2  
**Phase:** 2

**Acceptance Criteria:**

```gherkin
Given the user long-presses a history entry
When they select "Pin to Favorites"
Then the entry appears in the Favorites panel (max 50 pinned items)
And a star icon indicates pinned status in history view

Given the user taps a favorite
When the favorite loads
Then the expression populates the input field with original values
And the user can modify values before re-evaluating

Given the user has 50 pinned favorites and attempts to pin a 51st
When they confirm the pin action
Then a prompt asks them to remove an existing favorite first
And no silent replacement occurs

Given the user deletes a favorite
When they confirm deletion
Then it is removed from favorites but remains in history
And the action is reversible via "Undo" for 5 seconds
```

---

#### US-010: Unit Conversions
**As a** Professional, **I want** to convert between units (currency, length, weight, temperature) inline, **so that** I can handle real-world calculations without switching apps.

**Story Points:** 5  
**Priority:** P2  
**Phase:** 2

**Acceptance Criteria:**

```gherkin
Given the user types "150 lbs to kg"
When the expression is evaluated
Then the result shows "68.0389 kg" with the conversion factor displayed
And the result updates within 50ms

Given the user requests a currency conversion "100 USD to EUR"
When the device is online
Then the result uses exchange rates no older than 4 hours
And the rate timestamp is displayed below the result

Given the user requests currency conversion while offline
When no cached rate exists (first-time conversion)
Then the message "Exchange rate unavailable offline" is shown
And when a cached rate exists, it is used with "Rate from [date]" disclaimer

Given the user enters an invalid conversion "5 kg to meters"
When the expression is evaluated
Then the error "Incompatible units: mass cannot convert to length" is shown
And a list of valid target units for kg is suggested
```

---

#### US-011: Quick-Access Widget
**As a** Professional, **I want** a home screen widget showing my last result and a quick-input field, **so that** I can perform calculations without fully opening the app.

**Story Points:** 5  
**Priority:** P2  
**Phase:** 2

**Acceptance Criteria:**

```gherkin
Given the user has added the CalcApp widget to their home screen
When they glance at the widget
Then it displays the last calculation result (expression + answer) updated within 1 second of app calculation

Given the user taps the widget input field
When they enter a simple expression "25 * 4"
Then the result "100" appears in the widget within 50ms
And the calculation is added to full app history

Given the widget has not been used in 24 hours
When the user views their home screen
Then the widget shows the last result with a "24h ago" timestamp
And battery usage from the widget is < 1% over 24 hours

Given the user has the widget on iOS and Android
When they interact with it
Then the UX is platform-native (iOS: WidgetKit style; Android: Material You style)
And core functionality is identical across both
```

---

#### US-012: Calculation Sharing
**As a** Professional, **I want** to share a calculation (or set of calculations) as formatted text or image, **so that** I can include results in emails, messages, or documents.

**Story Points:** 3  
**Priority:** P2  
**Phase:** 2

**Acceptance Criteria:**

```gherkin
Given the user selects a calculation from history
When they tap "Share"
Then a share sheet presents options: "Copy as text", "Copy as image", "Share via..."
And the text format is: "Expression = Result" (e.g., "15% × 2400 = 360")

Given the user selects 5 calculations for batch sharing
When they tap "Share Selected"
Then all 5 are formatted as a numbered list in a single shareable block
And total share payload is under 1MB

Given the user shares a calculation containing special math symbols
When the recipient views the shared content
Then Unicode math symbols render correctly (×, ÷, √, π)
And a plain-text fallback is included for systems that don't support Unicode

Given the user attempts to share while offline
When the share action triggers
Then "Copy to clipboard" works immediately
And "Share via..." options that require network show "available when online"
```

---

### Phase 3 — Engineer Power Tools (Dev Tier — $4.99/mo)

---

#### US-013: Programmer Mode with Multi-Base Display
**As an** Engineer, **I want** to see any number simultaneously in decimal, hexadecimal, octal, and binary, **so that** I can verify values across representations without manual conversion.

**Story Points:** 8  
**Priority:** P3  
**Phase:** 3

**Acceptance Criteria:**

```gherkin
Given the user activates Programmer Mode
When they enter "255"
Then the display simultaneously shows:
  | Base | Value      |
  | DEC  | 255        |
  | HEX  | 0xFF       |
  | OCT  | 0o377      |
  | BIN  | 1111 1111  |
And all values update within 50ms of input change

Given the user enters a value in hex "0xDEADBEEF"
When the value is accepted
Then all four base representations update simultaneously
And the binary display groups bits in nibbles (4-bit groups) with spaces

Given the user enters a negative number "-1" in 8-bit signed mode
When the value displays
Then BIN shows "1111 1111" (two's complement)
And HEX shows "0xFF"
And a word-size indicator shows "8-bit signed"

Given the user enters a value exceeding the selected word size (e.g., 256 in 8-bit mode)
When the value is entered
Then an overflow warning appears: "Value exceeds 8-bit range (0-255)"
And the display shows the truncated value with overflow bits highlighted
```

---

#### US-014: Bitwise Operations
**As an** Engineer, **I want** to perform AND, OR, XOR, NOT, and bit-shift operations with visual bit representation, **so that** I can debug hardware registers and protocol flags efficiently.

**Story Points:** 5  
**Priority:** P3  
**Phase:** 3

**Acceptance Criteria:**

```gherkin
Given the user enters "0xF0 AND 0x3C"
When the expression evaluates
Then the result shows 0x30 (decimal 48)
And a bit-level visualization shows:
  1111 0000
  0011 1100
  ---------
  0011 0000 (AND)

Given the user performs "0x01 << 7"
When the expression evaluates
Then the result shows 0x80 (binary: 1000 0000)
And bits shifted out are shown grayed/faded for educational context

Given the user performs NOT on a value without specifying word size
When the expression evaluates
Then the default word size (32-bit) is used
And the word size is displayed: "NOT (32-bit): result"

Given the user enters a shift amount exceeding word size "0x01 << 33" in 32-bit mode
When the expression evaluates
Then a warning shows "Shift amount (33) exceeds word size (32)"
And the result wraps per language-standard behavior (result = 0x02 if wrapping, or 0 if clamping — user-configurable)
```

---

#### US-015: Custom Variables and Expressions
**As an** Engineer, **I want** to define named variables and reusable expressions (e.g., BAUD_RATE = 115200), **so that** I can build up complex calculations referencing previously computed values.

**Story Points:** 5  
**Priority:** P3  
**Phase:** 3

**Acceptance Criteria:**

```gherkin
Given the user types "CLOCK_FREQ = 16000000"
When they press Enter
Then the variable "CLOCK_FREQ" is stored with value 16000000
And it appears in the variables panel

Given the user types "BAUD_DIVISOR = CLOCK_FREQ / (16 * 9600)"
When the expression evaluates
Then the result is 104.1667 and BAUD_DIVISOR is stored
And hovering/tapping the variable shows its definition expression

Given the user defines a variable with a name that conflicts with a built-in function (e.g., "sin = 5")
When they press Enter
Then the assignment is rejected with error: "Cannot override built-in function 'sin'"
And the existing function remains intact

Given the user has 100 defined variables
When they reference a variable in an expression
Then autocomplete suggests matching variable names within 100ms of typing 2+ characters
And the variables panel supports search/filter
```

---

#### US-016: Bit Field Visualizer
**As an** Engineer, **I want** to define and visualize named bit fields within a register value, **so that** I can decode hardware register contents without manual bit counting.

**Story Points:** 5  
**Priority:** P3  
**Phase:** 3

**Acceptance Criteria:**

```gherkin
Given the user defines a register template:
  "STATUS_REG: [7:BUSY] [6:ERROR] [5:3:MODE] [2:0:ADDR]"
When they enter a value "0xA5"
Then the visualizer shows:
  | Field | Bits | Value | Decoded  |
  | BUSY  | 7    | 1     | Set      |
  | ERROR | 6    | 0     | Clear    |
  | MODE  | 5:3  | 100   | 4        |
  | ADDR  | 2:0  | 101   | 5        |

Given the user modifies a field value by tapping "MODE" and entering "6"
When the field updates
Then the full register value recalculates to 0xB5
And all other fields update accordingly within 50ms

Given the user defines overlapping bit fields "[7:4:A] [5:2:B]"
When the template is saved
Then a warning shows "Fields A and B overlap at bits 5:4"
And the template is saved but with overlap bits highlighted in orange

Given the user loads a register value exceeding the template width
When the value exceeds defined field range
Then excess bits are shown in a "RESERVED" section
And a note appears: "Value has bits beyond defined fields"
```

---

#### US-017: Expression Bookmarks with Tags
**As an** Engineer, **I want** to tag and organize saved expressions into categories (e.g., "UART", "SPI", "Power"), **so that** I can build a personal engineering reference library.

**Story Points:** 3  
**Priority:** P3  
**Phase:** 3

**Acceptance Criteria:**

```gherkin
Given the user saves an expression
When they add tags "UART, baud-rate"
Then the expression is retrievable by searching either tag
And tags appear as filterable chips in the bookmarks panel

Given the user has 200 bookmarked expressions across 15 tags
When they select the "UART" tag filter
Then only UART-tagged expressions show within 300ms
And a count badge shows the number of matches

Given the user creates a tag exceeding 30 characters
When they attempt to save
Then the tag is truncated at 30 characters with a warning
And no tag may contain special characters except hyphens and underscores

Given the user deletes a tag from the system
When they confirm deletion
Then the tag is removed from all associated expressions
But the expressions themselves are not deleted
And this action is reversible for 10 seconds via "Undo"
```

---

#### US-018: Calculation Export (CSV/JSON)
**As an** Engineer, **I want** to export my calculation history and variables as CSV or JSON, **so that** I can import them into spreadsheets, scripts, or documentation.

**Story Points:** 3  
**Priority:** P3  
**Phase:** 3

**Acceptance Criteria:**

```gherkin
Given the user selects "Export" from settings
When they choose CSV format with date range "last 30 days"
Then a file downloads containing columns: timestamp, expression, result, mode, tags
And the file size is shown before download

Given the user exports 10,000 entries as JSON
When the export completes
Then the file is valid JSON (parseable without errors)
And export completes within 5 seconds
And file size does not exceed 50MB

Given the user exports while a sync is in progress
When the export triggers
Then only locally-confirmed entries are included
And a note in the file header states: "Export may not include pending sync items"

Given the user has no entries in the selected date range
When they attempt export
Then a message shows "No entries found for the selected range"
And suggests expanding the date range
```

---

### Cross-Phase Stories

---

#### US-019: App Cold Start Performance
**As a** User (all personas), **I want** the app to be usable within 2 seconds of tapping the icon, **so that** I can perform calculations the instant I need them.

**Story Points:** 5  
**Priority:** P1  
**Phase:** 1

**Acceptance Criteria:**

```gherkin
Given the app has not been opened in 24+ hours (full cold start)
When the user taps the app icon
Then the calculator is interactive (accepting input) within 2 seconds on devices from 2020 onward

Given the app was recently backgrounded (< 5 minutes ago)
When the user returns to it
Then the previous state is restored within 200ms (warm start)

Given the app is launched for the first time after install
When initial setup runs (local DB creation, default preferences)
Then first-interactive is still achieved within 3 seconds
And no mandatory onboarding blocks the calculator screen

Given the user has 10,000+ history entries in local storage
When the app cold-starts
Then history does NOT block the main calculator render
And history loads asynchronously (available within 1 second of calculator appearing)
```

---

#### US-020: Keypress Responsiveness
**As a** User (all personas), **I want** every button press to produce visual and computational feedback within 50ms, **so that** the calculator feels as responsive as a physical device.

**Story Points:** 3  
**Priority:** P1  
**Phase:** 1

**Acceptance Criteria:**

```gherkin
Given the user taps any calculator button
When the tap registers
Then visual feedback (button highlight) appears within 16ms (one frame at 60fps)
And the display updates with the pressed value within 50ms (P95)

Given the user rapid-fires 10 button presses within 1 second
When all presses register
Then all 10 inputs appear in sequence with no dropped inputs
And final display state is correct

Given the device is under memory pressure (< 200MB available RAM)
When the user presses a button
Then response time degrades no worse than 100ms (2x normal, graceful degradation)
And no ANR/freeze occurs

Given a complex expression is being live-evaluated during input
When the user presses the next key
Then input registration is never blocked by ongoing computation
And computation runs on a background isolate
```

---

#### US-021: Accessibility Compliance
**As a** User with visual impairments, **I want** the calculator to work with screen readers and support dynamic text sizing, **so that** I can perform calculations independently.

**Story Points:** 5  
**Priority:** P1  
**Phase:** 1

**Acceptance Criteria:**

```gherkin
Given the user has VoiceOver (iOS) or TalkBack (Android) enabled
When they navigate the calculator
Then every button has a semantic label (e.g., "plus" not "+", "equals" not "=")
And calculation results are announced automatically upon evaluation

Given the user has system font size set to 200% (largest)
When the app renders
Then all text remains readable without horizontal scrolling
And button targets remain minimum 44×44 points

Given the user has "Reduce Motion" enabled in system settings
When animations would normally play
Then all transitions are instant (no slide/fade/bounce)
And no information is lost by disabling animations

Given the user has high-contrast mode enabled
When the calculator renders
Then contrast ratio meets WCAG AAA (7:1) for all text
And button boundaries are clearly distinguishable
```


---

## 6. Non-Functional Requirements

| ID | Category | Requirement | Target | Source |
|----|----------|-------------|--------|--------|
| NFR-001 | Performance | Keypress-to-display latency | P95 < 50ms | CTO Strategy |
| NFR-002 | Performance | Cold start to interactive | < 2 seconds (2020+ devices) | CTO Strategy |
| NFR-003 | Availability | Uptime for sync services | 99.9% (43.8 min downtime/month max) | CTO Strategy |
| NFR-004 | Performance | Sync propagation (online-online) | < 5 seconds | CTO Strategy |
| NFR-005 | Platform | Single codebase coverage | < 5% platform-specific code | CTO Strategy |
| NFR-006 | Platform | Supported platforms | iOS 15+, Android 10+, Web (Chrome/Safari/Firefox latest-2) | CTO Strategy |
| NFR-007 | Storage | Local DB size (default) | < 50MB for 10,000 entries | Derived |
| NFR-008 | Security | Auth token handling | Tokens stored in platform secure storage (Keychain/Keystore) | Best Practice |
| NFR-009 | Security | Data at rest | All local history encrypted via platform encryption | Best Practice |
| NFR-010 | Privacy | Analytics data collection | No PII in analytics events; opt-in for usage telemetry | Compliance |
| NFR-011 | Accessibility | WCAG compliance level | AA minimum, AAA for calculator core | Product Goal |
| NFR-012 | Reliability | Crash-free rate | > 99.5% sessions | CTO Strategy (Sentry) |
| NFR-013 | Performance | Math engine evaluation (complex expr) | < 100ms for expressions up to 500 tokens | Derived |
| NFR-014 | Offline | Full functionality without network | All computation features work offline; sync queues operations | Product Goal |
| NFR-015 | Battery | Background battery consumption | < 1% per 24 hours with widget active | Platform Guideline |

---

## 7. Release Phases

### Phase 1: Student Foundation (Months 1-3)
**Target:** Free tier, Student segment, iOS + Android
**Goal:** Acquire 10,000 MAU in first 90 days via organic + university partnerships

**Includes:**
- US-001: Natural math expression input
- US-002: Step-by-step solution display
- US-003: Calculation history (local)
- US-004: Basic arithmetic with operator precedence
- US-005: Scientific functions
- US-006: Offline-first operation
- US-019: App cold start performance
- US-020: Keypress responsiveness
- US-021: Accessibility compliance

**NOT Building in Phase 1:**
- Cross-device sync — deferred because user accounts add onboarding friction to free tier adoption; revisit when DAU > 5,000
- Unit conversions — deferred because core math engine is higher priority for student value prop; revisit at Phase 2 start
- Programmer mode — deferred because Engineers are Phase 3 segment; revisit after Pro tier validation
- Graphing/plotting — deferred because requires separate rendering engine; revisit when step-by-step engagement confirms students want visual math
- Collaboration features — deferred because single-user solves the problem; revisit at 50K MAU if sharing metrics are high

---

### Phase 2: Professional Productivity (Months 4-6)
**Target:** Pro tier ($2.99/mo), Professional segment, + Web platform
**Goal:** 5% free-to-paid conversion within 60 days of Pro launch; 1,000 paying subscribers

**Includes:**
- US-007: Cross-device sync
- US-008: History search and filtering
- US-009: Favorites and pinned calculations
- US-010: Unit conversions
- US-011: Quick-access widget
- US-012: Calculation sharing

**NOT Building in Phase 2:**
- Real-time collaboration — deferred because solo productivity is the value prop; revisit if team requests > 100
- AI-powered suggestions — deferred because engineering cost is high relative to revenue at this stage; revisit at 5K subscribers
- Desktop native app — deferred because web covers desktop; revisit if web engagement shows 60%+ desktop sessions

---

### Phase 3: Engineer Power Tools (Months 7-10)
**Target:** Dev tier ($4.99/mo), Engineer segment, all platforms
**Goal:** 500 Dev tier subscribers within 90 days; NPS > 50 for programmer mode

**Includes:**
- US-013: Programmer mode with multi-base display
- US-014: Bitwise operations
- US-015: Custom variables and expressions
- US-016: Bit field visualizer
- US-017: Expression bookmarks with tags
- US-018: Calculation export (CSV/JSON)

**NOT Building in Phase 3:**
- IDE plugins — deferred because standalone app validates demand first; revisit when Dev tier hits 2K subscribers
- Hardware debugger integration — deferred because scope explosion risk; revisit if NPS feedback requests > 30%
- Custom scripting language — deferred because variable support covers 80% of use case; revisit if power user churn > 10%

---

## 8. Success Metrics

### Phase 1 Metrics (measured at Day 90)

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Monthly Active Users (MAU) | 10,000 | PostHog analytics |
| Day-7 retention | > 40% | Cohort analysis |
| Day-30 retention | > 25% | Cohort analysis |
| Avg session length | > 3 minutes | Session tracking |
| Step-by-step usage rate | > 30% of sessions | Feature flag tracking |
| Crash-free rate | > 99.5% | Sentry |
| App Store rating | > 4.3 stars | Store reviews |
| Cold start P95 | < 2 seconds | Performance monitoring |
| Keypress P95 latency | < 50ms | Performance monitoring |

### Phase 2 Metrics (measured at Day 180)

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Paying subscribers (Pro) | 1,000 | RevenueCat |
| Free-to-paid conversion | > 5% | RevenueCat / PostHog funnel |
| Sync usage (% of Pro users) | > 70% | Supabase metrics |
| History search usage | > 3x per user per week | Feature analytics |
| Widget daily active users | > 20% of Pro users | Platform analytics |
| MRR | > $2,990 | RevenueCat |
| Churn rate (monthly) | < 8% | RevenueCat |
| Cross-device users | > 40% of Pro tier | Sync analytics |
| Net Promoter Score | > 40 | In-app survey (Day 30 post-upgrade) |

### Phase 3 Metrics (measured at Day 300)

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Dev tier subscribers | 500 | RevenueCat |
| Programmer mode session length | > 8 minutes | PostHog |
| Multi-base view engagement | > 90% of programmer sessions | Feature analytics |
| Variables defined per user (avg) | > 5 | App analytics |
| Bit field templates created | > 2 per user | App analytics |
| Export usage | > 1x per week per active user | Feature analytics |
| NPS (programmer mode) | > 50 | In-app survey |
| Dev tier churn | < 6% monthly | RevenueCat |
| Total MRR (all tiers) | > $5,500 | RevenueCat |
| Total MAU (all tiers) | > 30,000 | PostHog |

---

## 9. Dependencies and Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Math engine precision issues across platforms | High — incorrect results destroy trust | Medium | Extensive property-based testing; reference test suite from Wolfram Alpha |
| Sync conflicts causing data loss | High — users lose work | Low | Conflict-free design (CRDT-inspired); "conflict drawer" UI; automated backup |
| App store rejection (iOS guidelines) | High — delays launch | Low | Pre-submission review against guidelines; no browser-engine dependencies |
| Flutter performance on low-end Android | Medium — poor experience for students | Medium | Performance budget per frame; test on $150 devices; lazy loading |
| RevenueCat SDK breaking changes | Medium — payment interruption | Low | Pin SDK version; integration tests on every release |
| Exchange rate API downtime | Low — currency conversion unavailable | Medium | Cache last-known rates; multiple API fallback providers |

---

## 10. Open Questions (To Resolve Before Architecture)

1. **Precision model:** Should the math engine use arbitrary precision by default, or fixed 64-bit with optional arbitrary precision? (Impacts performance budget)
2. **History retention:** How long should free-tier local history be kept? (Forever vs. 90-day rolling window to manage storage)
3. **Web platform scope:** Is the web version feature-complete with mobile, or a reduced "view history + basic calc" companion?
4. **Regional considerations:** Which currencies and unit systems are supported at Phase 2 launch? (All vs. top-20 by user locale)
5. **Monetization gate:** Which specific features require Pro tier? (Currently: sync + search + widget + sharing. Should history remain unlimited on free?)

---

## 11. Story Point Summary

| Phase | Stories | Total Points | Avg Points/Story |
|-------|---------|-------------|-----------------|
| Phase 1 | 9 stories (US-001 to US-006, US-019 to US-021) | 42 | 4.7 |
| Phase 2 | 6 stories (US-007 to US-012) | 29 | 4.8 |
| Phase 3 | 6 stories (US-013 to US-018) | 29 | 4.8 |
| **Total** | **21 stories** | **100 points** | **4.8** |

---

## Appendix A: Story-to-Goal Traceability

| Story | Goal(s) Served |
|-------|---------------|
| US-001 | G1 (comprehension) |
| US-002 | G1 (comprehension) |
| US-003 | G2 (retention) |
| US-004 | G1, G3 (correctness, workflow) |
| US-005 | G1 (comprehension) |
| US-006 | G2, G5 (retention, trust) |
| US-007 | G5 (trust, persistence) |
| US-008 | G2 (retrieval) |
| US-009 | G3 (workflow efficiency) |
| US-010 | G3 (workflow efficiency) |
| US-011 | G3 (workflow efficiency) |
| US-012 | G3 (workflow efficiency) |
| US-013 | G4 (multi-base) |
| US-014 | G4 (multi-base) |
| US-015 | G4 (multi-base) |
| US-016 | G4 (multi-base) |
| US-017 | G2 (retrieval) |
| US-018 | G3, G4 (workflow, power tools) |
| US-019 | G3 (workflow) |
| US-020 | G3 (workflow) |
| US-021 | G1, G3, G4 (all users) |

---

*This PRD is a living document. Updates require Product Manager approval and trigger downstream architecture review.*
