class PaypalCredential < ActiveRecord::Base
	# validates_presence_of :user
	# validates_presence_of :password
	# validates_presence_of :signature
	# validates_presence_of :server
	# validates_presence_of :service
	belongs_to :organization
	
	def un_password
		Encryption.decrypted(password,the_salt) if password
	end
	def un_password=(item)
		self.password = Encryption.encrypted(item,the_salt)
	end
	def un_user
		Encryption.decrypted(user,the_salt) if user
	end
	def un_user=(item)
		self.user = Encryption.encrypted(item,the_salt)
	end
	def un_server
		Encryption.decrypted(server,the_salt) if server 
	end
	def un_server=(item)
		self.server = Encryption.encrypted(item,the_salt)
	end
	def un_service
		service ? Encryption.decrypted(service,the_salt) : '/nvp'
	end
	def un_service=(item)
		self.service = Encryption.encrypted(item,the_salt)
	end
	def un_signature
		Encryption.decrypted(signature,the_salt) if signature
	end
	def un_signature=(item)
		self.signature = Encryption.encrypted(item,the_salt)
	end
	def the_salt
		self.salt = User.hashed("salt-#{Time.now}") unless self.salt
		self.salt
	end
	
end
