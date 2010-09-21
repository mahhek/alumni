module MessagesHelper
     def user_to_list(user_list)
       response_text = ""
       user_list.each do |a_user|
          response_text << "<li value='#{a_user.id}'>#{a_user.short_name}</li>"
       end
       response_text
     end

  def respond_link(message)
    if message.creator
      link_to h(message.creator.short_name),
        :action => 'new_to_user',
        :user_id => message.creator.id
    else
      "System"
    end
  end

	def respond_link_sent(message)
	  if !message.users.empty?
	    link_to h(message.users.first.short_name),
	      :action => 'new_to_user',
	      :user_id => message.users.first.id
	  end
	end

end
