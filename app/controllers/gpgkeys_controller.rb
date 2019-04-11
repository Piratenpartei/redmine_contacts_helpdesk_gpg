require 'gpgkeys'

class GpgkeysController < ApplicationController
  layout 'admin'
  before_action :require_admin

  def initialize
    super()
    GpgKeys.init_gpg
  end

  def index
    @limit = per_page_option
    @keys = GpgKeys.visible(params)

    @sec_fingerprints = GpgKeys.sec_fingerprints

    @keys = @keys.sort_by { |key| key.primary_uid.uid }

    @key_count = @keys.count
    @key_pages = Paginator.new @key_count, @limit, params['page']
    @offset ||= @key_pages.offset

    render layout: !request.xhr?
  end

  # import a key here
  def create
    cnt = GpgKeys.import_keys(params)
    flash[:notice] = t(:msg_gpg_keys_imported, pub: cnt[0], priv: cnt[1])
    redirect_to gpgkeys_path
  end

  # refresh keys from key server
  def refresh
    GpgKeys.refresh_keys
    flash[:notice] = t(:msg_gpg_keys_updated)
    redirect_to gpgkeys_path
  end

  # remove all expired keys
  def expired
    cnt = GpgKeys.remove_expired_keys
    flash[:notice] = t(:msg_gpg_keys_expired, cnt: cnt)
    redirect_to gpgkeys_path
  end

  def destroy
    GpgKeys.remove_key(params[:id])
    redirect_to gpgkeys_path
  end
end
