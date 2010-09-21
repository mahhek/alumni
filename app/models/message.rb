class Message < ActiveRecord::Base

     stampable
     after_save :save_users
     has_many :user_messages
     has_many :users, :through=>:user_messages
	
	VISIBLE = 0
	DELETED = 1
	
     def save_users
               @temp_users ||= []
               @temp_users.each do |a_user_message|
                    a_user_message.message_id = id
                    a_user_message.save
               end

               if !original_message_id
                    self.original_message_id = id
                    self.save
               end
               send_messages
     end

     def send_messages
          self.user_messages.each do |um|
               unless um.user_id == self.creator_id or um.user.do_not_contact?
                  # Notification.deliver_message_sent(um)
               end
          end
     end

     def main_recipient(current_user)
          user_list = get_first_message.users.delete_if {|item|  item.id == current_user.id}
          if user_list.length == 0
             creator
          else
               user_list.first
          end
     end

     def recipient_count(current_user)
          get_first_message.users.delete_if {|item| item.id ==current_user.id}.length
     end

     def recipient_name(current_user)
          user_count = recipient_count(current_user)
          if user_count > 1
               "#{user_count} recipients"
          else
               main_recipient(current_user) .short_name
          end
     end

     def check_for_creator
          a_message = get_first_message
          user_message = UserMessage.find(:first,:conditions=>["user_id=? and message_id=?",a_message.creator_id,original_message_id] )
          unless user_message
               UserMessage.create!(:user_id=>a_message.creator_id,:message_id=>a_message.id)
          end
     end

     def user_ids=(collection)
          @temp_users = []
          collection.each do |item|
               @temp_users<< UserMessage.new(:user_id=>item)
          end
     end

     def get_original_id
          if original_message_id
               original_message_id
          else
               id
          end
     end

     def get_current_message
          Message.find(:first, :conditions => "original_message_id=#{original_message_id}", :order => 'created_at desc')
     end

     def get_first_message
          Message.find(:first,:conditions=>"original_message_id=#{original_message_id}",:order=>'created_at asc')
     end

     def get_all_messages
          Message.find(:all,:conditions=>"original_message_id=#{original_message_id}",:order=>'created_at asc' )
     end

	def text_summary(length)
		message_text.split("\n").first.to_s[0...length].strip
	end
	
	def visible?
		self.visibility == Message::VISIBLE
	end
	

end
