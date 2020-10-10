Rails.application.routes.draw do
  resources :vpn_clients
  namespace :api do
    namespace :v1 do
      resources :servers
    end
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
