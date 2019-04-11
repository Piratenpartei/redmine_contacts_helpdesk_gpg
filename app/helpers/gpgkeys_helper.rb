module GpgkeysHelper
  def main_uid(key)
    key.primary_uid.uid
  end

  def key_image(key)
    pair = @sec_fingerprints.include? key.subkeys[0].fingerprint
    pair ? 'gpg_keypair' : 'gpg_pubkey'
  end

  def key_trust(key)
    if key.expired
      'expired'
    elsif key.subkeys[0].trust == :revoked
      'revoked'
    else
      'trusted'
    end
  end

  def subkeys_from_key(key)
    subkeys = key.instance_variable_get(:@subkeys)
    subkeys = subkeys[1, subkeys.length]
    subkeys
  end

  def short_fingerprint(key)
    key.subkeys[0].fingerprint[-8..-1]
  end

  def render_gpg_subkey(subkey)
    "#{subkey.length}#{subkey.pubkey_algo_letter}/#{subkey.fingerprint[-8..-1]}"
  end

  def render_expired_key(key)
    s = [key.timestamp.strftime('%Y-%m-%d'),
         "[#{l(:label_key_expires)}: #{key.expires.to_i.zero? ? l(:label_key_expires_never) : key.expires.strftime('%Y-%m-%d')}]"]
    safe_join(s, ' ')
  end
end
