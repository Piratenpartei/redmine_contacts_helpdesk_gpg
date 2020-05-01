require 'gpgkeys'

class GpgkeysController < ApplicationController
  layout 'admin'
  before_action :require_admin, except: [:query, :selfcheck]
  before_action :require_login, only: [:query]
  before_action :init_gpg

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

  def query
    (render_400; return false) unless params['id']
    found = GpgKeys.key_for_encryption?(params['id'])
    expires_now
    render plain: found
  end

  def selfcheck
    key = GPGME::Key.find(:public, 'test@example.com')
    render plain: key
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

  private

  def init_gpg
    HelpDeskGPG.init_gpg_settings
    @@hkp = Hkp.new(HelpDeskGPG.keyserver)
  end
end
