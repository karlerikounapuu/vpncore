Rails.application.routes.draw do
  resources :vpn_clients
  namespace :api do
    namespace :v1 do
      resources :vpn_clients do
        collection do
          get ':id/download_ovpn_config', to: 'vpn_clients#download_ovpn_config'
        end
      end

      resources :servers do
        collection do
          put ':id/start', to: 'servers#start'
          put ':id/stop', to: 'servers#stop'
          post ':id/clients', to: 'servers#add_client'
        end
      end
    end
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
