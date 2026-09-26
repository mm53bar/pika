Rails.application.routes.draw do
  root "items#index"

  resources :items

  resources :kits do
    resources :kit_items, only: %i[ create update destroy ], shallow: true
  end

  resources :trips do
    post :pack, on: :member
    resources :trip_items, only: %i[ create update destroy ], shallow: true
    resources :trip_meals, only: %i[ create update destroy ], shallow: true
  end

  resources :meals

  resources :reference_lists do
    resources :reference_items, only: %i[ create update destroy ], shallow: true
  end

  get "llms.txt" => "docs#llms", as: :llms_txt, format: false
  get "docs/api" => "docs#api", as: :docs_api
  get ".well-known/api-catalog" => "docs#api_catalog", as: :api_catalog, format: false

  get "up" => "rails/health#show", as: :rails_health_check
end
