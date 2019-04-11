class GpgKeys
  def self.init_gpg
    ENV.delete('GPG_AGENT_INFO') # this interfers otherwise with our tests
    ENV['GNUPGHOME'] = HelpDeskGPG.keyrings_dir
    GPGME::Engine.home_dir = HelpDeskGPG.keyrings_dir
    @@hkp = Hkp.new(HelpDeskGPG.keyserver)

    Rails.logger.info "Gpgkeys#init_gpg using key rings in: #{HelpDeskGPG.keyrings_dir}"
    Rails.logger.info "Gpgkeys#init_gpg using key server: #{HelpDeskGPG.keyserver}"
  end

  def self.visible(params)
    keys = if params[:format].present? && params[:format] == 'filter'
             filter_keys(params)
           else
             find_all_keys
           end
    keys
  end

  def self.sec_fingerprints
    @@sec_fingerprints
  end

  def self.import_keys(params)
    cnt_pub_old = GPGME::Key.find(:public).length
    cnt_priv_old = GPGME::Key.find(:secret).length

    if params[:attachments]
      # Rails.logger.info "Gpgkeys#import has attachments"
      params[:attachments].each do |_id, descr|
        attached = Attachment.find_by(token: descr['token'])
        if attached
          GPGME::Key.import(File.open(attached.diskfile))
          attached.delete_from_disk
        end
      end
    end

    cnt_pub_new = GPGME::Key.find(:public).length - cnt_pub_old
    cnt_priv_new = GPGME::Key.find(:secret).length - cnt_priv_old
    [cnt_pub_new, cnt_priv_new]
  end

  def self.remove_key(fingerprint)
    key = GPGME::Key.get(fingerprint)
    key.delete!(true) if key
  end

  # refresh all keys in keystore from public key server
  def self.refresh_keys
    ctx = GPGME::Ctx.new
    keys = ctx.keys(nil, false)
    keys.each do |key|
      begin
        Rails.logger.info "Gpgkeys#refresh_key #{key.fingerprint} <#{key.email}>"
        @@hkp.fetch_and_import(key.fingerprint)
      rescue StandardError
        # catch OpenURI::HTTPError 404 for keys not on key server
        Rails.logger.info "Gpgkeys#refresh_key caught error on #{key.fingerprint}"
        next
      end
    end
    ctx.release
  end

  # remove expired keys from keystore
  def self.remove_expired_keys
    cnt = 0
    ctx = GPGME::Ctx.new
    keys = ctx.keys(nil, false)
    keys.each do |key|
      if key_expired_or_revoked(key)
        key.delete!(true)
        cnt += 1
      end
    end
    Rails.logger.info "Gpgkeys#remove_expired_keys removed #{cnt} keys"
    cnt
  end

  ## private

  def self.newContext
    GPGME::Ctx.new(pinentry_mode: GPGME::PINENTRY_MODE_LOOPBACK)
  end

  def self.find_all_keys
    _ctx = newContext
    _keys = _ctx.keys(nil, false)
    @@sec_fingerprints = []
    _sec = _ctx.keys(nil, true)
    _sec.each do |key|
      @@sec_fingerprints.push(key.subkeys[0].fingerprint)
    end
    _ctx.release
    _keys
  end # find_all_keys

  def self.filter_keys(params)
    # Rails.logger.debug "Gpgkeys filter_keys (name='#{params[:name]}', secret='#{params[:secretonly]}', expired='#{params[:expiredonly]}')"
    _all_keys = find_all_keys
    _result = []
    if params[:name]
      _all_keys.each do |key|
        _found = false
        key.instance_variable_get(:@uids).each do |uid|
          next unless uid.name.downcase.include?(params[:name].downcase) || uid.email.downcase.include?(params[:name].downcase)

          _result.push(key)
          _found = true
          break
        end
        next unless _found && params[:secretonly]

        _result.delete(key) unless @@sec_fingerprints.include? key.subkeys[0].fingerprint
      end
    elsif params[:secretonly]
      _all_keys.each do |key|
        _result.push(key) if @@sec_fingerprints.include? key.subkeys[0].fingerprint
      end
    end

    if params[:expiredonly]
      _temp = _all_keys
      _temp = _result if params[:name] || params[:secretonly]
      _result = []
      _temp.each do |key|
        _result.push(key) if keyExpiredOrRevoked(key)
      end
    end

    _result
  end # filter_keys

  def self.keyExpiredOrRevoked(_key)
    _key.expired || _key.subkeys[0].trust == :revoked
  end # keyExpiredOrRevoked

  def self.checkAndOptionallyImportKey(_mailaddress)
    # check existence of key for '_mailaddress'. Return a boolean whether we found it
    _keys = GPGME::Key.find(:public, _mailaddress)
    if _keys.empty?
      # logger.info "checkAndOptionallyImportKey: Doing hkp lookup for key '#{_mailaddress}'"
      _found = @@hkp.search(_mailaddress)
      if _found
        _found.each do |result|
          _keyid = result[0]
          _key = @@hkp.fetch_and_import(_keyid)
        end
      end
      _keys = GPGME::Key.find(:public, _mailaddress)
    end
    !_keys.empty?
  rescue Exception ## probably key not found or some other error while retrieving data from hkp
    false
  end # def checkAndOptionallyImportKey

  def self.missingKeysForEncryption(_receivers)
    # collect any key from list '_receivers' which we cannot encrypt to
    _missing = []
    _receivers.each do |r|
      _missing.push(r) unless hasKeyForEncryption?(r)
    end
    _missing
  end # def missingKeysForEncryption

  def self.hasKeyForEncryption?(_mailaddress)
    # already in store?
    return true if exactKeyAvailable?(_mailaddress, :encrypt)

    # nope. Lookup from key server
    getKeyFromKeyServer(_mailaddress)
    # now in store?
    exactKeyAvailable?(_mailaddress, :encrypt)
  end # def hasKeyForEncryption?

  def self.exactKeyAvailable?(_mailaddress, purpose)
    # lookup a key from store and check if its usable for 'purpose'
    _keys = GPGME::Key.find(:public, _mailaddress, [purpose])
    _keys.each do |_key|
      _key.uids.each do |_uid|
        return true if _uid.email.casecmp(_mailaddress).zero?
      end
    end
    false
  end # def exactKeyAvailable?

  def self.getKeyFromKeyServer(_mailaddress)
    # lookup key from keyserver and import into store if found

    _found = @@hkp.search(_mailaddress)
    if _found
      _found.each do |result|
        _keyid = result[0]
        @@hkp.fetch_and_import(_keyid)
      end
    end
  rescue StandardError # catch OpenURI::HTTPError 404 for keys not on key server
    Rails.logger.info "Gpgkeys#getKeyFromKeyServer caught error on #{_mailaddress}"
  end # def getKeyFromKeyServer
end
