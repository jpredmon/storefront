Rails.application.routes.draw do
  root "products#index"

  resources :products, only: [ :index, :show ]

  resource  :cart,       only: [ :show ]
  resources :cart_items, only: [ :create, :update, :destroy ]

  resources :orders, only: [ :new, :create, :show ]

  namespace :admin do
    devise_for :admin_users,
      path: "",
      path_names: { sign_in: "login", sign_out: "logout" },
      controllers: { sessions: "devise/sessions" }

    resources :products
  end
end
