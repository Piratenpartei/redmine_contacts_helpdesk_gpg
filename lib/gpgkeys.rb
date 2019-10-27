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

    params[:attachments]&.each do |_id, descr|
      attached = Attachment.find_by_token(descr['token'])
      if attached
        GPGME::Key.import(File.open(attached.diskfile))
        attached.delete_from_disk
      end
    end

    cnt_pub_new = GPGME::Key.find(:public).length - cnt_pub_old
    cnt_priv_new = GPGME::Key.find(:secret).length - cnt_priv_old
    [cnt_pub_new, cnt_priv_new]
  end

  def self.remove_key(fingerprint)
    key = GPGME::Key.get(fingerprint)
    key&.delete!(true)
  end

  # refresh all keys in keystore from public key server
  def self.refresh_keys
    ctx = GPGME::Ctx.new
    keys = ctx.keys(nil, false)
    keys.each do |key|
      Rails.logger.info "Gpgkeys#refresh_key #{key.fingerprint} <#{key.email}>"
      @@hkp.fetch_and_import(key.fingerprint)
    rescue StandardError
      # catch OpenURI::HTTPError 404 for keys not on key server
      Rails.logger.info "Gpgkeys#refresh_key caught error on #{key.fingerprint}"
      next
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

  def self.new_context
    GPGME::Ctx.new
  end

  def self.find_all_keys
    ctx = new_context
    keys = ctx.keys(nil, false)
    @@sec_fingerprints = []
    sec = ctx.keys(nil, true)
    sec.each do |key|
      @@sec_fingerprints.push(key.subkeys[0].fingerprint)
    end
    ctx.release
    keys
  end

  def self.filter_keys(params)
    # Rails.logger.debug "Gpgkeys filter_keys (name='#{params[:name]}', secret='#{params[:secretonly]}', expired='#{params[:expiredonly]}')"
    all_keys = find_all_keys
    result = []
    if params[:name]
      all_keys.each do |key|
        found = false
        key.instance_variable_get(:@uids).each do |uid|
          next unless uid.name.downcase.include?(params[:name].downcase) || uid.email.downcase.include?(params[:name].downcase)

          result.push(key)
          found = true
          break
        end
        if found && params[:secretonly]
          result.delete(key) unless @@sec_fingerprints.include?(key.subkeys[0].fingerprint)
        end
      end
    elsif params[:secretonly]
      all_keys.each do |key|
        result.push(key) if @@sec_fingerprints.include? key.subkeys[0].fingerprint
      end
    end

    if params[:expiredonly]
      temp = all_keys
      temp = result if params[:name] || params[:secretonly]
      result = []
      temp.each do |key|
        result.push(key) if key_expired_or_revoked(key)
      end
    end

    result
  end

  def self.key_expired_or_revoked(key)
    key.expired || key.subkeys[0].trust == :revoked
  end

  # check existence of key for 'mail_address'. Return a boolean whether we found it
  def self.check_and_optionally_import_key(mail_address)
    keys = GPGME::Key.find(:public, mail_address)
    if keys.empty?
      # logger.info "check_and_optionally_import_key: Doing hkp lookup for key '#{mail_address}'"
      found = @@hkp.search(mail_address)
      found&.each do |result|
        keyid = result[0]
        _key = @@hkp.fetch_and_import(keyid)
      end
      keys = GPGME::Key.find(:public, mail_address)
    end
    keys.present?
  rescue StandardError
    # probably key not found or some other error while retrieving data from hkp
    false
  end

  def self.missing_keys_for_encryption(receivers)
    # collect any key from list 'receivers' which we cannot encrypt to
    missing = []
    receivers.each do |r|
      missing.push(r) unless key_for_encryption?(r)
    end
    missing
  end

  def self.key_for_encryption?(mailaddress)
    exact_key_available?(mailaddress, :encrypt)
  end

  def self.exact_key_available?(mailaddress, purpose)
    # lookup a key from store and check if its usable for 'purpose'
    keys = GPGME::Key.find(:public, mailaddress, [purpose])
    keys.each do |key|
      key.uids.each do |uid|
        return true if uid.email.casecmp(mailaddress)
      end
    end
    false
  end

  # lookup key from keyserver and import into store if found
  def self.key_from_keyserver(mailaddress)
    found = @@hkp.search(mailaddress)
    found&.each do |result|
      keyid = result[0]
      @@hkp.fetch_and_import(keyid)
    end
  rescue StandardError # catch OpenURI::HTTPError 404 for keys not on key server
    Rails.logger.info "Gpgkeys#key_from_keyserver caught error on #{mailaddress}"
  end
end
