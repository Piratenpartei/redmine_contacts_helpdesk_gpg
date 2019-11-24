resources :gpgkeys do
  collection do
    get :refresh, :expired, :query, :selfcheck
  end
end
