class Encryption
  def self.encrypted(string, salt)
    #return CAST_256_32.encrypt(str)
    if string != ''
      enc = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
      enc.encrypt(salt)
      data = enc.update(string)
      Base64.encode64(data << enc.final).chomp
    end

  end

  def self.decrypted(str, salt)
    #return CAST_256_32.decrypt(str)
    if str
      enc = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
      enc.decrypt(salt)
      text = enc.update(Base64.decode64(str))
      result = (text << enc.final)
    end
    result
  end
end
