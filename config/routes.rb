Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"

  resources :parts, only: [ :show ], param: :slug do
    resources :chapters, only: [ :show ], param: :slug
  end

  get "/auth/:provider/callback", to: "sessions#create", constraints: { provider: "github" }
  get "/auth/failure", to: "sessions#failure"
  delete "/logout", to: "sessions#destroy"

  resource :progress, only: [ :show ], controller: "progress"

  resources :exercise_completions, only: [ :create ]
  delete "/exercise_completions/:exercise_key", to: "exercise_completions#destroy",
    as: :exercise_completion, constraints: { exercise_key: /[^\/]+/ }

  post "/session_for_test", to: "sessions#create_for_test" if Rails.env.test?
end
