class HomeController < ApplicationController
   auto_complete_for :organization,:name

	helper UsersHelper
	helper PhotosHelper
  helper :form_table, :paginate, :managed_form
	def index
    puts "---------------------------------------------------------"

		@user = logged_in_user
    puts "1"
		@featured_campaigns = FeaturedCampaign.get_hottest
		puts "2"
		#Statistics
		@member_count = CampaignUser.count(:all, :conditions=>"status=#{CampaignUser::MEMBER}")
    puts "3"
		@campaign_count  = Campaign.count(:all, :conditions=>[ "campaigns.status NOT IN (?)", [Campaign::DELETED, Campaign::CLOSED] ])
		puts "4"
		@donor_count = Payment.count + Campaign.sum(:base_donors) + Organization.sum(:base_donors)
    puts "5"
		@total_donations = Payment.sum(:amount) + Campaign.sum(:base_donations) + Organization.sum(:base_donations)
    puts "6"

    puts Date.today
    @new_organizations = NewOrganization.paginate(:per_page => 5, :conditions => ["expiry_date > CURDATE()"], :page=>params[:page], :order=> "joining_date desc")
	end

	def search_schools
		@schools = School.find_by_partial_name(params[:search_term], :select=>"name", :limit=>10)
		@schools += Organization.find_by_partial_name(params[:search_term], :select=>"name", :limit=>10)
		@schools = @schools.map(&:name).uniq
		render :layout=>false
	end

  def go_to_school_new

    puts params[:school_name]
    if params[:school_name]
      @sort = "organizations.name asc"
      @search_text = params[:school_name] || ''
      @organizations = Organization.find_by_search_term(@search_text, params[:page], 5, @sort)
      if @organizations.size > 0
        redirect_to :controller=> "organizations", :action => "show", :id => @organizations.first.id
      else
        @school = School.find_by_name(params[:school_name])
				if @school
					redirect_to :action=>:contact_signup,:school_id=>@school.id
				else
					redirect_to :action=>:contact_signup,:school_name=>params[:school_name]
				end
      end
    else
			redirect_to :action=>:contact_signup
		end

  end

	def go_to_school
    search = params[:organization][:name] if params[:organization][:name]
    search = params[:school_name] if params[:school_name]
    
		if search
			@organization = Organization.find_by_name_or_school_name(search)
			if  @organization
				redirect_to organization_path(@organization)
			else
				@school = School.find_by_name(search)
				if @school
					redirect_to :action=>:contact_signup,:school_id=>@school.id
				else
					redirect_to :action=>:contact_signup,:school_name=>search
				end
			end
		else
			redirect_to :action=>:contact_signup
		end
	end

	def add_to_contact_alerts
		@contact_alert = ContactAlert.new(params[:contact_alert])
		if @contact_alert.save
			redirect_to :action => params[:go_to]
		else
			render :action => :contact_signup
		end
	end

	def email_unregister    
    @organization = Campaign.find(params[:campaign_id]).organization    
	end

	def remove_from_location
		contact = Contact.find_by_email_address(params[:email])
    organization = Campaign.find(params[:campaign_id]).organization
		case params[:unregister]
		when "campaign"
			if a_user = User.find_by_email(params[:email])
				a_user.campaign_users.each do |campaign_user|
					campaign_user.remove_from_contact if campaign_user.campaign_id == params[:campaign_id].to_i
				end
			end
			user_contact = UserContact.find(:first, :conditions=>["campaign_id = ? AND contact_id = ?", params[:campaign_id], contact.id])
			user_contact.unsubscribe!
			flash[:notice] = "You have been unsubscribed from this Fundraising Page"
    when "organization"     
      
      organization.active_campaigns.each do |campaign|
        if a_user = User.find_by_email(params[:email])
          a_user.campaign_users.each do |campaign_user|
            campaign_user.remove_from_contact if campaign_user.campaign_id == campaign.id.to_i
          end
        end
        puts campaign.id
        puts contact.id
        user_contact = UserContact.find(:first, :conditions=>["campaign_id = ? AND contact_id = ?", campaign.id, contact.id])
        puts user_contact
        if user_contact
          puts "unsubscribe for this campaign ======>>>>#{campaign.id}======>>>>#{campaign.name}"
          user_contact.unsubscribe!
        end
      end

      unless UnsubscribeOrganization.find_by_email_and_organization_id(params[:email],organization.id)
        UnsubscribeOrganization.new(:organization_id=>organization.id , :email=>params[:email]).save
      end
      
			flash[:notice] = "You have been unsubscribed from all campaigns of #{organization.name} in AlumniFidelity"
      
		when "solicitation"
			contact.update_attributes(:subscribed=>Contact::UNSUBSCRIBED )
			if a_user = User.find_by_email(params[:email])
				a_user.campaign_users.each do |campaign_user|
					campaign_user.remove_from_contact
				end
			end
			flash[:notice] = "You have been unsubscribed from all campaigns of mentioned organization in AlumniFidelity"
		when "all"
			if a_user = User.find_by_email(params[:email])
				a_user.update_attributes(:do_not_contact=>true)
			end
			contact.update_attributes(:subscribed=>Contact::UNSUBSCRIBED )
			a_user.campaign_users.each do |campaign_user|
				campaign_user.remove_from_contact
			end
			flash[:notice] = "You have been unsubscribed from all emails from AlumniFidelity"
		end if contact
		redirect_to ""
	end

	def contact_signup
		@contact_alert = ContactAlert.new
		@contact_alert.school_name = params[:school_name] || ""
		if params[:school_id]
			@contact_alert.school_id = params[:school_id]
		end
		@contact_alert.as_org = params[:as_org] || "0"
	end

	def terms
		render :layout => true
	end
	
	def services
		render :layout => true
	end
end
