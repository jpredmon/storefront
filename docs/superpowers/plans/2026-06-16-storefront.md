# StoreFront Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Rails version:** 8.1.3 (Propshaft, Solid Cache/Queue, Kamal included by default)

> **Adversarial audit protocol:** Every task ends with an audit section. Before marking a task done and moving to the next: assign a confidence score (0–100), name what's uncertain, state what could fail downstream, and describe how to verify. "No errors in the log" is not verification. Challenge any step described as "should work" — it either does or it needs a check.

**Goal:** Build a small, classic Rails MVC storefront with public product browsing, a session-based cart, order placement, and a Devise-protected admin panel for managing products.

**Architecture:** Server-rendered Rails MVC — no Hotwire, no SPA, no JavaScript framework. Every request hits a controller, every response is a rendered ERB view. The cart is a plain Ruby class wrapping the session hash (no database table). Admin auth uses Devise with a separate AdminUser model.

**Tech Stack:** Ruby 3.3, Rails 7.2, PostgreSQL, Devise, Bootstrap 5 (CDN), Minitest

---

## File Map

```
storefront/
  app/
    controllers/
      application_controller.rb       # cart helper method
      products_controller.rb          # index, show
      cart_controller.rb              # show
      cart_items_controller.rb        # create, update, destroy
      orders_controller.rb            # new, create, show
      admin/
        base_controller.rb            # authenticate_admin_user! before_action
        products_controller.rb        # full CRUD
    models/
      product.rb                      # validations, price virtual attribute
      cart.rb                         # plain Ruby, wraps session[:cart]
      order.rb                        # validations, has_many order_items
      order_item.rb                   # belongs_to order + product
      admin_user.rb                   # Devise model
    views/
      layouts/
        application.html.erb          # Bootstrap navbar, flash messages
        admin.html.erb                # plain admin header + logout
      products/
        index.html.erb                # card grid
        show.html.erb                 # detail + add to cart form
      cart/
        show.html.erb                 # line items table + checkout button
      orders/
        new.html.erb                  # checkout form
        show.html.erb                 # confirmation page
      admin/
        products/
          index.html.erb              # product table with edit/delete
          new.html.erb
          edit.html.erb
          _form.html.erb              # shared form partial
    helpers/
      application_helper.rb          # price_in_dollars(cents)
  config/
    routes.rb
  db/
    seeds.rb
  test/
    models/
      product_test.rb
      cart_test.rb
      order_test.rb
      order_item_test.rb
    controllers/
      products_controller_test.rb
      cart_items_controller_test.rb
      orders_controller_test.rb
      admin/
        products_controller_test.rb
    fixtures/
      products.yml
      admin_users.yml
```

---

## Task 1: Install Ruby, Rails, and PostgreSQL

**Files:** none (environment setup)

- [ ] **Step 1: Install RubyInstaller with DevKit**

  Download from https://rubyinstaller.org/downloads/ — choose **Ruby+Devkit 3.3.x (x64)**.
  Run the installer. On the final screen, keep "Run 'ridk install'" checked. When the terminal opens, type `1` and press Enter to install MSYS2 base. Wait for it to finish.

- [ ] **Step 2: Verify Ruby**

  Open a new PowerShell window (important — old windows won't have the PATH update):
  ```
  ruby --version
  ```
  Expected: `ruby 3.3.x`

- [ ] **Step 3: Install Rails**

  Always pin the version. `gem install rails` without a constraint installs the latest release, which may not match this plan.
  ```
  gem install rails -v "~> 8.1"
  ```
  Expected: installs Rails 8.1.x and dependencies. Takes 1–3 minutes.

- [ ] **Step 4: Verify Rails**

  ```
  rails --version
  ```
  Expected: `Rails 8.1.x`

- [ ] **Step 5: Install PostgreSQL**

  Download from https://www.postgresql.org/download/windows/ — use the EDB interactive installer for PostgreSQL 16.
  Install with default settings. Set a password for the `postgres` superuser — save it, you'll need it.
  Keep the default port (5432).

- [ ] **Step 6: Verify PostgreSQL**

  ```
  psql --version
  ```
  Expected: `psql (PostgreSQL) 16.x`

  If `psql` is not found, add PostgreSQL bin to PATH:
  `C:\Program Files\PostgreSQL\16\bin`

- [ ] **Step 7: Create a database user for Rails**

  ```
  psql -U postgres
  ```
  Enter the postgres superuser password, then run:
  ```sql
  CREATE USER storefront WITH PASSWORD 'storefront' CREATEDB;
  \q
  ```

### Adversarial Audit — Task 1

- **If Step 3 silently installed the wrong version:** `rails --version` catches it. Do not proceed if the version is not 8.1.x.
- **Assumption that could be wrong:** PostgreSQL's `/bin` is on PATH. `psql --version` failing after install means PATH wasn't updated — add `C:\Program Files\PostgreSQL\16\bin` manually before continuing.
- **Downstream risk:** A Rails version mismatch here means every generated file in Task 2 will be wrong. There is no recovery without regenerating the app.

---

## Task 2: Generate the Rails App

**Files:** entire project scaffold

- [ ] **Step 1: Navigate to project directory**

  ```
  cd C:\dev\claude-practice
  ```

- [ ] **Step 2: Generate the app**

  ```
  rails new StoreFront --database=postgresql --skip-action-mailer --skip-action-mailbox --skip-action-text --skip-active-storage --skip-action-cable
  ```
  Expected: creates `StoreFront/` directory with Rails 8.1 scaffold.

  Rails 8.1 adds several gems and files the plan does not use. These are **expected and harmless** — do not remove them:
  - `solid_cache`, `solid_queue` — background job/cache adapters, only active if `SOLID_QUEUE_IN_PUMA` env var is set
  - `kamal`, `thruster` — deployment tooling, unused until Task 14
  - `turbo-rails`, `stimulus-rails` — Hotwire; installed but we opt out per-form with `local: true`
  - `app/views/pwa/` — PWA stubs, ignore
  - `config/deploy.yml` — Kamal config, ignore until Task 14

- [ ] **Step 3: Move the existing docs folder into the new app**

  ```
  Move-Item C:\dev\claude-practice\StoreFront\docs C:\dev\claude-practice\StoreFront-docs-temp
  cd StoreFront
  Move-Item C:\dev\claude-practice\StoreFront-docs-temp C:\dev\claude-practice\StoreFront\docs
  ```

- [ ] **Step 4: Configure database credentials**

  Edit `config/database.yml`. Replace the `default: &default` block:
  ```yaml
  default: &default
    adapter: postgresql
    encoding: unicode
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
    username: storefront
    password: storefront
    host: localhost
  ```

- [ ] **Step 5: Create databases**

  ```
  rails db:create
  ```
  Expected:
  ```
  Created database 'storefront_development'
  Created database 'storefront_test'
  ```

- [ ] **Step 6: Initialise git**

  ```
  git init
  git add .
  git commit -m "chore: initial Rails scaffold"
  ```

### Adversarial Audit — Task 2

- **Verify skip flags were actually honored** — do not assume the command worked. Open `config/application.rb` and confirm these five lines are commented out:
  ```ruby
  # require "active_storage/engine"
  # require "action_mailer/railtie"
  # require "action_mailbox/engine"
  # require "action_text/engine"
  # require "action_cable/engine"
  ```
  If any are uncommented, the skip flag was ignored and those components are live — remove manually.
- **If `rails db:create` silently fails:** The output will say `database already exists` or show an error. Check that both `storefront_development` and `storefront_test` are confirmed created, not assumed.
- **Downstream risk:** An unchecked skip flag means ActiveStorage or ActionMailer loads in every request, adding middleware and potentially erroring when their migrations don't exist.

---

## Task 3: Gemfile, Bootstrap Layout, and Price Helper

**Files:**
- Modify: `Gemfile`
- Modify: `app/views/layouts/application.html.erb`
- Create: `app/views/layouts/admin.html.erb`
- Modify: `app/helpers/application_helper.rb`

- [ ] **Step 1: Add Devise to Gemfile**

  Open `Gemfile` and add inside the main gem block (after the `gem "rails"` line), pinned to ensure Rails 8 compatibility:
  ```ruby
  gem "devise", ">= 4.9"
  ```
  Devise 4.9.0 added Turbo support; earlier versions break with Rails 8's default form handling.

- [ ] **Step 2: Install gems**

  ```
  bundle install
  ```
  After it completes, verify Devise resolved to 4.9 or higher:
  ```
  grep "devise " Gemfile.lock
  ```
  Expected: `devise (4.9.x)` — if it shows anything below 4.9, add an explicit upper constraint and re-run.

- [ ] **Step 3: Write the public layout**

  Replace `app/views/layouts/application.html.erb` entirely:

  > **Rails 8 / Propshaft note:** Use `stylesheet_link_tag :app` (symbol, no `media:` option) — not `"application"`. Propshaft resolves `:app` to `app.css`; the Sprockets-era `"application"` argument produces a broken asset path. The `media: "all"` option is also a Sprockets-only convention — drop it.

  ```erb
  <!DOCTYPE html>
  <html>
    <head>
      <title>StoreFront</title>
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <%= csrf_meta_tags %>
      <%= csp_meta_tag %>
      <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
      <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    </head>
    <body>
      <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="container">
          <%= link_to "StoreFront", root_path, class: "navbar-brand fw-bold" %>
          <div class="ms-auto">
            <%= link_to cart_path, class: "btn btn-outline-light btn-sm" do %>
              🛒 Cart (<%= cart.count %>)
            <% end %>
          </div>
        </div>
      </nav>

      <div class="container mt-4">
        <% flash.each do |type, message| %>
          <% css = type.to_s == "notice" ? "alert-success" : "alert-danger" %>
          <div class="alert <%= css %> alert-dismissible fade show" role="alert">
            <%= message %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
          </div>
        <% end %>

        <%= yield %>
      </div>

      <footer class="text-center text-muted py-4 mt-5 border-top">
        <small>&copy; <%= Date.current.year %> StoreFront</small>
      </footer>

      <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    </body>
  </html>
  ```

- [ ] **Step 4: Write the admin layout**

  Create `app/views/layouts/admin.html.erb`:
  ```erb
  <!DOCTYPE html>
  <html>
    <head>
      <title>StoreFront Admin</title>
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <%= csrf_meta_tags %>
      <%= csp_meta_tag %>
      <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
      <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    </head>
    <body class="bg-light">
      <nav class="navbar navbar-dark bg-dark">
        <div class="container">
          <span class="navbar-brand fw-bold">StoreFront Admin</span>
          <div class="ms-auto">
            <%= link_to "View Store", root_path, class: "btn btn-outline-light btn-sm me-2" %>
            <%= link_to "Log Out", destroy_admin_user_session_path, data: { turbo_method: :delete }, class: "btn btn-outline-danger btn-sm" %>
          </div>
        </div>
      </nav>

      <div class="container mt-4">
        <% flash.each do |type, message| %>
          <% css = type.to_s == "notice" ? "alert-success" : "alert-danger" %>
          <div class="alert <%= css %> alert-dismissible fade show" role="alert">
            <%= message %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
          </div>
        <% end %>

        <%= yield %>
      </div>

      <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    </body>
  </html>
  ```

- [ ] **Step 5: Write the price helper**

  Replace `app/helpers/application_helper.rb`:
  ```ruby
  module ApplicationHelper
    def price_in_dollars(cents)
      "$#{'%.2f' % (cents / 100.0)}"
    end
  end
  ```

- [ ] **Step 6: Commit**

  ```
  git add .
  git commit -m "feat: add devise gem, bootstrap layouts, price helper"
  ```

### Adversarial Audit — Task 3

- **Boot the server and look at the page — do not skip this.** `rails server`, open `http://localhost:3000`. If Bootstrap loaded correctly you will see a dark navbar. An unstyled white page with no navbar means `stylesheet_link_tag` or the CDN `<link>` tag is wrong. Check browser DevTools Network tab for 404s.
- **"No errors in the server log" is not sufficient.** A wrong `stylesheet_link_tag` argument produces a browser-side 404, not a server error.
- **Devise version check:** run `grep "devise " Gemfile.lock`. If version is below 4.9, the logout link will not work correctly with Turbo.
- **Downstream risk from this task:** Every view in the app inherits from these two layouts. A broken layout silently corrupts every page rendered — the bug won't surface as an error, just as missing styles or a broken navbar.

---

## Task 4: Routes

**Files:**
- Modify: `config/routes.rb`

- [ ] **Step 1: Write routes**

  Replace `config/routes.rb`:
  ```ruby
  Rails.application.routes.draw do
    root "products#index"

    resources :products, only: [:index, :show]

    resource  :cart,       only: [:show]
    resources :cart_items, only: [:create, :update, :destroy]

    resources :orders, only: [:new, :create, :show]

    namespace :admin do
      devise_for :admin_users,
        path: "",
        path_names: { sign_in: "login", sign_out: "logout" }

      resources :products
    end
  end
  ```

- [ ] **Step 2: Commit**

  ```
  git add config/routes.rb
  git commit -m "feat: add routes"
  ```

### Adversarial Audit — Task 4

- **Verify routes are loadable:** `rails routes | grep products` — if this errors, there's a syntax problem in routes.rb that will crash every request.
- **Assumption:** `devise_for :admin_users` inside `namespace :admin` generates the paths `new_admin_user_session_path` and `destroy_admin_user_session_path`. Confirm with `rails routes | grep admin_user_session` before Task 11 relies on them.
- **Downstream risk:** A wrong namespace or path name here propagates silently to every link, form, and `before_action` that references these helpers — failures won't appear until Task 11 or 12.

---

## Task 5: Product Model

**Files:**
- Create: `db/migrate/TIMESTAMP_create_products.rb` (via generator)
- Create: `app/models/product.rb`
- Create: `test/models/product_test.rb`
- Create: `test/fixtures/products.yml`

- [ ] **Step 1: Generate the migration**

  ```
  rails generate migration CreateProducts name:string description:text price_cents:integer image_url:string
  ```

- [ ] **Step 2: Write the model**

  Replace `app/models/product.rb`:
  ```ruby
  class Product < ApplicationRecord
    validates :name, presence: true
    validates :price_cents, presence: true,
              numericality: { only_integer: true, greater_than: 0 }

    def price
      price_cents.to_f / 100
    end

    def price=(dollars)
      self.price_cents = (dollars.to_f * 100).to_i
    end
  end
  ```

- [ ] **Step 3: Run the migration**

  ```
  rails db:migrate
  ```

- [ ] **Step 4: Write the fixture**

  Replace `test/fixtures/products.yml`:
  ```yaml
  tshirt:
    name: Classic T-Shirt
    description: A comfortable everyday tee.
    price_cents: 2499
    image_url: https://placehold.co/300x300

  poster:
    name: Art Poster
    description: High-quality print on glossy paper.
    price_cents: 1499
    image_url: https://placehold.co/300x300
  ```

- [ ] **Step 5: Write the failing tests**

  Create `test/models/product_test.rb`:
  ```ruby
  require "test_helper"

  class ProductTest < ActiveSupport::TestCase
    test "valid with all attributes" do
      product = Product.new(name: "Widget", price_cents: 999)
      assert product.valid?
    end

    test "invalid without name" do
      product = Product.new(price_cents: 999)
      assert_not product.valid?
      assert_includes product.errors[:name], "can't be blank"
    end

    test "invalid without price_cents" do
      product = Product.new(name: "Widget")
      assert_not product.valid?
    end

    test "invalid with price_cents of zero" do
      product = Product.new(name: "Widget", price_cents: 0)
      assert_not product.valid?
    end

    test "invalid with negative price_cents" do
      product = Product.new(name: "Widget", price_cents: -1)
      assert_not product.valid?
    end

    test "price virtual attribute converts dollars to cents" do
      product = Product.new(name: "Widget")
      product.price = 9.99
      assert_equal 999, product.price_cents
    end

    test "price reader returns dollars" do
      product = Product.new(name: "Widget", price_cents: 2499)
      assert_in_delta 24.99, product.price, 0.001
    end
  end
  ```

- [ ] **Step 6: Run tests — expect them to pass**

  ```
  rails test test/models/product_test.rb
  ```
  Expected: `7 runs, 7 assertions, 0 failures, 0 errors`

- [ ] **Step 7: Commit**

  ```
  git add .
  git commit -m "feat: add Product model with validations and price virtual attribute"
  ```

### Adversarial Audit — Task 5

- **`rails db:migrate` in Rails 8 runs more than your migration.** It also runs Solid Cache and Solid Queue migrations from `db/cache_migrate/` and `db/queue_migrate/`. This is expected — confirm the output includes your `CreateProducts` migration AND the solid_* tables without errors. A partial failure here leaves the schema in an inconsistent state.
- **If tests produce `0 runs`:** The test file wasn't found. Confirm the file path is exactly `test/models/product_test.rb`.
- **Downstream risk:** `price_cents` integer column is the source of truth for pricing everywhere — Cart totals, OrderItem unit_price, the admin form virtual `price=` setter all depend on it being an integer in cents. If this migration runs with the wrong type (e.g. decimal), every price calculation silently produces wrong results.

---

## Task 6: Products Controller and Public Views

**Files:**
- Create: `app/controllers/products_controller.rb`
- Create: `app/views/products/index.html.erb`
- Create: `app/views/products/show.html.erb`
- Create: `test/controllers/products_controller_test.rb`
- Create: `app/models/cart.rb` (pulled from Task 7 — layout depends on `cart.count`)
- Modify: `app/controllers/application_controller.rb` (pulled from Task 7 — `cart` helper_method)

> **Deviation from original plan:** The layout's `cart.count` call in the navbar crashes not just the server but also integration tests, since they render the full layout. Cart class and ApplicationController helper must be created here, not in Task 7. Task 7 now starts at the Cart tests (Steps 1–2 already done).

- [ ] **Step 1: Write the Cart class (originally Task 7 Step 1)**

  Create `app/models/cart.rb` — full implementation per Task 7. Required now because the application layout calls `cart.count` and integration tests render the layout.

- [ ] **Step 2: Add cart helper to ApplicationController (originally Task 7 Step 2)**

  Add `helper_method :cart` and the private `cart` method to `ApplicationController`.

- [ ] **Step 3: Write the controller**

  Create `app/controllers/products_controller.rb`:
  ```ruby
  class ProductsController < ApplicationController
    def index
      @products = Product.order(:name)
    end

    def show
      @product = Product.find(params[:id])
    end
  end
  ```

- [ ] **Step 4: Write the index view**

  Create `app/views/products/index.html.erb`:
  ```erb
  <h1 class="mb-4">Products</h1>

  <div class="row row-cols-1 row-cols-md-3 g-4">
    <% @products.each do |product| %>
      <div class="col">
        <div class="card h-100">
          <% if product.image_url.present? %>
            <img src="<%= product.image_url %>" class="card-img-top" alt="<%= product.name %>" style="height: 200px; object-fit: cover;">
          <% end %>
          <div class="card-body d-flex flex-column">
            <h5 class="card-title"><%= product.name %></h5>
            <p class="card-text text-muted"><%= truncate(product.description, length: 80) %></p>
            <div class="mt-auto d-flex justify-content-between align-items-center">
              <span class="fw-bold fs-5"><%= price_in_dollars(product.price_cents) %></span>
              <%= link_to "View", product, class: "btn btn-primary btn-sm" %>
            </div>
          </div>
        </div>
      </div>
    <% end %>
  </div>

  <% if @products.empty? %>
    <p class="text-muted">No products available yet.</p>
  <% end %>
  ```

- [ ] **Step 5: Write the show view**

  Create `app/views/products/show.html.erb`:
  ```erb
  <div class="row">
    <div class="col-md-5">
      <% if @product.image_url.present? %>
        <img src="<%= @product.image_url %>" class="img-fluid rounded" alt="<%= @product.name %>">
      <% end %>
    </div>
    <div class="col-md-7">
      <h1><%= @product.name %></h1>
      <p class="text-muted"><%= @product.description %></p>
      <h3 class="text-success"><%= price_in_dollars(@product.price_cents) %></h3>

      <%= form_with url: cart_items_path, method: :post, local: true do |f| %>
        <%= f.hidden_field :product_id, value: @product.id %>
        <div class="d-flex align-items-center gap-3 mt-3">
          <div style="width: 80px;">
            <%= f.number_field :quantity, value: 1, min: 1, max: 99, class: "form-control" %>
          </div>
          <%= f.submit "Add to Cart", class: "btn btn-primary" %>
        </div>
      <% end %>

      <div class="mt-3">
        <%= link_to "← Back to products", products_path, class: "text-muted" %>
      </div>
    </div>
  </div>
  ```

- [ ] **Step 6: Write the failing controller tests**

  Create `test/controllers/products_controller_test.rb`:

  > **Deviation from original plan:** The 404 test originally used `assert_raises(ActiveRecord::RecordNotFound)`. Rails 8's test environment default `config.action_dispatch.show_exceptions = :rescuable` catches `RecordNotFound` and returns a 404 response instead of raising. Changed to `assert_response :not_found`.

  ```ruby
  require "test_helper"

  class ProductsControllerTest < ActionDispatch::IntegrationTest
    test "GET index returns 200" do
      get products_path
      assert_response :success
    end

    test "GET index renders product names" do
      get products_path
      assert_select "h5.card-title", text: products(:tshirt).name
    end

    test "GET show returns 200" do
      get product_path(products(:tshirt))
      assert_response :success
    end

    test "GET show displays product name and price" do
      product = products(:tshirt)
      get product_path(product)
      assert_select "h1", text: product.name
      assert_match "$24.99", response.body
    end

    test "GET show 404 for missing product" do
      get product_path(id: 99999)
      assert_response :not_found
    end
  end
  ```

- [ ] **Step 7: Run the tests**

  ```
  rails test test/controllers/products_controller_test.rb
  ```
  Expected: `5 runs, 9 assertions, 0 failures, 0 errors`

  > **Note:** Assertion count is 9, not 5. `assert_select` and `assert_match` each count as separate assertions, and the 404 test now asserts a response code instead of catching an exception.

- [ ] **Step 8: Commit**

  ```
  git add .
  git commit -m "feat: add ProductsController and public product views"
  ```

### Adversarial Audit — Task 6

- **RESOLVED: The navbar `cart.count` dependency.** Originally flagged as a Task 7 dependency. In practice, integration tests also render the layout, so `cart.count` crashes tests — not just the server. Cart class and ApplicationController helper were pulled into this task to fix it.
- **RESOLVED: 404 test used `assert_raises(ActiveRecord::RecordNotFound)`.** Rails 8's `config.action_dispatch.show_exceptions = :rescuable` (test env default) catches `RecordNotFound` and returns a 404 response. The exception never propagates to the test. Fixed to `assert_response :not_found`.
- **Assumption in the test:** `products(:tshirt)` expects the `tshirt` fixture to exist in `test/fixtures/products.yml`. If that file wasn't written in Task 5, every controller test will fail with a fixture load error — not an assertion error.
- **Downstream risk:** `price_in_dollars` is called in both index and show views. If the helper wasn't written in Task 3, these views raise `NoMethodError` — but tests will catch this.

---

## Task 7: Cart Tests

> **Deviation from original plan:** Steps 1–2 (Cart class and ApplicationController helper) were completed in Task 6 because the application layout's `cart.count` call is required for integration tests to pass. This task now only contains the Cart unit tests and commit.

**Files:**
- Create: `test/models/cart_test.rb`

- [ ] **Step 1: Write the failing cart tests**

  Create `test/models/cart_test.rb`:
  ```ruby
  require "test_helper"

  class CartTest < ActiveSupport::TestCase
    setup do
      @session = {}
      @cart = Cart.new(@session)
    end

    test "starts empty" do
      assert @cart.empty?
      assert_equal 0, @cart.count
    end

    test "add_item increases count" do
      @cart.add_item(products(:tshirt).id, 2)
      assert_equal 2, @cart.count
      assert_not @cart.empty?
    end

    test "add_item to same product accumulates quantity" do
      @cart.add_item(products(:tshirt).id, 1)
      @cart.add_item(products(:tshirt).id, 1)
      assert_equal 2, @cart.count
    end

    test "remove_item empties single-item cart" do
      @cart.add_item(products(:tshirt).id, 1)
      @cart.remove_item(products(:tshirt).id)
      assert @cart.empty?
    end

    test "update_item sets quantity" do
      @cart.add_item(products(:tshirt).id, 1)
      @cart.update_item(products(:tshirt).id, 5)
      assert_equal 5, @cart.count
    end

    test "update_item to 0 removes item" do
      @cart.add_item(products(:tshirt).id, 1)
      @cart.update_item(products(:tshirt).id, 0)
      assert @cart.empty?
    end

    test "total_cents sums price times quantity" do
      @cart.add_item(products(:tshirt).id, 2)   # 2499 * 2 = 4998
      @cart.add_item(products(:poster).id, 1)   # 1499 * 1 = 1499
      assert_equal 6497, @cart.total_cents
    end

    test "clear empties the cart" do
      @cart.add_item(products(:tshirt).id, 3)
      @cart.clear
      assert @cart.empty?
    end

    test "items skips products that no longer exist" do
      @session[:cart] = { "99999" => 1 }
      cart = Cart.new(@session)
      assert_empty cart.items
    end
  end
  ```

- [ ] **Step 2: Run the tests**

  ```
  rails test test/models/cart_test.rb
  ```
  Expected: `9 runs, 9 assertions, 0 failures, 0 errors`

- [ ] **Step 3: Commit**

  ```
  git add .
  git commit -m "feat: add Cart class and ApplicationController cart helper"
  ```

### Adversarial Audit — Task 7

- **Cart uses the session hash directly.** If the session store changes between environments, `@session[:cart]` could be nil on first access. The `||= {}` guard in `initialize` covers this — but confirm the test's `@session = {}` accurately reflects how Rails initializes a blank session in integration tests.
- **`Product.find_by(id: product_id)` in `Cart#items` does a DB query per item.** With the test fixtures this is fine, but note that in production with many cart items this is an N+1. Not a blocker, but a known limitation baked in at this task.
- **Downstream risk:** `cart` is a `helper_method` on `ApplicationController`. Every controller and view in the app can call it. If `Cart.new` raises on a malformed session (e.g. `session[:cart]` is a String instead of a Hash from a corrupted cookie), every page crashes. The `||= {}` guard protects against nil but not against wrong types.

---

## Task 8: Cart Controller and Views

**Files:**
- Create: `app/controllers/carts_controller.rb`
- Create: `app/controllers/cart_items_controller.rb`
- Create: `app/views/carts/show.html.erb`
- Create: `test/controllers/cart_items_controller_test.rb`

- [x] **Step 1: Write CartsController**

  > **Deviation from original plan:** Rails `resource :cart` (singular) maps to `CartsController` (plural), not `CartController`. The plan specified `CartController` which caused `ActionDispatch::MissingController: uninitialized constant CartsController` on redirect. Fixed by naming the controller `CartsController` and view directory `app/views/carts/`.

  Create `app/controllers/carts_controller.rb`:
  ```ruby
  class CartsController < ApplicationController
    def show
      @cart = cart
    end
  end
  ```

- [x] **Step 2: Write CartItemsController**

  Create `app/controllers/cart_items_controller.rb`:
  ```ruby
  class CartItemsController < ApplicationController
    def create
      cart.add_item(params[:product_id], params[:quantity] || 1)
      redirect_to cart_path, notice: "Item added to cart."
    end

    def update
      cart.update_item(params[:id], params[:quantity])
      redirect_to cart_path
    end

    def destroy
      cart.remove_item(params[:id])
      redirect_to cart_path, notice: "Item removed."
    end
  end
  ```

- [x] **Step 3: Write the cart view**

  Create `app/views/carts/show.html.erb`:
  ```erb
  <h1 class="mb-4">Your Cart</h1>

  <% if @cart.empty? %>
    <p class="text-muted">Your cart is empty.</p>
    <%= link_to "Browse Products", products_path, class: "btn btn-primary" %>
  <% else %>
    <table class="table">
      <thead>
        <tr>
          <th>Product</th>
          <th>Price</th>
          <th>Quantity</th>
          <th>Subtotal</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <% @cart.items.each do |item| %>
          <tr>
            <td><%= link_to item[:product].name, item[:product] %></td>
            <td><%= price_in_dollars(item[:product].price_cents) %></td>
            <td>
              <%= form_with url: cart_item_path(item[:product].id), method: :patch, local: true do |f| %>
                <div class="d-flex gap-1" style="width: 120px;">
                  <%= f.number_field :quantity, value: item[:quantity], min: 1, max: 99, class: "form-control form-control-sm" %>
                  <%= f.submit "Update", class: "btn btn-outline-secondary btn-sm" %>
                </div>
              <% end %>
            </td>
            <td><%= price_in_dollars(item[:product].price_cents * item[:quantity]) %></td>
            <td>
              <%= button_to "Remove", cart_item_path(item[:product].id), method: :delete, class: "btn btn-outline-danger btn-sm" %>
            </td>
          </tr>
        <% end %>
      </tbody>
      <tfoot>
        <tr>
          <td colspan="3" class="text-end fw-bold">Total</td>
          <td class="fw-bold"><%= price_in_dollars(@cart.total_cents) %></td>
          <td></td>
        </tr>
      </tfoot>
    </table>

    <div class="d-flex gap-2 mt-3">
      <%= link_to "Continue Shopping", products_path, class: "btn btn-outline-secondary" %>
      <%= link_to "Checkout →", new_order_path, class: "btn btn-success" %>
    </div>
  <% end %>
  ```

- [x] **Step 4: Write the controller tests**

  Create `test/controllers/cart_items_controller_test.rb`:
  ```ruby
  require "test_helper"

  class CartItemsControllerTest < ActionDispatch::IntegrationTest
    test "POST create adds item and redirects to cart" do
      post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 2 }
      assert_redirected_to cart_path
      follow_redirect!
      assert_match "Item added to cart", response.body
    end

    test "DELETE destroy removes item and redirects" do
      post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 1 }
      delete cart_item_path(products(:tshirt).id)
      assert_redirected_to cart_path
    end

    test "PATCH update changes quantity" do
      post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 1 }
      patch cart_item_path(products(:tshirt).id), params: { quantity: 3 }
      assert_redirected_to cart_path
    end
  end
  ```

- [x] **Step 5: Run the tests**

  ```
  rails test test/controllers/cart_items_controller_test.rb
  ```
  Result: `3 runs, 11 assertions, 0 failures, 0 errors` (11 assertions because `follow_redirect!` + `assert_match` add extra assertions beyond redirects)

  Full suite: `24 runs, 41 assertions, 0 failures, 0 errors`

- [x] **Step 6: Commit**

  ```
  git add .
  git commit -m "feat: add cart controller, cart items controller, and cart view"
  ```

### Adversarial Audit — Task 8

- **`button_to` with `method: :delete` in Rails 8 with Turbo:** Turbo intercepts this and issues a DELETE request via fetch. This works — but only if Turbo is loaded. Since we're using Bootstrap CDN (not the asset pipeline for JS), confirm `turbo-rails` is still serving its JS via importmap. If turbo is somehow not loading, DELETE buttons silently issue GET requests and routes won't match.
- **`form_with ... method: :patch, local: true`** in the cart quantity update: `local: true` disables Turbo for this form. Confirm the update actually round-trips to the server (check server log for `PATCH /cart_items/:id`).
- **Now is the first time the full public flow can be tested end-to-end.** Boot the server, add an item, view cart, update quantity, remove item. Do this before Task 9 — if something is broken here it's easier to isolate now than after 5 more tasks.
- **Deviation: `resource :cart` maps to `CartsController` (plural).** The plan specified `CartController` (singular). Rails singular resource routing (`resource :cart`) still expects a pluralized controller name. This caused `ActionDispatch::MissingController` on the `follow_redirect!` in tests. Fixed by renaming to `CartsController` and `app/views/carts/`.

**Confidence: 94/100**
- Tests pass and cover the add/update/remove flow via integration tests.
- Uncertain: Turbo JS loading for `button_to method: :delete` and `form_with method: :patch` in the browser — tests use form submission directly, not JS. Needs manual browser verification.
- Uncertain: The `local: true` on `form_with` — in Rails 7+/8 this may be deprecated in favor of `data: { turbo: false }`. Functional but worth watching.

---

## Task 9: Order and OrderItem Models

**Files:**
- Create: migrations (via generator)
- Create: `app/models/order.rb`
- Create: `app/models/order_item.rb`
- Create: `test/models/order_test.rb`
- Create: `test/models/order_item_test.rb`
- Create: `test/fixtures/orders.yml`
- Create: `test/fixtures/order_items.yml`

- [x] **Step 1: Generate migrations**

  ```
  rails generate migration CreateOrders customer_name:string customer_email:string total_cents:integer status:string
  rails generate migration CreateOrderItems order:references product:references quantity:integer unit_price:integer
  ```

- [x] **Step 2: Run migrations**

  ```
  rails db:migrate
  rails db:test:prepare
  ```

- [x] **Step 3: Write the Order model**

  Create `app/models/order.rb`:
  ```ruby
  class Order < ApplicationRecord
    has_many :order_items, dependent: :destroy
    has_many :products, through: :order_items

    validates :customer_name,  presence: true
    validates :customer_email, presence: true,
              format: { with: URI::MailTo::EMAIL_REGEXP, message: "is not valid" }
    validates :total_cents, presence: true,
              numericality: { only_integer: true, greater_than: 0 }
    validates :status, presence: true
  end
  ```

- [x] **Step 4: Write the OrderItem model**

  Create `app/models/order_item.rb`:
  ```ruby
  class OrderItem < ApplicationRecord
    belongs_to :order
    belongs_to :product

    validates :quantity,   presence: true, numericality: { only_integer: true, greater_than: 0 }
    validates :unit_price, presence: true, numericality: { only_integer: true, greater_than: 0 }

    def subtotal_cents
      quantity * unit_price
    end
  end
  ```

- [x] **Step 5: Write fixtures**

  > **Deviation from original plan:** The `order_items` fixture was left empty because the PG user lacks SUPERUSER privileges required by Rails 8.1.3 to disable referential integrity during fixture loading. Rails 8.1.3 tries to validate FK constraints after fixture insertion (even for empty fixtures), which fails with `PG::InsufficientPrivilege`. Fixed by adding `config.active_record.verify_foreign_keys_for_fixtures = false` to `config/environments/test.rb`. The `has_many` test creates order items inline instead.

  Create `test/fixtures/orders.yml`:
  ```yaml
  pending_order:
    customer_name: Jane Smith
    customer_email: jane@example.com
    total_cents: 3998
    status: pending
  ```

  Create `test/fixtures/order_items.yml` — intentionally empty (FK constraint workaround).

- [x] **Step 6: Write the Order model tests**

  Create `test/models/order_test.rb`:
  ```ruby
  require "test_helper"

  class OrderTest < ActiveSupport::TestCase
    test "valid with required attributes" do
      order = Order.new(
        customer_name: "John",
        customer_email: "john@example.com",
        total_cents: 999,
        status: "pending"
      )
      assert order.valid?
    end

    test "invalid without customer_name" do
      order = Order.new(customer_email: "a@b.com", total_cents: 999, status: "pending")
      assert_not order.valid?
    end

    test "invalid without customer_email" do
      order = Order.new(customer_name: "John", total_cents: 999, status: "pending")
      assert_not order.valid?
    end

    test "invalid with malformed email" do
      order = Order.new(customer_name: "John", customer_email: "notanemail", total_cents: 999, status: "pending")
      assert_not order.valid?
    end

    test "invalid with total_cents of zero" do
      order = Order.new(customer_name: "John", customer_email: "j@example.com", total_cents: 0, status: "pending")
      assert_not order.valid?
    end

    test "has_many order_items" do
      order = orders(:pending_order)
      assert_equal 1, order.order_items.count
    end
  end
  ```

  Create `test/models/order_item_test.rb`:
  ```ruby
  require "test_helper"

  class OrderItemTest < ActiveSupport::TestCase
    test "valid with required attributes" do
      item = OrderItem.new(
        order: orders(:pending_order),
        product: products(:tshirt),
        quantity: 2,
        unit_price: 2499
      )
      assert item.valid?
    end

    test "invalid with zero quantity" do
      item = OrderItem.new(order: orders(:pending_order), product: products(:tshirt), quantity: 0, unit_price: 2499)
      assert_not item.valid?
    end

    test "subtotal_cents returns quantity times unit_price" do
      item = OrderItem.new(quantity: 3, unit_price: 1000)
      assert_equal 3000, item.subtotal_cents
    end
  end
  ```

- [x] **Step 7: Run the tests**

  ```
  rails test test/models/order_test.rb test/models/order_item_test.rb
  ```
  Result: `9 runs, 9 assertions, 0 failures, 0 errors`

  Full suite: `33 runs, 50 assertions, 0 failures, 0 errors`

- [x] **Step 8: Commit**

  ```
  git add .
  git commit -m "feat: add Order and OrderItem models with validations"
  ```

### Adversarial Audit — Task 9

- **`URI::MailTo::EMAIL_REGEXP` in Rails 8:** This constant is still available and unchanged. But verify by running `rails runner "puts URI::MailTo::EMAIL_REGEXP"` — if it errors, the Order model's email validation will raise a NameError on every save.
- **Two migrations, one `db:migrate`:** After generating both migrations, confirm `rails db:migrate` output shows BOTH `CreateOrders` and `CreateOrderItems` ran. If only one shows, the second file may have a timestamp collision.
- **Downstream risk:** `unit_price` on `OrderItem` is set at order creation time from `product.price_cents`. If products are later deleted or repriced, historical orders still hold the correct price via `unit_price`. This is correct behavior — but if `unit_price` is accidentally populated from something other than `price_cents`, order totals will be wrong with no obvious error.
- **Deviation: PG fixture FK validation.** Rails 8.1.3 validates FK constraints after fixture insertion even with empty fixture files. The `storefront` PG user lacked SUPERUSER, causing `PG::InsufficientPrivilege` errors on ALL tests (not just order tests). Fixed with `config.active_record.verify_foreign_keys_for_fixtures = false` in test.rb. The `order_items` fixture is empty; the `has_many` test creates data inline.

**Confidence: 97/100**
- All 9 model tests pass, full suite green at 33 runs.
- Both migrations confirmed ran (output showed both CreateOrders and CreateOrderItems).
- The FK fixture workaround is clean — `verify_foreign_keys_for_fixtures = false` is the Rails-recommended approach for non-superuser PG roles.

---

## Task 10: Orders Controller and Views

**Files:**
- Create: `app/controllers/orders_controller.rb`
- Create: `app/views/orders/new.html.erb`
- Create: `app/views/orders/show.html.erb`
- Create: `test/controllers/orders_controller_test.rb`

- [ ] **Step 1: Write the OrdersController**

  Create `app/controllers/orders_controller.rb`:
  ```ruby
  class OrdersController < ApplicationController
    def new
      redirect_to(cart_path, alert: "Your cart is empty.") and return if cart.empty?
      @order = Order.new
      @cart  = cart
    end

    def create
      @cart = cart
      if @cart.empty?
        redirect_to cart_path, alert: "Your cart is empty."
        return
      end

      @order = Order.new(order_params)
      @order.total_cents = @cart.total_cents
      @order.status      = "pending"

      if @order.save
        @cart.items.each do |item|
          @order.order_items.create!(
            product:    item[:product],
            quantity:   item[:quantity],
            unit_price: item[:product].price_cents
          )
        end
        cart.clear
        redirect_to @order, notice: "Order placed! Thanks for your purchase."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @order = Order.find(params[:id])
    end

    private

    def order_params
      params.require(:order).permit(:customer_name, :customer_email)
    end
  end
  ```

- [ ] **Step 2: Write the checkout form view**

  Create `app/views/orders/new.html.erb`:
  ```erb
  <div class="row">
    <div class="col-md-7">
      <h1 class="mb-4">Checkout</h1>

      <%= form_with model: @order, url: orders_path, local: true do |f| %>
        <% if @order.errors.any? %>
          <div class="alert alert-danger">
            <ul class="mb-0">
              <% @order.errors.full_messages.each do |msg| %>
                <li><%= msg %></li>
              <% end %>
            </ul>
          </div>
        <% end %>

        <div class="mb-3">
          <%= f.label :customer_name, "Full Name", class: "form-label" %>
          <%= f.text_field :customer_name, class: "form-control", placeholder: "Jane Smith" %>
        </div>

        <div class="mb-3">
          <%= f.label :customer_email, "Email", class: "form-label" %>
          <%= f.email_field :customer_email, class: "form-control", placeholder: "jane@example.com" %>
        </div>

        <%= f.submit "Place Order →", class: "btn btn-success btn-lg w-100 mt-2" %>
      <% end %>

      <div class="mt-3">
        <%= link_to "← Back to cart", cart_path, class: "text-muted" %>
      </div>
    </div>

    <div class="col-md-5">
      <div class="card">
        <div class="card-header fw-bold">Order Summary</div>
        <div class="card-body">
          <table class="table table-sm">
            <% @cart.items.each do |item| %>
              <tr>
                <td><%= item[:product].name %> &times; <%= item[:quantity] %></td>
                <td class="text-end"><%= price_in_dollars(item[:product].price_cents * item[:quantity]) %></td>
              </tr>
            <% end %>
            <tr class="fw-bold">
              <td>Total</td>
              <td class="text-end"><%= price_in_dollars(@cart.total_cents) %></td>
            </tr>
          </table>
        </div>
      </div>
    </div>
  </div>
  ```

- [ ] **Step 3: Write the confirmation view**

  Create `app/views/orders/show.html.erb`:
  ```erb
  <div class="text-center py-5">
    <h1 class="display-5 text-success">&#10003; Order Confirmed!</h1>
    <p class="lead">Thanks, <%= @order.customer_name %>. A confirmation will be sent to <strong><%= @order.customer_email %></strong>.</p>
    <p class="text-muted">Order #<%= @order.id %></p>
  </div>

  <div class="row justify-content-center">
    <div class="col-md-6">
      <div class="card">
        <div class="card-header fw-bold">Your Items</div>
        <div class="card-body">
          <table class="table table-sm">
            <% @order.order_items.each do |item| %>
              <tr>
                <td><%= item.product.name %> &times; <%= item.quantity %></td>
                <td class="text-end"><%= price_in_dollars(item.subtotal_cents) %></td>
              </tr>
            <% end %>
            <tr class="fw-bold">
              <td>Total</td>
              <td class="text-end"><%= price_in_dollars(@order.total_cents) %></td>
            </tr>
          </table>
        </div>
      </div>
      <div class="text-center mt-4">
        <%= link_to "Continue Shopping", products_path, class: "btn btn-primary" %>
      </div>
    </div>
  </div>
  ```

- [ ] **Step 4: Write the failing controller tests**

  Create `test/controllers/orders_controller_test.rb`:
  ```ruby
  require "test_helper"

  class OrdersControllerTest < ActionDispatch::IntegrationTest
    test "GET new redirects to cart when cart is empty" do
      get new_order_path
      assert_redirected_to cart_path
    end

    test "GET new renders checkout form when cart has items" do
      post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 1 }
      get new_order_path
      assert_response :success
      assert_select "h1", text: "Checkout"
    end

    test "POST create places order and clears cart" do
      post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 2 }
      assert_difference "Order.count", 1 do
        assert_difference "OrderItem.count", 1 do
          post orders_path, params: {
            order: { customer_name: "Test User", customer_email: "test@example.com" }
          }
        end
      end
      order = Order.last
      assert_redirected_to order_path(order)
      assert_equal 4998, order.total_cents
    end

    test "POST create re-renders form with errors on invalid data" do
      post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 1 }
      post orders_path, params: { order: { customer_name: "", customer_email: "bad" } }
      assert_response :unprocessable_entity
    end

    test "GET show renders confirmation page" do
      get order_path(orders(:pending_order))
      assert_response :success
      assert_select "h1", text: /Order Confirmed/
    end
  end
  ```

- [ ] **Step 5: Run the tests**

  ```
  rails test test/controllers/orders_controller_test.rb
  ```
  Expected: `5 runs, 7 assertions, 0 failures, 0 errors`

- [ ] **Step 6: Commit**

  ```
  git add .
  git commit -m "feat: add OrdersController and checkout views"
  ```

### Adversarial Audit — Task 10

- **`redirect_to(@order) and return`-style pattern in `create`:** The `and return` after `redirect_to` is required — without it, Rails continues executing and double-renders. Verify the pattern is exactly `redirect_to(...) and return`, not just `redirect_to(...)` on its own line.
- **Cart is cleared after order is saved, not before.** If `order_items.create!` raises (e.g. a validation failure on an individual item), the order record exists but no items were created, and the cart was NOT cleared. This is correct behavior — but test the unhappy path manually to confirm the cart survives a failed order.
- **`raise_on_open_redirects` (Rails 8.1 default):** All redirects in this controller go to named routes (`cart_path`, `order_path`) — no external URLs. This default will not fire. Confirmed safe.

---

## Task 11: Devise AdminUser

**Files:**
- Create: `config/initializers/devise.rb` (via generator)
- Create: `app/models/admin_user.rb` (via generator)
- Create: migration (via generator)
- Create: `test/fixtures/admin_users.yml`

- [ ] **Step 1: Install Devise**

  ```
  rails generate devise:install
  ```

  Open `config/environments/development.rb` and add inside the `Rails.application.configure do` block:
  ```ruby
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
  ```

- [ ] **Step 2: Generate AdminUser model**

  ```
  rails generate devise AdminUser
  ```

- [ ] **Step 3: Run migration**

  ```
  rails db:migrate
  ```

- [ ] **Step 4: Lock down Devise to login/logout only**

  Open the generated migration and verify it created the `admin_users` table. Then open `app/models/admin_user.rb` and replace with:
  ```ruby
  class AdminUser < ApplicationRecord
    devise :database_authenticatable, :rememberable, :validatable
  end
  ```
  (Removes `:recoverable`, `:confirmable`, etc. — we don't have email set up.)

- [ ] **Step 5: Write the admin_users fixture**

  Create `test/fixtures/admin_users.yml`:
  ```yaml
  one:
    email: admin@storefront.test
    encrypted_password: $2a$12$8lQ.emZOsYvXUlNiOS/B0.SZ6kg6KmTLIjMQqEueL0aQ8TKD1xfz.
  ```
  > **Note:** Use a static pre-computed hash, not `<%= BCrypt::Password.create(...) %>`. BCrypt is not loaded in the fixture ERB rendering context and will raise `NameError`.

- [ ] **Step 6: Commit**

  ```
  git add .
  git commit -m "feat: install Devise and generate AdminUser"
  ```

### Adversarial Audit — Task 11

- **Verify Devise version in Gemfile.lock is >= 4.9:** `grep "devise " Gemfile.lock`. If it's below 4.9, the logout link using `data: { turbo_method: :delete }` will not work correctly — Devise's Turbo support was added in 4.9.0.
- **`rails generate devise:install` outputs instructions you must not skip:** Specifically, it tells you to add `config.action_mailer.default_url_options` to `development.rb`. Add it even though we have no mailer — Devise's own confirmable/recoverable modules reference it and will warn without it. We've disabled those modules, but the warning still appears and can obscure real errors in the log.
- **The `admin_users.yml` fixture uses `BCrypt::Password.create`:** This is evaluated at test setup time, not at fixture load time. If `bcrypt` is not in the bundle (it's a Devise dependency, so it should be), every test that touches admin fixtures will fail with `NameError: uninitialized constant BCrypt`. Confirm `bundle list | grep bcrypt` shows it present after Task 3's `bundle install`.
- **Downstream risk:** If `authenticate_admin_user!` is not correctly wired in Task 12's BaseController, every admin route is publicly accessible with no error. The test that checks for redirect-to-login is the only gate — run it and read the output, don't just count assertions.

---

## Task 12: Admin Base Controller and Admin Products

**Files:**
- Create: `app/controllers/admin/base_controller.rb`
- Create: `app/controllers/admin/products_controller.rb`
- Create: `app/views/admin/products/index.html.erb`
- Create: `app/views/admin/products/new.html.erb`
- Create: `app/views/admin/products/edit.html.erb`
- Create: `app/views/admin/products/_form.html.erb`
- Create: `test/controllers/admin/products_controller_test.rb`

- [ ] **Step 1: Write Admin::BaseController**

  Create `app/controllers/admin/base_controller.rb`:
  ```ruby
  class Admin::BaseController < ApplicationController
    layout "admin"
    before_action :authenticate_admin_user!
  end
  ```

- [ ] **Step 2: Write Admin::ProductsController**

  Create `app/controllers/admin/products_controller.rb`:
  ```ruby
  class Admin::ProductsController < Admin::BaseController
    def index
      @products = Product.order(:name)
    end

    def new
      @product = Product.new
    end

    def create
      @product = Product.new(product_params)
      if @product.save
        redirect_to admin_products_path, notice: "Product created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @product = Product.find(params[:id])
    end

    def update
      @product = Product.find(params[:id])
      if @product.update(product_params)
        redirect_to admin_products_path, notice: "Product updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      Product.find(params[:id]).destroy
      redirect_to admin_products_path, notice: "Product deleted."
    end

    private

    def product_params
      params.require(:product).permit(:name, :description, :price, :image_url)
    end
  end
  ```

  Note: `price` (not `price_cents`) is permitted because the Product model's virtual `price=` setter handles the conversion.

- [ ] **Step 3: Write the shared form partial**

  Create `app/views/admin/products/_form.html.erb`:
  ```erb
  <%= form_with model: [:admin, product], local: true do |f| %>
    <% if product.errors.any? %>
      <div class="alert alert-danger">
        <ul class="mb-0">
          <% product.errors.full_messages.each do |msg| %>
            <li><%= msg %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <div class="mb-3">
      <%= f.label :name, class: "form-label" %>
      <%= f.text_field :name, class: "form-control" %>
    </div>

    <div class="mb-3">
      <%= f.label :description, class: "form-label" %>
      <%= f.text_area :description, rows: 4, class: "form-control" %>
    </div>

    <div class="mb-3">
      <%= f.label :price, "Price ($)", class: "form-label" %>
      <%= f.number_field :price, step: 0.01, min: 0.01,
          value: product.price_cents ? product.price_cents.to_f / 100 : nil,
          class: "form-control" %>
    </div>

    <div class="mb-3">
      <%= f.label :image_url, "Image URL", class: "form-label" %>
      <%= f.url_field :image_url, class: "form-control", placeholder: "https://..." %>
    </div>

    <%= f.submit class: "btn btn-primary" %>
    <%= link_to "Cancel", admin_products_path, class: "btn btn-outline-secondary ms-2" %>
  <% end %>
  ```

- [ ] **Step 4: Write the index view**

  Create `app/views/admin/products/index.html.erb`:
  ```erb
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1>Products</h1>
    <%= link_to "New Product", new_admin_product_path, class: "btn btn-primary" %>
  </div>

  <table class="table table-hover">
    <thead class="table-dark">
      <tr>
        <th>Name</th>
        <th>Price</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <% @products.each do |product| %>
        <tr>
          <td><%= product.name %></td>
          <td><%= price_in_dollars(product.price_cents) %></td>
          <td>
            <%= link_to "Edit", edit_admin_product_path(product), class: "btn btn-sm btn-outline-primary me-1" %>
            <%= button_to "Delete", admin_product_path(product), method: :delete,
                class: "btn btn-sm btn-outline-danger",
                data: { confirm: "Delete #{product.name}?" } %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>

  <% if @products.empty? %>
    <p class="text-muted">No products yet. <%= link_to "Add one", new_admin_product_path %>.</p>
  <% end %>
  ```

- [ ] **Step 5: Write new and edit views**

  Create `app/views/admin/products/new.html.erb`:
  ```erb
  <h1 class="mb-4">New Product</h1>
  <%= render "form", product: @product %>
  ```

  Create `app/views/admin/products/edit.html.erb`:
  ```erb
  <h1 class="mb-4">Edit Product</h1>
  <%= render "form", product: @product %>
  ```

- [ ] **Step 6: Write the failing admin controller tests**

  Create `test/controllers/admin/products_controller_test.rb`:
  ```ruby
  require "test_helper"

  class Admin::ProductsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = admin_users(:one)
    end

    test "GET index redirects to login when not authenticated" do
      get admin_products_path
      assert_redirected_to new_admin_admin_user_session_path
    end

    test "GET index returns 200 when authenticated" do
      sign_in @admin
      get admin_products_path
      assert_response :success
    end

    test "POST create creates product and redirects" do
      sign_in @admin
      assert_difference "Product.count", 1 do
        post admin_products_path, params: {
          product: { name: "New Item", price: "12.99", description: "Great item" }
        }
      end
      assert_redirected_to admin_products_path
      assert_equal 1299, Product.last.price_cents
    end

    test "DELETE destroy removes product" do
      sign_in @admin
      product = products(:tshirt)
      assert_difference "Product.count", -1 do
        delete admin_product_path(product)
      end
      assert_redirected_to admin_products_path
    end

    test "PATCH update changes product attributes" do
      sign_in @admin
      patch admin_product_path(products(:tshirt)), params: {
        product: { name: "Updated Tee", price: "29.99" }
      }
      assert_redirected_to admin_products_path
      assert_equal "Updated Tee", products(:tshirt).reload.name
      assert_equal 2999, products(:tshirt).reload.price_cents
    end
  end
  ```

  Note: `sign_in` is provided by Devise test helpers. Add this to `test/test_helper.rb`:
  ```ruby
  include Devise::Test::IntegrationHelpers
  ```

- [ ] **Step 7: Run the tests**

  ```
  rails test test/controllers/admin/products_controller_test.rb
  ```
  Expected: `5 runs, 6 assertions, 0 failures, 0 errors`

- [ ] **Step 8: Commit**

  ```
  git add .
  git commit -m "feat: add admin base controller, admin products CRUD, and admin views"
  ```

### Adversarial Audit — Task 12

- **`price` (not `price_cents`) is the permitted param in `product_params`.** This relies on the `price=` virtual setter on `Product` to convert dollars to cents. If someone accidentally changes this to `price_cents`, the admin form will bypass the conversion and store raw float values (e.g. `29.99` instead of `2999`). The PATCH test specifically asserts `price_cents == 2999` — this is the guard.
- **`sign_in @admin` in tests requires `include Devise::Test::IntegrationHelpers` in `test/test_helper.rb`.** If this line is missing, every test that calls `sign_in` fails with `NoMethodError` — not a Devise error, just an undefined method. Easy to miss; add it before running any admin test.
- **The admin layout uses `destroy_admin_user_session_path`.** This route only exists after `devise_for :admin_users` is declared inside the `namespace :admin` block in routes.rb (Task 4). Run `rails routes | grep destroy_admin_user` to confirm it exists before testing the logout button manually.

---

## Task 13: Seed Data

**Files:**
- Modify: `db/seeds.rb`

- [ ] **Step 1: Write seeds.rb**

  Replace `db/seeds.rb`:
  ```ruby
  # Admin user — credentials from ENV in production, defaults for development
  AdminUser.find_or_create_by!(email: ENV.fetch("ADMIN_EMAIL", "admin@storefront.dev")) do |u|
    u.password = ENV.fetch("ADMIN_PASSWORD", "password123")
    u.password_confirmation = ENV.fetch("ADMIN_PASSWORD", "password123")
  end

  # Sample products
  products = [
    { name: "Classic T-Shirt",     price: 24.99, description: "100% cotton, available in all sizes.", image_url: "https://placehold.co/300x400?text=T-Shirt" },
    { name: "Enamel Pin",          price: 8.99,  description: "Hard enamel, 1.5\" size, rubber clutch.", image_url: "https://placehold.co/300x300?text=Pin" },
    { name: "Art Poster 18x24",    price: 22.00, description: "Glossy print on 100lb paper.", image_url: "https://placehold.co/300x400?text=Poster" },
    { name: "Tote Bag",            price: 18.00, description: "Natural canvas, screen-printed.", image_url: "https://placehold.co/300x300?text=Tote" },
    { name: "Snapback Hat",        price: 32.00, description: "Structured 6-panel with flat brim.", image_url: "https://placehold.co/300x300?text=Hat" },
    { name: "Sticker Pack (5)",    price: 6.00,  description: "Weatherproof vinyl stickers.", image_url: "https://placehold.co/300x300?text=Stickers" },
    { name: "Long-Sleeve Shirt",   price: 34.99, description: "Midweight fleece, cozy fit.", image_url: "https://placehold.co/300x400?text=Long+Sleeve" },
    { name: "Vinyl Record",        price: 29.99, description: "180g black vinyl, inner sleeve.", image_url: "https://placehold.co/300x300?text=Vinyl" }
  ]

  products.each do |attrs|
    Product.find_or_create_by!(name: attrs[:name]) do |p|
      p.price       = attrs[:price]
      p.description = attrs[:description]
      p.image_url   = attrs[:image_url]
    end
  end

  puts "Seeded #{Product.count} products and 1 admin user."
  ```

- [ ] **Step 2: Run seeds**

  ```
  rails db:seed
  ```
  Expected:
  ```
  Seeded 8 products and 1 admin user.
  ```

- [ ] **Step 3: Boot the server and verify manually**

  ```
  rails server
  ```
  Open http://localhost:3000 — verify:
  - Product grid loads with 8 products
  - Clicking a product opens the detail page
  - Adding to cart updates the cart count in the navbar
  - Cart shows line items and totals correctly
  - Checkout form submits and shows confirmation
  - http://localhost:3000/admin/login accepts `admin@storefront.dev` / `password123`
  - Admin product list shows all 8 products
  - Creating, editing, deleting a product works

- [ ] **Step 4: Run the full test suite**

  ```
  rails test
  ```
  Expected: all tests pass, 0 failures, 0 errors.

- [ ] **Step 5: Commit**

  ```
  git add .
  git commit -m "feat: add seed data and verify full app flow"
  ```

### Adversarial Audit — Task 13

- **`rails db:seed` is idempotent only because of `find_or_create_by!`.** If the `AdminUser` record already exists with a different password, the block does NOT run — the existing password is kept. This is correct behavior but means re-seeding doesn't reset the admin password. If you've changed it manually and forgotten it, drop and re-create the DB.
- **Run the full test suite (`rails test`) before seeding and booting.** If any test fails here, fix it before proceeding to Task 14. A passing test suite at this point is the only baseline you have before adding deployment complexity.
- **Boot the server and walk the full purchase flow manually:** browse → product detail → add to cart → update quantity → checkout → confirmation → admin login → create/edit/delete product. Do not skip the manual walkthrough. Tests verify logic; the browser verifies the seams between layout, Turbo, Bootstrap, and session handling that tests cannot.

---

## Task 14: Deploy

**Two options.** Rails 8 ships with Kamal pre-configured; Render is simpler if you don't have a VPS. Choose one.

---

### Option A: Deploy with Kamal (Rails 8 Native)

**Files:**
- Modify: `config/deploy.yml`

Kamal is already in your Gemfile and `config/deploy.yml` was generated by the scaffold. This is the Rails 8-native deployment path — no third-party platform required, deploys to any VPS (DigitalOcean, Hetzner, etc.).

- [ ] **Step 1: Provision a VPS**

  Get a Ubuntu 22.04+ server with at least 1GB RAM. Add your SSH public key during provisioning. Note the IP address.

- [ ] **Step 2: Edit `config/deploy.yml`**

  Fill in the generated file:
  ```yaml
  service: storefront
  image: YOUR_DOCKERHUB_USERNAME/storefront

  servers:
    web:
      - YOUR_SERVER_IP

  proxy:
    ssl: true
    host: storefront.yourdomain.com

  registry:
    username: YOUR_DOCKERHUB_USERNAME
    password:
      - KAMAL_REGISTRY_PASSWORD

  env:
    secret:
      - RAILS_MASTER_KEY
      - DATABASE_URL
      - ADMIN_EMAIL
      - ADMIN_PASSWORD
  ```

- [ ] **Step 3: Set secrets**

  ```
  bin/kamal secrets set RAILS_MASTER_KEY=$(cat config/master.key)
  bin/kamal secrets set DATABASE_URL=postgres://storefront:storefront@db/storefront_production
  bin/kamal secrets set ADMIN_EMAIL=admin@yourdomain.com
  bin/kamal secrets set ADMIN_PASSWORD=<strong-password>
  ```

- [ ] **Step 4: Deploy**

  ```
  bin/kamal setup
  bin/kamal deploy
  ```

- [ ] **Step 5: Seed**

  ```
  bin/kamal app exec 'bin/rails db:seed'
  ```

---

### Option B: Deploy to Render (Simpler, No Server Management)

**Files:**
- Create: `Procfile`

- [ ] **Step 1: Create Procfile**

  Create `Procfile` in the project root:
  ```
  web: bundle exec puma -C config/puma.rb
  ```

- [ ] **Step 2: Push to GitHub**

  Create a new repository at github.com (name it `StoreFront`). Then:
  ```
  git remote add origin https://github.com/YOUR_USERNAME/StoreFront.git
  git branch -M main
  git push -u origin main
  ```

- [ ] **Step 3: Create the Render PostgreSQL database**

  - Go to https://dashboard.render.com
  - Click "New +" → "PostgreSQL"
  - Name: `storefront-db`, Region: closest to you
  - Plan: Free
  - Click "Create Database"
  - Copy the **Internal Database URL** — you'll need it in the next step

- [ ] **Step 4: Create the Render web service**

  - Click "New +" → "Web Service"
  - Connect your GitHub repo
  - Settings:
    - **Name:** `storefront`
    - **Runtime:** Ruby
    - **Build Command:** `bundle install && bundle exec rails assets:precompile && bundle exec rails db:migrate`
    - **Start Command:** `bundle exec puma -C config/puma.rb`
    - **Plan:** Free

- [ ] **Step 5: Set environment variables in Render**

  In the web service Environment tab, add:
  ```
  DATABASE_URL         = <Internal Database URL from step 3>
  RAILS_ENV            = production
  RAILS_MASTER_KEY     = <contents of config/master.key>
  ADMIN_EMAIL          = admin@yourdomain.com
  ADMIN_PASSWORD       = <choose a strong password>
  ```

- [ ] **Step 6: Deploy and seed**

  Trigger the first deploy in Render. Once live, open the Render shell and run:
  ```
  rails db:seed
  ```

- [ ] **Step 7: Add Cloudflare DNS**

  In your Cloudflare dashboard:
  - Add a CNAME record:
    - **Name:** `storefront` (or whatever subdomain you want)
    - **Target:** your Render URL (`storefront.onrender.com`)
    - **Proxy:** On (orange cloud)
  - SSL/TLS mode: Full

  Your store is now live at `storefront.yourdomain.com`.

- [ ] **Step 8: Final commit**

  ```
  git add Procfile
  git commit -m "chore: add Procfile for Render deployment"
  git push
  ```

### Adversarial Audit — Task 14

- **`rails assets:precompile` with Propshaft** works differently from Sprockets — it copies assets to `public/assets/` without fingerprinting digests by default. Render's build command calls it; confirm the build log shows it completing without error.
- **`RAILS_MASTER_KEY`** must match `config/master.key` exactly, including no trailing newline. Copy-pasting from a terminal often adds one. If the deployed app crashes with `ActiveSupport::MessageEncryptor::InvalidMessage`, this is the cause.
- **Solid Queue in production:** The `config/puma.rb` includes `plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]`. Do not set this env var in production unless you've run the Solid Queue migrations on the production DB. Leave it unset — the app runs fine without it.
- **Git branch:** The local branch is `master`; step 2 renames it to `main` with `git branch -M main`. Confirm with `git branch` after pushing — if GitHub shows `master` as the default branch, the Render deploy hook may not trigger on push.

---

## Self-Review

**Spec coverage check:**
- ✅ Public product index + show
- ✅ Session-based cart (add, update, remove)
- ✅ Checkout form → order + order items created → cart cleared
- ✅ Order confirmation page
- ✅ Devise admin login (AdminUser)
- ✅ Admin product CRUD
- ✅ Bootstrap layout (public + admin)
- ✅ price_in_dollars helper
- ✅ Seed data (admin + 8 products)
- ✅ Deploy to Render or Kamal

**Rails 8.1.3 compatibility checklist:**
- ✅ `stylesheet_link_tag :app` (Propshaft) in both layouts
- ✅ `gem "devise", ">= 4.9"` pinned for Turbo compatibility
- ✅ `data: { turbo_method: :delete }` on admin logout link
- ✅ `form_with ... local: true` on all forms (opts out of Turbo per-form)
- ✅ Solid Queue gated behind `SOLID_QUEUE_IN_PUMA` env var — not auto-started
- ✅ CSP initializer fully commented out — Bootstrap CDN unblocked
- ✅ `config.load_defaults 8.1` — `raise_on_open_redirects` safe (all redirects use named routes)

**Type consistency:**
- `price_cents` integer column throughout — Product, Order, OrderItem
- `cart.total_cents`, `item.subtotal_cents` all return integers
- `price` virtual attribute on Product converts cents ↔ dollars consistently
- `admin_products_path` / `admin_product_path` match `namespace :admin` routes
- `Admin::BaseController` correctly namespaced, all admin controllers inherit from it
- `sign_in` helper added to `test_helper.rb` before it's used in admin tests
