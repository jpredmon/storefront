# StoreFront

A classic Rails MVC storefront with public product browsing, session-based cart, order placement, and a Devise-protected admin panel for managing products.

Built with Rails 8.1.3, PostgreSQL, Bootstrap 5, and Minitest.

## Features

**Public storefront** (no login required):
- Browse products with image cards
- Product detail pages
- Session-based cart (add, update quantity, remove)
- Checkout with customer name/email
- Order confirmation page

**Admin panel** (`/admin`):
- Devise authentication
- Full CRUD for products (create, edit, delete)
- Separate admin layout

## Setup

```sh
# Install dependencies
bundle install

# Create and migrate the database
rails db:create
rails db:migrate

# Seed sample data (8 products + 1 admin user)
rails db:seed

# Start the server
rails server
```

Then open http://localhost:3000.

## Admin access

After seeding, log in at http://localhost:3000/admin/login:

- **Email:** `admin@storefront.dev`
- **Password:** `password123`

Credentials are configurable via `ADMIN_EMAIL` and `ADMIN_PASSWORD` environment variables.

## Tests

```sh
rails test
```

43 tests covering models (Product, Order, OrderItem, Cart), public controllers (Products, Cart, CartItems, Orders), and admin controllers (Admin::Products).

## Tech stack

- Ruby 3.3, Rails 8.1.3
- PostgreSQL
- Devise 5.0 (admin auth)
- Bootstrap 5 (CDN)
- Propshaft (asset pipeline)
- Minitest

## Architecture

- Server-rendered MVC -- no Hotwire, no SPA, no JS framework
- Cart is a plain Ruby class wrapping the session hash (no database table)
- Prices stored as integers (`price_cents`) to avoid floating-point issues
- `Product#price=` virtual setter converts dollar input to cents
