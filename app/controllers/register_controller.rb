class RegisterController < ApplicationController
	
	helper :form_table
	before_filter :set_registration_session,  :only => [:account, :organization, :old, :info]
  before_filter :check_administrator_role , :only => [:show, :all]
  
	def organization
		
	end
	
	def info
	
	end
	
	def old
		
	end
	
	def create
		@org_reg = OrganizationRegistration.new(params[:organization_registration])
		if @org_reg.save
			session[:org_reg] = nil
			session[:org_reg_id] = @org_reg.id
      begin
        Notification.deliver_org_registered(@org_reg)
      rescue Exception=>e
      end
			redirect_to :action => :attachments
		else
			session[:org_reg] = @org_reg
			redirect_to :action => :info
		end
	end
	
	def attachments
		@registration = OrganizationRegistration.find(session[:org_reg_id])
	end
	
	def add_attachment
		attachment = OrgRegAttachment.new(params[:org_reg_attachment])
		attachment.organization_registration_id = session[:org_reg_id]
		if attachment.save
			flash[:notice] = "File added successfully."
		else
			flash[:error] = flash_msg "Error adding file.", attachment.errors.to_json
		end
		redirect_to :action => :attachments
	end
	
	def finish
    puts "1"
		registration = OrganizationRegistration.find(session[:org_reg_id])
    puts "2"
		org = Organization.new_from_registration(session[:org_reg_id])
    puts "3"
		addr = OrganizationAddress.new_from_registration(session[:org_reg_id])
    addr.url_portion = ""
    puts "4"
		addr.save
    puts "5=>#{addr.inspect}"
		org.organization_addresses << addr    
		org.fund_raisers << FundRaiser.create!(:name=>'Default')
    puts "7"
		org.save!
    puts "8"
		registration.update_attribute(:organization_id, org.id)
    puts "9"
		logged_in_user.roles << Role.find_by_name("OrganizationUser")
    puts "0"
		OrganizationUser.create(:organization_id=>org.id, :user_id=>logged_in_user.id)
    puts "11"
		session[:org_reg_id] = nil
		
		flash[:notice] = flash_msg "Thank you for signing up with AlumniFidelity!", "After completing our due diligence on your application, we will contact you to let you know that you are configured to receive donations and we will provide additional help with promoting your campaign at that time.  In the meantime, you are welcome to explore the site and continue customizing your fundraising operation.  Complete instructions can be found <a href='/organizations/help/1'>here</a>.  Don't hesitate to contact us at <a href='mailto:support@alumnifidelity.com'>support@alumnifidelity.com</a> or 202.680.8925 if you have questions."
		redirect_to(org)
	end
	
	def all
		@registrations = OrganizationRegistration.find(:all)
	end
	
	def show
		@registration = OrganizationRegistration.find(params[:id])
		@user = logged_in_user
		@is_admin = @user && @user.has_role?('Administrator')
	end
	
	private
	def set_registration_session
		@org_reg = session[:org_reg] || OrganizationRegistration.new
		session[:org_reg] = nil
	end
end