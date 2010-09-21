class UsersController < ApplicationController
	helper PhotosHelper
	before_filter :check_administrator_role , :only => [:list_all]
	def list_all
		@users = User.find(:all)
	end
	
	def contact
		if params[:contacts].to_a.empty?
			flash[:error] = "You must choose a recipient"
		else
			Notification.deliver_custom_user_email(params[:contacts].to_a.uniq, params[:subject], params[:body])
			flash[:notice] = "Your email has been sent"
		end
		redirect_to :action => "list_all"
	end

	def search_users
		if params[:search_text].to_s.size > 2
			user_list = User.get_by_search_term(params[:search_text])
			if user_list.size > 0
				render :partial=>'user_search_view', :locals=>{:users=>user_list}
			else
				render :text => "No users found"
			end
		else
			render :text => ""
		end
	end

	def search_linked_users
		if params[:keyword] && params[:keyword] != ''
			@user_list = User.get_by_search_term(params[:keyword])
		else
			@user_list =[]
		end
		respond_to do |format|
			format.html {render :partial=>'user_search_link', :locals=>{:users=>user_list} }# index.html.erb
			format.xml  { render :xml => @user_list  }
			format.json {render :json=>User.get_json_for(@user_list)}
		end

	end

	def  insert_user_icon
		a_user=User.find(params[:user_id])
		render :update do |page|
			page.insert_html :top, 'user_icons', "<div class='user_icon_instance' >#{a_user.short_name}<input type='hidden' name='message[user_ids][]' value='#{a_user.id}' /><a href='#' onclick='this.parentNode.innerHTML=\"\";return false;' >del</a></div>"
			page.replace_html 'search_results',''
			page[:search_name].value = ''
		end
	end

	def new_org_user
		@user = User.new
		@request_url = params[:request_url]
	end

	def new
		@user = User.new
	end

	def create
		@user = User.new(params[:user])
		if @user.i_agree == "1"  && @user.save
			if params[:photo] && !params[:photo][:uploaded_data].blank?
				photo = UserPhoto.new(params[:photo])
				if photo.save
					@user.user_photos << photo
					@user.save
				end
			end
			self.logged_in_user = @user
			flash[:notice] = "Welcome to AlumniFidelity!"
			@user.send_welcome_email(params.dup)
			unless params[:other_dest]  && !params[:other_dest] .empty?
				redirect_to  new_campaign_path
			else
				redirect_to CGI::unescape( params[:other_dest])
			end
		else
			if @user.i_agree == "0"
				@user.errors.add_to_base("You must agree to the terms of service by checking the box below in order to continue.")
			end
			render :action=>'new_org_user'
		end
	end

	def destroy
		@user = User.find(params[:id])
		if @user.update_attribute(:enabled, false)
			flash[:notice] = "User disabled"
		else
			flash[:error] = "There was a problem disabling this user."
		end
		redirect_to :action=>'index'
	end

	def terms
	end

end
