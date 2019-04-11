resources :gpgkeys do
  collection do
    get :refresh, :expired
  end
end
