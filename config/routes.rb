Rails.application.routes.draw do
  get 'to_dos/show'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  routes = lambda {
    mount_devise_token_auth_for 'User', at: 'users'

    resources :orgas, except: [:new, :edit] do
      member do
      end
    end

    resources :users, only: [:show] do
      member do
        get :list_orgas, path: 'orgas'
        get :list_events, path: 'events'
      end
    end

    resources :events, only: [:create, :show, :index]

    get '/todos', to: 'todos#index'

  }

  namespace :api do

    namespace :v1 do
      routes.call
    end

  end

end
