resources :gpgkeys do
  collection do
    get :refresh, :expired, :query
  end
end
