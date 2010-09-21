class ApplicationController < ActionController::Base
  
	filter_parameter_logging :password, :acct, :cvv, :expire_year, :expire_month
	include LoginSystem
	include ExceptionNotifiable  
	include Userstamp
	session :session_key => '_PayPalSDK_session_id'
	
	before_filter :no_cache

	before_filter do |c|
		the_user = User.find(c.session[:user]) unless c.session[:user].nil?
		User.current_user = the_user
	end
  
	before_filter :set_page_title, :check_site_status, :set_site_branding
        before_filter :require_no_ssl
	
	def current_user
		logged_in_user
	end

	def get_content_modules
		@content_modules
	end
	
	def flash_msg(first, second=nil)
		msg = first
		msg += "<br><span class='secondary'>#{second}</span>" if second
		msg
	end
	
	def set_user
		
	end
	
	def set_campaign
		@campaign = Campaign.find(params[:campaign_id])
	end
	
	def set_organization
		@organization = Organization.find(params[:organization_id])
	end
	
	def set_org_nav
		@show_org_menu = true
    end

	def set_page_title
		@page_title_tag = "#{params[:controller]}_#{params[:action]}_title"
		@page_title = CMS.find_by_tag(@page_title_tag)
	end
	
	def set_site_branding(org=nil)

		set_branded_logo(org)
		set_background_color(org)
	end
	
	def set_site_branding_from_org 
		set_site_branding(@organization)
	end
	
	def set_site_branding_from_campaign
    puts "oooooooooooooooooooooooooooooooooooooooooooooooooooo->#{@campaign.organization.id}"
		set_site_branding(@campaign.organization)
	end
	
	def set_branded_logo(org=nil)     
		if (org && !org.disable_branded_logo? && org.branded_logo)
			@branded_org = org
		else
			@branded_org = nil
		end     
	end
	
	def set_background_color(org=nil)
		if (org && !org.disable_background_color? && org.background_color)
			@bg_color = org.background_color
		else
			@bg_color = "084971"
		end
	end
	
	def check_site_status
		if Admin.is_site_down?
			if params[:bacon] == "chunky" || session[:bacon] == "delicious" # This is a backdoor
				session[:bacon] = "delicious"
				return true
			elsif params[:cocoa] == "butter"
				session[:bacon] = nil
			else
				redirect_to "/maintenance.html"
				return false
			end
		else
			return true
		end
	end
	
	def require_no_ssl
		if RAILS_ENV == 'production' && request.ssl?
			redirect_to_self_with_protocol("http://")
		end
	end
	
	def redirect_to_self_with_protocol(protoc)
		redirect_to url_for(params.merge({:protocol => protoc}))
	end
	
	def no_cache
		headers['Cache-Control'] = 'no-store'
	end

end
