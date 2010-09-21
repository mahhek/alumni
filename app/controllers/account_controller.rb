require "erb"
class AccountController < ApplicationController
	include ERB::Util
	
	def login

	end
	
	def authenticate
		self.logged_in_user = User.authenticate(params[:user][:email], params[:user][:editable_password])
		if logged_in_user
			logged_in_user.update_attribute(:login_at, Time.now)
			if params[:request_url] && !params[:request_url].empty?
				redirect_to CGI::unescape(params[:request_url])
			else
				if logged_in_user.has_role?('OrganizationUser')
					orgs = logged_in_user.administrated_organizations
					if orgs.size == 1
						redirect_to "/organizations/#{orgs.first.organization_id}"
					else
						redirect_to :action=>'show', :controller=>'profiles', :id=>1
					end
				else
					campaigns = logged_in_user.campaigns
					if campaigns.size == 1
						redirect_to :action=>'show', :controller=>'campaigns', :id=>campaigns[0].friendly_url, :format => 'html'
					else
						redirect_to :action=>'show', :controller=>'profiles', :id=>1
					end
				end
			end
		else
			flash[:error] = "I'm sorry; either your email address or password was incorrect."
			redirect_to :action => 'index',:controller=>'home'
		end
	end

	def logout
		reset_session
		flash[:notice] = "Thanks for visiting...see you soon!"

		redirect_to :action => :index, :controller=>'home'
	end

	def forgot_password
	end

	def send_forgotten_password
		@user = User.find_by_email(params[:email])
		if @user
			Notification.deliver_forgot_password(@user)
		end
		flash[:notice] = "You have been sent an email with a link to change your password."
		redirect_to :action => 'index',:controller=>'home'
	end

	def password_change_request
		@user = User.find_by_token(params[:key])
		if !@user
			flash[:notice] = "Please log in."
			redirect_to :action => 'index',:controller=>'home'
		else
			self.logged_in_user = @user
			flash[:notice] = "Please change your password here!"
			redirect_to :controller=>"my_account",:action=>"password"
		end
	end
end
