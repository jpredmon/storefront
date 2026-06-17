# Cloudflare + Render Deployment Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy the StoreFront Rails app to `store.jpredmon.com` using Render for hosting and Cloudflare for DNS/SSL/proxy.

**Architecture:** Cloudflare proxies `store.jpredmon.com` via CNAME to a Render Web Service running the existing Dockerfile. Render manages the PostgreSQL database and injects `DATABASE_URL`. Cloudflare handles SSL termination, caching, and DDoS protection.

**Tech Stack:** Render (Docker hosting + PostgreSQL), Cloudflare (DNS/SSL proxy), existing Rails 8.1.3 Dockerfile

## Global Constraints

- Domain: `store.jpredmon.com` (Cloudflare-managed `jpredmon.com`)
- Cloudflare SSL mode: Full (Strict)
- Render region: Oregon (default)
- Admin credentials must come from environment variables, not hardcoded defaults
- `config/master.key` must never be committed — it's already in `.gitignore`

---

## File Map

```
storefront/
  config/
    environments/
      production.rb          # Modify: SSL, hosts, health check exclusion
```

Only one file changes. Everything else is platform configuration (Render dashboard, Cloudflare dashboard).

---

## Task 1: Production Rails Config

**Files:**
- Modify: `config/environments/production.rb:24-31, 62-69`

- [ ] **Step 1: Enable SSL settings**

  In `config/environments/production.rb`, uncomment and set the SSL lines. Replace lines 24-31:

  ```ruby
  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }
  ```

- [ ] **Step 2: Enable host authorization**

  In the same file, uncomment and set the hosts block. Replace lines 62-69:

  ```ruby
  # Enable DNS rebinding protection and other `Host` header attacks.
  config.hosts = [
    "store.jpredmon.com",
    /.*\.onrender\.com/
  ]

  # Skip DNS rebinding protection for the default health check endpoint.
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
  ```

- [ ] **Step 3: Run the test suite**

  ```
  rails test
  ```
  Expected: `43 runs, 88 assertions, 0 failures, 0 errors` (production config doesn't affect test env)

- [ ] **Step 4: Commit and push**

  ```bash
  git add config/environments/production.rb
  git commit -m "feat: configure production SSL and host authorization for Render + Cloudflare"
  git push
  ```

### Adversarial Audit — Task 1

- **`config.force_ssl` + `config.ssl_options`:** The health check at `/up` is excluded from SSL redirect so Render's uptime monitor can hit it over HTTP. Without this exclusion, Render's health check gets a 301 redirect loop and marks the service as down.
- **`config.hosts` regex:** `/.*\.onrender\.com/` allows any Render subdomain. This is intentional — Render assigns a random subdomain and it may change. The regex is scoped to `.onrender.com` only.
- **No test env impact:** These settings are in `production.rb` only. Tests run in the `test` environment and won't be affected.

---

## Task 2: Create Render PostgreSQL Database

This task and all remaining tasks are performed in the browser, not in code.

- [ ] **Step 1: Create the database**

  1. Go to https://dashboard.render.com
  2. Click **New** → **PostgreSQL**
  3. Name: `storefront-db`
  4. Region: Oregon (US West)
  5. Plan: Free (or Starter for persistence beyond 90 days)
  6. Click **Create Database**

- [ ] **Step 2: Copy the Internal Database URL**

  Once created, go to the database's **Info** tab. Copy the **Internal Database URL** — it looks like:
  ```
  postgres://storefront_db_user:password@dpg-xxxxx-a.oregon-postgres.render.com/storefront_db
  ```
  You'll paste this into the web service's environment variables in Task 3.

### Adversarial Audit — Task 2

- **Free tier warning:** Render's free PostgreSQL databases expire after 90 days and are deleted. If you want persistence, use the Starter plan ($7/mo). The app will crash with `PG::ConnectionBad` when the DB is deleted.
- **Internal URL vs External URL:** Use the Internal URL (starts with `dpg-`), not the External URL. Internal is faster and doesn't count against bandwidth.

---

## Task 3: Create Render Web Service

- [ ] **Step 1: Create the web service**

  1. Go to https://dashboard.render.com
  2. Click **New** → **Web Service**
  3. Connect your GitHub account if not already connected
  4. Select the `jpredmon/storefront` repository
  5. Settings:
     - Name: `storefront`
     - Region: Oregon (US West) — same as the database
     - Runtime: **Docker**
     - Plan: Free (or Starter $7/mo to avoid cold starts)
  6. Click **Create Web Service** (don't deploy yet — add env vars first)

- [ ] **Step 2: Set environment variables**

  In the web service's **Environment** tab, add these:

  | Key | Value |
  |---|---|
  | `DATABASE_URL` | The Internal Database URL from Task 2 Step 2 |
  | `RAILS_MASTER_KEY` | `3f8f9efe7b3aab76ef81f3ebe1e213d9` |
  | `ADMIN_EMAIL` | Your production admin email |
  | `ADMIN_PASSWORD` | A strong password (not `password123`) |

- [ ] **Step 3: Set the pre-deploy command**

  In the web service's **Settings** tab, find **Pre-Deploy Command** and set it to:
  ```
  bin/rails db:migrate db:seed
  ```
  This runs migrations and seeds before each deploy. Seeds are idempotent.

- [ ] **Step 4: Trigger the first deploy**

  Click **Manual Deploy** → **Deploy latest commit**. Watch the logs:
  1. Docker build should complete (3-5 minutes first time)
  2. Pre-deploy command should show migration output and "Seeded 8 products and 1 admin user."
  3. Service should start and show "Listening on http://0.0.0.0:80"

- [ ] **Step 5: Verify the Render URL works**

  Once deployed, Render assigns a URL like `storefront-xxxx.onrender.com`. Open it in your browser:
  - Homepage should show 8 products
  - `/up` should return a 200 (green health check page)
  - `/admin/login` should render the login form

  **Copy this hostname** — you need it for Cloudflare in Task 4.

### Adversarial Audit — Task 3

- **RAILS_MASTER_KEY:** This is the contents of `config/master.key`. Without it, Rails can't decrypt `credentials.yml.enc` and will crash on boot with `ActiveSupport::MessageEncryptor::InvalidMessage`.
- **Pre-deploy vs build command:** Use **Pre-Deploy Command**, not Build Command. The build command runs during Docker image build (no database access). Pre-deploy runs after build, before the new version goes live — it has database access.
- **First deploy cold start:** The Docker build downloads Ruby, installs gems, precompiles assets. First deploy takes 3-5 minutes. Subsequent deploys use layer caching and are faster.
- **Free tier sleep:** On the free plan, the service sleeps after 15 minutes of inactivity. First request after sleep takes ~30 seconds. This is normal.

---

## Task 4: Configure Cloudflare DNS

- [ ] **Step 1: Add the CNAME record**

  1. Go to https://dash.cloudflare.com
  2. Select the `jpredmon.com` domain
  3. Go to **DNS** → **Records**
  4. Click **Add Record**:
     - Type: `CNAME`
     - Name: `store`
     - Target: the Render hostname from Task 3 Step 5 (e.g., `storefront-xxxx.onrender.com`)
     - Proxy status: **Proxied** (orange cloud ON)
     - TTL: Auto
  5. Click **Save**

- [ ] **Step 2: Set SSL mode to Full (Strict)**

  1. In Cloudflare, go to **SSL/TLS** → **Overview**
  2. Set encryption mode to **Full (strict)**
  3. This ensures Cloudflare validates Render's SSL cert on the backend connection

- [ ] **Step 3: Add custom domain in Render**

  1. Go back to Render dashboard → your `storefront` web service
  2. Go to **Settings** → **Custom Domains**
  3. Click **Add Custom Domain**
  4. Enter: `store.jpredmon.com`
  5. Render will verify the CNAME and issue a TLS certificate (may take 1-2 minutes)

- [ ] **Step 4: Verify the live site**

  Open `https://store.jpredmon.com` in your browser. Verify:

  1. Homepage loads with 8 products and a valid SSL lock icon
  2. Click a product → detail page renders
  3. Add to cart → cart shows the item
  4. Checkout → fill in name/email → "Order Confirmed!" page
  5. Go to `/admin/login` → log in with your production credentials
  6. Admin product list shows all 8 products
  7. Create, edit, and delete a test product
  8. `https://store.jpredmon.com/up` returns 200

- [ ] **Step 5: Commit nothing — this task is Cloudflare/Render config only**

### Adversarial Audit — Task 4

- **Proxy status must be Proxied (orange cloud).** If set to DNS-only (gray cloud), Cloudflare won't provide SSL termination or caching. The site will still work, but you lose Cloudflare's benefits and the connection from browser to Render won't use Cloudflare's edge SSL.
- **Full (Strict) vs Full:** "Full" validates that Render has *some* SSL cert. "Full (Strict)" validates that the cert is *valid and matches the hostname*. Render provides valid certs, so use Strict.
- **DNS propagation:** The CNAME record should propagate within seconds since Cloudflare is the authoritative DNS. If `store.jpredmon.com` doesn't resolve immediately, wait 2-3 minutes and try again.
- **Render cert issuance:** After adding the custom domain, Render needs to issue a Let's Encrypt cert. If Cloudflare proxy is enabled, Render verifies via HTTP-01 challenge through the Cloudflare proxy. This usually takes under a minute but can take up to 10 minutes.
