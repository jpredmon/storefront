# Cloudflare + Render Deployment Design

**Goal:** Deploy the StoreFront Rails app to `store.jpredmon.com` using Render for hosting and Cloudflare for DNS/SSL/proxy.

---

## Architecture

```
Browser → store.jpredmon.com → Cloudflare (proxy/SSL) → CNAME → storefront-xxxx.onrender.com → Rails app (Docker) → Render PostgreSQL
```

Cloudflare handles DNS resolution, SSL termination, caching of static assets, and DDoS protection. Render runs the Docker container and manages the PostgreSQL database. The existing Dockerfile works as-is.

---

## Render Setup

**Web Service:**
- Connect to `jpredmon/storefront` GitHub repo
- Build from Dockerfile (auto-detected)
- Region: Oregon (default) or closest to target users
- Plan: Starter ($7/mo) to avoid free-tier cold starts, or Free to start

**PostgreSQL Database:**
- Create a Render PostgreSQL instance
- Link to the web service — Render auto-injects `DATABASE_URL`

**Environment Variables:**
| Variable | Source |
|---|---|
| `RAILS_MASTER_KEY` | Contents of `config/master.key` |
| `ADMIN_EMAIL` | Production admin email (not `admin@storefront.dev`) |
| `ADMIN_PASSWORD` | A strong password (not `password123`) |
| `DATABASE_URL` | Auto-injected by Render |

**Post-deploy command:** `bin/rails db:migrate db:seed`

This runs migrations and seeds on every deploy. Seeds are idempotent (`find_or_create_by!`) so re-running is safe.

---

## Production Rails Config Changes

Three changes in `config/environments/production.rb`:

1. **`config.assume_ssl = true`** — Tell Rails that requests are HTTPS even though Cloudflare forwards them as HTTP to Render.

2. **`config.force_ssl = true`** — Redirect HTTP to HTTPS, set `Strict-Transport-Security` header, mark cookies as secure.

3. **`config.hosts`** — Allow `store.jpredmon.com` and the Render hostname. Block all other hostnames (Rails 8 default behavior).

```ruby
config.assume_ssl = true
config.force_ssl = true
config.hosts = [
  "store.jpredmon.com",
  /.*\.onrender\.com/
]
config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
```

No changes needed to `database.yml` — Rails picks up `DATABASE_URL` automatically in production.

---

## Cloudflare DNS

In Cloudflare dashboard for `jpredmon.com`:

**DNS Record:**
- Type: `CNAME`
- Name: `store`
- Target: Render app hostname (e.g., `storefront-xxxx.onrender.com`)
- Proxy status: Proxied (orange cloud enabled)

**SSL/TLS Settings:**
- Encryption mode: **Full (Strict)**
- Render provides its own SSL cert, so Cloudflare-to-Render is encrypted end-to-end

**Render Custom Domain:**
- Add `store.jpredmon.com` as a custom domain in Render service settings
- Render verifies the CNAME and issues a cert for it

---

## What Does Not Change

- **Dockerfile** — works as-is for production (already handles shebang fix, asset precompilation, Thruster)
- **`database.yml`** — production config already supports `DATABASE_URL`
- **Kamal config** — not used; Render deploys directly from Dockerfile
- **Application code** — no changes needed beyond `production.rb`

---

## Verification

After deploy:
1. `https://store.jpredmon.com` loads the product grid
2. `https://store.jpredmon.com/admin/login` accepts the production admin credentials
3. Full purchase flow works (add to cart, checkout, order confirmation)
4. Cloudflare shows the site as proxied with valid SSL
5. `https://store.jpredmon.com/up` returns 200 (Rails health check)
