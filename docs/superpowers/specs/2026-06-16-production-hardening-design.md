# Production Hardening — Roadmap Design

**Date:** 2026-06-16
**Status:** Approved
**Goal:** Bring the live StoreFront app to production-grade quality across security, accessibility, code quality, and test coverage.

---

## Approach

Four independent phases, each following its own spec → plan → implementation cycle. Ordered by urgency — the app is live at `store.jpredmon.com`.

| Phase | Focus | Why this order |
|---|---|---|
| 1. Security Audit | Lock down the live app | App is public, accepts user input, has admin auth |
| 2. Accessibility Audit | WCAG 2.1 AA | User-facing, visible, professional baseline |
| 3. Code Quality Audit | Clean internals | Stabilize codebase before expanding tests |
| 4. Test Expansion | Comprehensive coverage | Test the final, clean codebase |

Each phase produces: a findings list, direct fixes committed to `master`, and any permanent CI/tooling additions.

---

## Phase 1: Security Audit

**Attack surface:** Checkout form (customer_name, customer_email), admin product form (name, description, price, image_url), admin login, session cookies, product image_url rendered as `<img src>`.

**Areas to audit:**

- **CSRF protection** — verify `protect_from_forgery` is active and compatible with Turbo form submissions
- **Input sanitization** — all user-submitted fields (checkout, admin product CRUD). Check for stored XSS via product descriptions rendered in views
- **SQL injection** — confirm all queries use parameterized inputs, no raw SQL
- **Session security** — cookie settings (secure, httponly, samesite), session fixation on admin login, session expiry
- **Devise hardening** — account lockout after failed attempts, password complexity requirements, rate limiting on login endpoint
- **CSP headers** — Content-Security-Policy restricting script and style sources to self, Bootstrap CDN, and importmap
- **image_url validation** — user-supplied URL rendered as `<img src>` is an open redirect / XSS vector if not validated server-side
- **Admin authorization** — verify unauthenticated users can't access admin routes, no IDOR on order show pages (any user can view any order by ID)
- **HTTP security headers** — X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy
- **Dependency scanning** — Brakeman and bundler-audit already in CI; confirm they run and catch everything

**Severity framework:**

| Level | Definition | Action |
|---|---|---|
| Critical | Exploitable vulnerability or data exposure | Fix immediately |
| Important | Defense-in-depth gap or hardening opportunity | Fix in this audit |
| Minor | Low-risk improvement | Document only |

---

## Phase 2: Accessibility Audit

**Standard:** WCAG 2.1 AA

**Areas to audit:**

- **Semantic HTML** — heading hierarchy (h1-h6), landmark elements (`<nav>`, `<main>`, `<footer>`), list structures for product grids
- **Form labels** — checkout form, admin product form, cart quantity fields, Devise login form
- **Color contrast** — text-muted on light backgrounds, button states, link visibility against card backgrounds
- **Keyboard navigation** — tab order through product cards, cart actions, checkout flow, admin CRUD; all interactive elements reachable and operable via keyboard
- **Skip link** — "Skip to main content" link to bypass navbar for keyboard and screen reader users
- **Focus indicators** — verify visible focus styles on all interactive elements
- **Image alt text** — product images need meaningful alt text (product name), not empty or missing alt
- **Flash messages** — announce to screen readers via `role="alert"` or `aria-live="polite"`
- **Page titles** — unique `<title>` per page (currently all pages say "StoreFront")
- **Reduced motion** — respect `prefers-reduced-motion` for transitions (Bootstrap handles most; verify no custom animations violate this)

**Tooling to add permanently:**
- `rails_best_practices` or manual checklist — no direct equivalent to `eslint-plugin-jsx-a11y` in Rails ERB, but automated contrast and semantic checks can be added to the test suite via integration test assertions

---

## Phase 3: Code Quality Audit

**Scope:** All non-test source files — models, controllers, views, helpers, routes, config.

**Review categories:**

| Category | What to look for |
|---|---|
| Controller complexity | Fat controllers with business logic that belongs in models or service objects |
| View logic | Calculations, conditionals, or formatting that belongs in helpers or presenters |
| Model responsibilities | Missing validations, input sanitization, methods that should exist but don't |
| Dead code | Unused files, routes, helpers, generated stubs (e.g., `hello_controller.js`) |
| Error handling | Unhandled edge cases — deleted products in active carts, session overflow, malformed input |
| Naming consistency | Rails conventions, route naming, controller/view directory alignment |
| DRY violations | Repeated markup across views, duplicated flash rendering in both layouts |

**Severity framework:**

| Level | Definition | Action |
|---|---|---|
| Critical | Correctness bug or data loss risk | Fix immediately |
| Important | Degrades maintainability or user experience | Fix in this audit |
| Minor | Style or preference | Document only, no fix |

---

## Phase 4: Test Expansion

**Current state:** 43 Minitest tests (models + integration controllers).

**Gaps to fill:**

- **Model edge cases** — Cart with negative quantities, zero-price products, extremely long strings, missing product during checkout, email validation edge cases
- **Controller edge cases** — double-submit on order create, updating nonexistent cart items, accessing other users' orders (IDOR), admin actions without auth beyond the single redirect test, invalid product IDs
- **Integration flow tests** — full browse → cart → checkout → confirmation in a single test, admin login → create product → verify on public storefront
- **System tests (Capybara)** — browser-level tests for JavaScript-dependent behavior: Turbo delete confirmation dialog, Bootstrap navbar toggler, flash message dismissal
- **Regression tests** — for every bug found and fixed during development (Devise sessions routing, Cart N+1, order atomicity, CartsController naming)

**Principle:** Test meaningful user-facing flows and edge cases. No coverage percentage targets. No testing for testing's sake.

---

## What This Does Not Cover

- Feature additions (customer accounts, order history, real images, payment processing)
- Visual redesign or theming
- Performance optimization (caching, CDN for assets, database indexing)
- Monitoring and alerting (error tracking, uptime monitoring)

These are all valid next steps after hardening, but out of scope for this roadmap.
