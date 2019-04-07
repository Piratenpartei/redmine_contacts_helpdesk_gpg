match 'gpgkeys.import', to: 'gpgkeys#import', via: %i[get post]
match 'gpgkeys.refresh', to: 'gpgkeys#refresh', via: %i[get post]
match 'gpgkeys.expire', to: 'gpgkeys#expire', via: %i[get post]
match 'gpgkeys/query', to: 'gpgkeys#query', via: %i[get post]

match 'gpgkeys', to: 'gpgkeys#index', via: %i[get post]
match 'gpgkeys/', to: 'gpgkeys#index', via: %i[get post]
match 'gpgkeys/all', to: 'gpgkeys#index', via: %i[get post]
match 'gpgkeys/new', to: 'gpgkeys#create', via: %i[get post]
match 'gpgkeys/filter', to: 'gpgkeys#index', via: %i[get post]

resource :gpgkeys
