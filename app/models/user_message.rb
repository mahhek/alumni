class UserMessage < ActiveRecord::Base
	belongs_to :user
	belongs_to :message
	stampable
	
	# Note: User messages only belong to the original message of a discussion
	
	def has_read(message)
        read_message_id == message.id	
    end
end
