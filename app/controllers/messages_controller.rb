class MessagesController < ApplicationController
	helper PhotosHelper

	before_filter :login_required

	# GET /messages
	# GET /messages.xml
	def index
		@user = logged_in_user
		@all_messages = @user.all_messages.uniq
		@all_message_ids = @all_messages.map{ |m| m.first.get_current_message.id }
		@marked_messages = {}
		@all_messages.each do |m|
			@marked_messages[m.first.get_current_message.id] = !m.last.nil?
		end
		
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @messages }
		end
	end

	def sent_items
		@user = logged_in_user
		@messages = @user.sent_messages
		@all_message_ids = @messages.map{ |m| m.get_current_message.id }
		#respond_to do |format|
		#  format.html # index.html.erb
		#  format.xml  { render :xml => @messages }
		#end
	end

	# GET /messages/1
	# GET /messages/1.xml
	def show
		@user = logged_in_user
		@message = Message.find(params[:id]).get_first_message
		@user.mark_read_level_id(@message.get_current_message)
		@message_list = @message.get_all_messages
		@new_message = Message.new
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @message }
		end
	end

	# GET /messages/new
	# GET /messages/new.xml

	def new
		@user = logged_in_user
		@message = Message.new

		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @message }
		end
	end

	def new_to_campaign_owner
		@user = logged_in_user
		@message = Message.new
		@campaign = Campaign.find(params[:campaign_id])
		@to_list = [@campaign.creator]
		render :action=>"new"
	end

	def new_to_user
		@user = logged_in_user
		@message = Message.new
		@to_user = User.find(params[:user_id])
		@to_list = [@to_user]
		render :action=>"new"
	end
	# GET /messages/1/edit

	def edit
		@user = logged_in_user
		@message = Message.find(params[:id])
	end

	# POST /messages
	# POST /messages.xml
	def create
		@user = logged_in_user
		message_params = params[:message]
		
		if message_params["user_ids"].to_a.empty?
			flash[:error] = "Please add at least one recipient before sending."
			redirect_to :action => "new"
			return false
		end
		
		message_params["user_ids"] = message_params["user_ids"].uniq
		@message = Message.new(message_params)
		respond_to do |format|
			if @message.save
				@user.mark_read_level_id(@message)
				flash[:notice] = 'Your message was successfully sent.'
				format.html { redirect_to(:action => "sent_items") }
				format.xml  { render :xml => @message, :status => :created, :location => @message }
			else
				format.html { render :action => "new" }
				format.xml  { render :xml => @message.errors, :status => :unprocessable_entity }
			end
		end
	end

	# POST /messages/1
	# POST /messages/1.xml
	def create_response
		@user = logged_in_user
		options = params[:new_message].dup
		@message = Message.new(options )
		respond_to do |format|
			if @message.save
				@message.check_for_creator
				@user.mark_read_level_id(@message)
				flash[:notice] = 'Your message was successfully sent.'
				format.html { redirect_to(:action => "sent_items") }
				format.xml  { render :xml => @message, :status => :created, :location => @message }
			else
				format.html { render :action => "new" }
				format.xml  { render :xml => @message.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /messages/1
	# PUT /messages/1.xml
	def update
		@user = logged_in_user
		@message = Message.find(params[:id])

		respond_to do |format|
			if @message.update_attributes(params[:message])
				flash[:notice] = 'Message was successfully updated.'
				format.html { redirect_to(@message) }
				format.xml  { head :ok }
			else
				format.html { render :action => "edit" }
				format.xml  { render :xml => @message.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /messages/1
	# DELETE /messages/1.xml
	def delete
		@user = logged_in_user
		if (params[:ids])
			params[:ids].each do |id|
				@message = Message.find(id).get_first_message
				@usermessages = UserMessage.find(:all, :conditions=>["message_id=? and user_id=?",@message.id, @user.id])
				@usermessages.each {|um| um.destroy}
			end
			flash[:notice] = 'Messages Deleted'
		else
			flash[:notice] = 'Please first select the message/s you want to delete.'
		end
		redirect_to(messages_url)
	end

	# DELETE /messages/1
	# DELETE /messages/1.xml
	def destroy
		@user = logged_in_user
		if (params[:ids])
			params[:ids].each do |id|
				@message = Message.find(id).get_first_message
				@usermessages = UserMessage.find(:all, :conditions=>["message_id=? and user_id=?",@message.id, @user.id])
				@usermessages.each {|um| um.destroy}
			end
		else
			@message = Message.find(params[:id]).get_first_message
			@usermessages = UserMessage.find(:all, :conditions=>["message_id=? and user_id=?",@message.id, @user.id])
			@usermessages.each {|um| um.destroy}
		end

		respond_to do |format|
			format.html { redirect_to(messages_url) }
			format.xml  { head :ok }
		end
	end

	def mark_as_read
		begin
			@user = logged_in_user
			messages = Message.find(params[:ids]).map(&:get_first_message)
			messages.each do |m| @user.mark_read_level_id(m.get_current_message) end
		rescue Exception => e
		end
		redirect_to "/messages"
	end

	def mark_as_unread
		begin
			@user = logged_in_user
			messages = Message.find(params[:ids]).map(&:get_first_message)
			messages.each do |m| @user.unmark_read_level_id(m.get_current_message) end
		rescue Exception => e
		end
		redirect_to "/messages"
	end

	def delete_sent
		begin
			@user = logged_in_user
			if params[:ids]
				messages = Message.find(params[:ids])
				messages += messages.map(&:get_first_message)
				messages.uniq!
				messages.each do |m| m.update_attribute(:visibility, Message::DELETED) end
				flash[:notice] = 'Messages Deleted'
			else
				flash[:notice] = 'Please first select the message/s you want to delete.'
			end
		rescue Exception => e
		end
		redirect_to "/messages/sent_items"
	end
end
