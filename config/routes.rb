Rails.application.routes.draw do
  root 'application#whatsgeoclipper'

  get 'info', to: 'application#whatsgeoclipper'
  get 'data/load', to: 'data#load'
  get 'data/new', to: 'data#new'
  post 'data/create', to: 'data#create'
  post 'data/jsonToMap', to: 'data#jsonToMap'
  get 'data/clipper', to: 'data#clipper'
  post 'data/tables', to: 'data#tables'
  post 'data/listToClip', to: 'data#listToClip'
  post 'data/clipNow', to: 'data#clipNow'
  get 'data/downloadShp/:name', to: 'data#downloadShp'
  get 'data/downloadCsv/:name', to: 'data#downloadCsv'
  get 'data/remove/:name', to: 'data#remove'

  #############################
  # Rutas para error_controller
  #############################
  match "/404", :to => "errors#not_found", :via => :all
  match "/423", :to => "errors#permission_denied", :via => :all
  match "/500", :to => "errors#internal_server_error", :via => :all
  match "/503", :to => "errors#service_down", :via => :all






#   Ultima ruta para capturar todas
get '*path' => "errors#not_found"




  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
