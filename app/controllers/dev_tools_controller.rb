class DevToolsController < ApplicationController
	before_filter :no_production
	before_filter :flag_tools, :except=>"close"
	
	def role_change
		user = logged_in_user
		case params[:do]
			when "add"
				user.roles << Role.find_by_name(params[:role])
				OrganizationUser.create(:organization_id=>params[:org], :user_id=>user.id) if params[:org]
			when "revoke"
				if params[:org]
					OrganizationUser.delete_all(["organization_id = ? and user_id = ?", params[:org], user.id])
					user.roles.delete Role.find_by_name(params[:role]) if OrganizationUser.count(:conditions => ["user_id = ?", user.id]) == 0
				else
					user.roles.delete Role.find_by_name(params[:role])
				end
		end
		redirect_to params[:goto]
	end
	
	def close
		flag_tools(nil)
		redirect_to params[:goto]
	end
	
	def log_in
		#logged_in_user = User.find(6)
		session[:user] = 6
		redirect_to params[:goto]
	end
	
	private
	def no_production
		if RAILS_ENV == "production"
			redirect_to "/"
			return false
		end
	end
	
	def flag_tools(flag="on")
		session[:dev_tools] = flag
	end
end