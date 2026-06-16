# StoreFront — Design Spec

**Date:** 2026-06-16  
**Type:** New Rails application  
**Purpose:** Educational Ruby on Rails project — learn Rails MVC fundamentals by building a real, deployable generic product storefront

---

## Overview

StoreFront is a small, classic server-rendered Rails e-commerce app. It has two distinct areas: a public storefront where anyone can browse products, add to cart, and place an order; and a password-protected admin panel where products are managed. No customer accounts, no real payments. Scope is intentionally tight to keep the focus on Rails fundamentals.

---

## Tech Stack

| Layer | Choice | Reason |
|---|---|---|
| Framework | Ruby on Rails (Classic MVC) | Server-rendered, no Hotwire/Turbo — every Rails concept is visible |
| Database | PostgreSQL | Production-ready, mirrors Merchtable's stack, required by Render |
| Auth | Devise (admin only) | Industry standard Rails auth gem |
| Styling | Bootstrap | Simple to add, looks professional, likely what Merchtable uses |
| Cart | Session-based (no DB table) | Teaches Rails sessions; no customer accounts needed |
| Payments | None | Out of scope — order form only |
| Hosting | Render (free tier) | Simple Rails deployment, free PostgreSQL for 90 days |
| DNS/CDN | Cloudflare subdomain | Free, proxies in front of Render |

---

## Scope

### In Scope
- Public product browsing (index + show)
- Session-based cart (add, update quantity, remove)
- Checkout form (name + email) → order creation
- Order confirmation page
- Admin login via Devise
- Admin product CRUD (create, edit, delete)
- Seed data (one admin user, sample products)
- Bootstrap layout with navbar and flash messages
- Deployment to Render + Cloudflare

### Out of Scope
- Customer accounts or login
- Real payment processing
- Admin order management
- Inventory/stock tracking
- Product image uploads (image URL field only)
- Search or filtering

---

## Data Model

### Product
```
name          string    required
description   text
price_cents   integer   required — stored in cents to avoid float precision bugs
image_url     string
timestamps
```

### Order
```
customer_name    string   required
customer_email   string   required
total_cents      integer  required
status           string   default: "pending"
timestamps
```

### OrderItem
```
order_id     integer  belongs_to Order
product_id   integer  belongs_to Product
quantity     integer  required
unit_price   integer  required — snapshot of price_cents at time of order
timestamps
```

### AdminUser (Devise)
```
email       string  (Devise default)
password    string  (bcrypt via Devise)
timestamps
```

### Cart (no table)
A plain Ruby class wrapping `session[:cart]` — a hash of `{ product_id => quantity }`. Responsible for adding items, removing items, calculating line totals and order total. Instantiated in the controller, never persisted.

**Price convention:** All prices stored as integer cents. A `price_in_dollars` helper converts for display (e.g. `1999` → `"$19.99"`).

---

## Routes

```ruby
# Public
root to: 'products#index'

resources :products, only: [:index, :show]

resource :cart, only: [:show]
resources :cart_items, only: [:create, :update, :destroy]

resources :orders, only: [:new, :create, :show]

# Admin
namespace :admin do
  devise_for :admin_users,
    path: '',
    path_names: { sign_in: 'login', sign_out: 'logout' }

  resources :products
end
```

---

## Controllers

### `ProductsController`
- `index` — all products, ordered by name
- `show` — single product

### `CartItemsController`
- `create` — add product to session cart (or increment if already present)
- `update` — set quantity for a cart item
- `destroy` — remove item from session cart

### `OrdersController`
- `new` — render checkout form; redirect to cart if cart is empty
- `create` — validate form, create `Order` + `OrderItem` records, clear session cart, redirect to confirmation
- `show` — order confirmation page

### `Admin::BaseController`
- Inherits from `ApplicationController`
- `before_action :authenticate_admin_user!`
- All admin controllers inherit from this

### `Admin::ProductsController`
- Full CRUD: `index`, `new`, `create`, `edit`, `update`, `destroy`
- Uses strong params for product attributes

---

## Views

### Layouts
**`application.html.erb`** — public layout
- Bootstrap navbar: "StoreFront" brand left, cart icon + item count right
- Flash messages rendered as Bootstrap alerts below navbar
- Footer: copyright line

**`admin.html.erb`** — admin layout
- Plain header: "StoreFront Admin" left, logout link right
- No public navbar

### Public Views
| View | Content |
|---|---|
| `products/index` | Bootstrap card grid — product image, name, price, "Add to Cart" button |
| `products/show` | Product image, description, price, quantity input, "Add to Cart" button |
| `cart/show` | Line items table with quantities and subtotals, order total, "Checkout" and "Continue Shopping" buttons |
| `orders/new` | Order summary (read-only), name + email fields, "Place Order" button |
| `orders/show` | Confirmation: order number, line items, total, thank-you message |

### Admin Views
| View | Content |
|---|---|
| `admin/products/index` | Table: name, price, actions (Edit, Delete) |
| `admin/products/new` | Form: name, description, price, image URL |
| `admin/products/edit` | Same form, pre-populated |

---

## Deployment

### Render
- **Web service:** Ruby environment, Puma server
- **Build command:** `bundle install && rails assets:precompile && rails db:migrate`
- **Start command:** `bundle exec puma -C config/puma.rb`
- **Environment variables:** `DATABASE_URL` (auto-set by Render), `SECRET_KEY_BASE`, `RAILS_MASTER_KEY`
- **Database:** Render PostgreSQL free instance

### Cloudflare
- Add CNAME record: chosen subdomain → Render `.onrender.com` URL
- SSL terminated at Cloudflare edge (free)
- Proxy mode on (orange cloud)

### Seed Data
- One `AdminUser` — credentials read from `ENV["ADMIN_EMAIL"]` and `ENV["ADMIN_PASSWORD"]`
- 6–8 sample products with names, descriptions, prices, and placeholder image URLs

---

## File Structure (key files)

```
app/
  controllers/
    application_controller.rb
    products_controller.rb
    cart_items_controller.rb
    orders_controller.rb
    admin/
      base_controller.rb
      products_controller.rb
  models/
    product.rb
    order.rb
    order_item.rb
    admin_user.rb
    cart.rb           ← plain Ruby, no ActiveRecord
  views/
    layouts/
      application.html.erb
      admin.html.erb
    products/
    cart/
    orders/
    admin/
      products/
  helpers/
    application_helper.rb   ← price_in_dollars helper
db/
  seeds.rb
config/
  routes.rb
```

---

## Self-Review Notes

- No TBDs or incomplete sections
- Price-as-cents convention is explicit and consistent throughout (model, OrderItem snapshot, helper)
- Cart as a plain Ruby class is unambiguous — no ActiveRecord, no table
- Admin auth enforcement is centralized in `Admin::BaseController` — no per-action gaps
- Seed credentials from ENV — never hardcoded
- Scope is tight and internally consistent — nothing in routes/controllers references out-of-scope features
