require 'faster_csv.rb'
class OrganizationsController < ApplicationController

 
	
	helper :form_table, :paginate, :managed_form
	
	before_filter :organization_login_required,
		:except => [:index, :show, :search, :search_with_sort]
  before_filter :organization_admin_login_required,
		:only => [:manage]

  before_filter :check_administrator_role , :only => [:new]
	def organization_login_required
		login_required(params)
	end

  def organization_admin_login_required
    
    org_from_org_address = OrganizationAddress.find_all_by_url_portion(params[:id])
    unless org_from_org_address.blank?
      org_id = org_from_org_address.first.organization_id
    else
      org_id = params[:id]
    end        
    @organization = Organization.find(org_id)  
    
    unless current_user.is_org_admin_for(@organization)    
			flash[:notice]="You dont have right to access other's organization."
			redirect_to :controller => 'profiles', :action=>'show',
        :other_dest=>url_encode(request.path + '?' +request.query_string )
		end
  end

	def index
		@sort = params[:sort] || "organizations.name asc"
		@search_text = params[:search_text] || ''
		@organizations = Organization.find_by_search_term(@search_text, params[:page], 5, @sort)
		@user = logged_in_user
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @organizations }
		end
	end

	def search_with_sort
		@sort = params[:sort] || "organizations.name asc"
		@search_text = params[:search_text] || ''
		@organizations = Organization.find_by_search_term(@search_text, params[:page], 5, @sort)
		render :partial => "search_results"
	end

  def is_url_exist    
    @organization = OrganizationAddress.find_by_sql("select * from organization_addresses
                                                     where url_portion = '#{params[:url_portion]}'
                                                     AND organization_id != '#{params[:organization_id]}' ;")
    
    if @organization.blank?      
      @isExist = false   # false meanz url is avaliable        
    else      
      @isExist = true    # true meanz url is not avaliable
    end
    
    render :update do|page|            
      page["msg_div"].replace_html :partial=>"is_url_exist"
    end
  end

	def upload_image
		@user = logged_in_user
		@organization = Organization.find(params[:organization_id])
		@photo = @organization.main_photo || OrganizationPhoto.new
		set_site_branding_from_org
	end
	
	def remove_image
		@organization = Organization.find(params[:organization_id])
		@organization.organization_photos.each do |i| i.destroy end
		redirect_to :action => :upload_image, :organization_id => params[:organization_id]
	end

	def create_org_photo
		@user = logged_in_user
		@photo = OrganizationPhoto.new(params[:photo])
		@organization = Organization.find(params[:organization_id])
		if @photo.save
			@organization.organization_photos.each do |i| i.destroy end
			@organization.organization_photos << @photo
			@organization.save
			flash[:notice] = 'Your profile picture has been updated.'
		else
			flash[:notice] = 'You must choose a file to upload.'
		end
		redirect_to :action => :upload_image, :organization_id => params[:organization_id]
	end

	def statistics
    
		if params[:id] == "all"
			@all = true
			@campaigns = Campaign.find(:all)
		else
      
			@all = false
			@organization = Organization.find(params[:id])
			if params[:campaign_id]
				@campaigns = [@organization.campaigns.find(params[:campaign_id])]
			else        
				@campaigns = Campaign.find(:all, :conditions => { :organization_id => @organization.id },
          :include => :payments,
          :order => "campaigns.name asc")
        
			end
			set_site_branding_from_org
		end
    
		respond_to do |format|
			format.html #
			format.csv { statistics_as_csv }
		end
	end

	# GET /organizations/1
	# GET /organizations/1.xml
	def show
		@user = logged_in_user
    org_from_org_address = OrganizationAddress.find_all_by_url_portion(params[:id])
    unless org_from_org_address.blank?
      
      org_id = org_from_org_address.first.organization_id
    else
      
      org_id = params[:id]
    end
		@organization = Organization.find(org_id)
		@org_user = @organization.org_user
		@campaigns = @organization.campaigns.active.visible_to_all.sort_by { |e| -e.currentAmount.to_i }
		@class_years = @organization.top_class_years
		set_site_branding_from_org
		
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @organization }
		end
	end

	# GET /organizations/new
	# GET /organizations/new.xml
	def new
		#if params[:from_registration]
		#	@organization = Organization.new_from_registration(params[:from_registration])
		#	@organization_address = OrganizationAddress.new_from_registration(params[:from_registration])
		#else
    @organization = Organization.new
    @organization_address = OrganizationAddress.new
		#end
		@paypal_credential = PaypalCredential.new
		@show_bg_disabled = @show_logo_disabled = false
		
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @organization }
		end
	end

	# GET /organizations/1/edit
	def edit
		@user = logged_in_user  
		@organization = Organization.find(params[:id])
		@fund_raiser = FundRaiser.new
		@organization_address = @organization.main_address
		@paypal_credential  = @organization.main_credential
		@fund_raisers = FundRaiser.find(:all,:conditions=>["organization_id=?", @organization.id] )
		@show_bg_disabled = @organization.disable_background_color? && !@user.has_role?('Administrator')
		@show_logo_disabled = @organization.disable_branded_logo? && !@user.has_role?('Administrator')
		
		set_site_branding_from_org
	end
	
	def manage
		@user = logged_in_user  
		@is_admin = @user.has_role?('Administrator')
    org_from_org_address = OrganizationAddress.find_all_by_url_portion(params[:id])
    unless org_from_org_address.blank?
      
      org_id = org_from_org_address.first.organization_id
    else
      
      org_id = params[:id]
    end   
    
    @organization = Organization.find(org_id)
		@fund_raiser = FundRaiser.new
		@organization_address = @organization.main_address
		@paypal_credential  = @organization.main_credential
		@authorize_credential  = @organization.authorize_credential
		@fund_raisers = FundRaiser.find(:all,:conditions=>["organization_id=?", @organization.id] )
		@show_bg_disabled = @organization.disable_background_color? && !@is_admin
		@show_logo_disabled = @organization.disable_branded_logo? && !@is_admin
		@show_class_year_disabled = !(@organization.show_class_year? || @is_admin)		
		@donation_options = @organization.donation_options		
		set_site_branding_from_org
	end
	
	def has_paypal?
		params[:organization] && params[:organization][:add_paypal_account] == "1"
	end

	def create
    
		@organization = Organization.new(params[:organization])
		@organization.name = @organization.school.name if @organization.school and @organization.name.blank?
		@organization_address = OrganizationAddress.new(params[:organization_address])
		@paypal_credential = PaypalCredential.new(params[:paypal_credential]) if has_paypal?
		respond_to do |format|
			if !@organization.valid? || !@organization_address.valid? || (has_paypal? && !@paypal_credential.valid?)
				format.html { render :action => "new" }
				format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
			else
				@organization.save
				@organization.organization_addresses << @organization_address
				@organization.paypal_credentials << @paypal_credential if has_paypal?
				@organization.fund_raisers << FundRaiser.create!(:name=>'Default')
				if params[:photo] && !params[:photo][:uploaded_data].blank?
					photo = BrandedLogo.new(params[:photo])
					if !photo.filename.blank? && photo.save
						@organization.branded_logo = photo
					end
				end
				
				@organization.save!
				flash[:notice] = 'Organization was successfully created.'
				format.html { redirect_to(@organization) }
				format.xml  { render :xml => @organization, :status => :created, :location => @organization }

			end
		end
	end

	# PUT /organizations/1
	# PUT /organizations/1.xml
	def update    
		@user = logged_in_user
		@organization = Organization.find(params[:id])		
		success = false		
		if params[:organization_address]            
      organization_address = OrganizationAddress.find_by_url_portion(params[:organization_address][:url_portion])
      if organization_address.nil?
        org_address = OrganizationAddress.new(params[:organization_address])
        success = @organization.save if (@organization.organization_addresses << org_address if org_address.valid?)
      else      
        success = organization_address.update_attribute("created_at", DateTime.now)
      end		
		elsif params[:paypal_credential]
			success = @organization.update_paypal_credentials(params[:paypal_credential])
		elsif params[:authorize_credential]
      success = @organization.update_authorize_credentials(params[:authorize_credential])      
		elsif params[:organization]
			org_opts = params[:organization]
			org_opts[:background_color] = params["yui-picker-hex"] if params["yui-picker-hex"]
      if params[:organization][:branded_logo_directs_to] && params[:organization][:branded_logo_directs_to].chars[0..4] != "http:"
        params[:organization][:branded_logo_directs_to] = "http://"+params[:organization][:branded_logo_directs_to].to_s
      end      
			success = @organization.update_attributes(org_opts)      
      
		elsif params[:donation_options]
			if params[:donation_options][:categories_switch] != "true" || params[:donation_options][:amount].nil?
				success = @organization.update_attributes(:multiple_choice_donations => nil)
			else
				if params[:donation_options][:named_categories] != "true"
					amounts = params[:donation_options][:amount].map(&:to_f).select{ |i| i > 0 }.sort
					success = @organization.update_attributes(:multiple_choice_donations => amounts)
				else
					cats = {}
					params[:donation_options][:amount].each_with_index do |a, i|
						amt = a.gsub(/[^(\d|.|,)]/, "").to_f
						cats[amt] = params[:donation_options][:category][i].to_s if amt > 0
					end
					success = @organization.update_attributes(:multiple_choice_donations => cats)
				end
			end
		end
		
    

		if params[:photo] && !params[:photo][:uploaded_data].blank?
			photo = BrandedLogo.new(params[:photo])
			if !photo.filename.blank? && photo.save
				@organization.branded_logo = photo
			end
			success = @organization.save
		end



    if @organization.organization_addresses.first.url_portion.nil? || @organization.organization_addresses.first.url_portion == ""
      url_id = @organization.id      
    else
      url_id = @organization.organization_addresses.first.url_portion      
    end

		
		
		if success
      if @organization.who_will_choose_fund == "the_donors" || @organization.who_will_choose_fund == "all_gifts_will_be_unrestritced"        
        set_default_fund_against_all_campaigns_of_current_organization()        
      end
			flash[:notice] = 'Organization was successfully updated.'
			redirect_to :action=>"show" , :id => url_id
		else
			flash[:notice] = "There was a problem."
			redirect_to :action => "manage", :id => url_id
		end
	end

  # TODO Comment
  def set_default_fund_against_all_campaigns_of_current_organization()
    fund_raiser_obj_for_default_fund = nil    
    @organization.fund_raisers.each do|organization_fund_raiser|      
      if organization_fund_raiser.name.downcase == "default"
        fund_raiser_obj_for_default_fund = organization_fund_raiser        
      end
    end
    @organization.active_campaigns.each do|campaign|
      unless campaign.fund_raisers.include?(fund_raiser_obj_for_default_fund)
        campaign.fund_raisers << fund_raiser_obj_for_default_fund
      end
    end
  end
	
	# DELETE /organizations/1
	# DELETE /organizations/1.xml
	def destroy
		@user = logged_in_user
		@organization = Organization.find(params[:id])
		@organization.destroy

		respond_to do |format|
			format.html { redirect_to(organizations_url) }
			format.xml  { head :ok }
		end
	end

	def search
		orgs = Organization.find_by_partial_name(params[:search_term], :limit=>10)
		schools = School.find_by_partial_name(params[:search_term], :limit=>10)
		
		used_school_ids = orgs.map(&:school_id).compact
		schools.delete_if{ |s| used_school_ids.include?(s.id) }
		
		@orgs_and_schools = orgs + schools
    @orgs_and_schools.sort { |a,b| a.name <=> b.name }
		render :layout=>false
	end
	
	def list_all
		@user = logged_in_user

		if !@user.has_role?('Administrator')
			redirect_to "/"
			return false
		end
		
		@org_list = Organization.find(:all)
		
		case params[:sort]
		when "status"
			@org_list = @org_list.sort_by{ |c| c.status }
		when "name"
			@org_list = @org_list.sort_by{ |c| c.name }
		else
			@org_list = @org_list.sort_by{ |c| c.id }
		end
		
		@org_list.reverse! if params[:order] == "asc"
		
		per_page = 20
		
		@total_pages = ((@org_list.size - 1) / per_page) + 1

		page = params[:page].to_i
		if page <= 0 || page > @total_pages
			@page =  1
		else
			@page = page
		end
		@page = @page.to_i

		@org_list = @org_list.slice( (per_page * (@page - 1) ) , per_page)

	end
	
	def activate
		@organization = Organization.find(params[:id])
		@organization.activate!
		redirect_to :action => "list_all"
	end
	
	def contacts
		@organization = Organization.find(params[:id])
		@sheets = ContactSpreadsheet.find_all_by_organization_id(params[:id])
	end
	
	def contact_sheet
		@organization = Organization.find(params[:id])
		@sheet = ContactSpreadsheet.find(params[:sheet_id])
	end
	
	def add_contacts
		if params[:spreadsheet] && !params[:spreadsheet][:uploaded_data].blank?
			params[:spreadsheet][:organization_id] ||= params[:id]
			ContactSpreadsheet.create(params[:spreadsheet]).build!
			redirect_to "/organizations/contacts/#{params[:id]}"
		end
	end
	
	def send_contacts
		params[:contacts].each do |cid|
			contact = SharedContact.find(cid)
			if !contact.accepted?
				contact.update_attribute(:campaign_id, params[:campaign])
			end
		end
		
		redirect_to "/organizations/contact_sheet/#{params[:id]}?sheet_id=#{params[:sheet_id]}"
	end
	
	private

	def stream_csv(filename)
		#this is required if you want this to work with IE
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
			headers["Content-type"] = "text/plain"
			headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
			headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
			headers['Expires'] = "0"
		else
      headers["Content-Type"] ||= 'text/csv'
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""      
		end
		render :text => Proc.new { |response, output|
			csv = FasterCSV.new(output, :row_sep => "\r\n") 
			yield csv
		}
	end
	
	def init_row(c)
		(@all) ? [c.organization.name] : []
	end

	
	def statistics_as_csv    
		if @all
			filename = 'all_organizations.csv'
		else
			filename = @organization.name.downcase.gsub(/[^0-9a-z]/, "_") + ".csv"
		end
		
		stream_csv(filename) do |csv|

      
			if @campaigns.size > 0
          if @campaigns.first.organization.name == 'The University of Oklahoma'
            header_row = %W(Date Fundraising_Page_Owner Fundraising_Page OU_alum Degree Year_of_Graduation Class_Year First_Name Last_Name Email Address_1 Address_2 City State Zip Phone Amount Fund Activity Contact? Offline? Comment Matched? Company_Name Address_1 Address_2 City State Zip Phone)
          else
            header_row = %W(Date Fundraising_Page_Owner Fundraising_Page Class_Year First_Name Last_Name Email Address_1 Address_2 City State Zip Phone Amount Fund Activity Contact? Offline? Comment Matched? Company_Name Address_1 Address_2 City State Zip Phone)
          end
      else
          header_row = %W(Date Fundraising_Page_Owner Fundraising_Page Class_Year First_Name Last_Name Email Address_1 Address_2 City State Zip Phone Amount Fund Activity Contact? Offline? Comment Matched? Company_Name Address_1 Address_2 City State Zip Phone)
      end
      header_row.unshift("Organization") if @all
      
      
			csv << header_row
			@campaigns.each do |campaign|

  			fundraiser = campaign.fund_raiser.nil? ? "" : (campaign.fund_raiser.name.nil? ? "" :campaign.fund_raiser.name.strip)
        user = campaign.creator
        row = init_row(campaign)
        row << campaign.created_at
				row << user.email
				row << campaign.name
				row << campaign.class_year.to_s
				row << user.first_name
				row << user.last_name
				row << user.email
				row << "" << "" << "" << "" << "" << "" << ""
				row << fundraiser
				row << "Created"
				row << (campaign.can_contact? ? "Yes" : "No")
				row << "" << "" << "" << "" << "" << "" << "" << "" << "" << ""
				
				csv << row			
        
				campaign.payments.each do |payment|          
					
					row = init_row(campaign)
				
					row << payment.created_at
					row << user.email
					row << campaign.name
           if campaign.organization.name == 'The University of Oklahoma'
            row << payment.ou_alum
            row << payment.degree
            row << payment.graduation_year
           end
					row << campaign.class_year.to_s
					row << payment.first_name
					row << payment.last_name
					row << payment.email
					row << payment.address1
					row << payment.address2
					row << payment.city
					row << payment.state
					row << payment.zip
					row << payment.phone
         
					row << "%8.2f" % payment.amount                    
          
          fund_raiser_object = FundRaiser.find_by_id(payment.campaign.fund_raiser_id)
					row << (payment.fund_raiser.nil? ? (fund_raiser_object.nil? ? "" : fund_raiser_object.name) : payment.fund_raiser.name)
          
					row << "Donated"
					row << (payment.ok_to_send? ? "Yes" : "No")
					row << (payment.offline? ? "Yes" : "No")
					row << payment.comment
					
					if payment.matched?
						row << "Yes"
						row << payment.matched_name
						row << payment.matched_addr1
						row << payment.matched_addr2
						row << payment.matched_city
						row << payment.matched_state
						row << payment.matched_zip
						row << payment.matched_phone
					else
						row << "No" << "" << "" << "" << "" << "" << "" << ""
					end
					
					csv << row
				end
				
				campaign.campaign_users.to_a.find_all(&:include_in_download?).each do |campaign_user|
				
					user = campaign_user.user
					
					row = init_row(campaign)
					
					row << ""
					row << user.email
					row << campaign.name
					row << campaign.class_year.to_s
					row << user.first_name
					row << user.last_name
					row << user.email
					row << "" << "" << "" << "" << "" << "" << ""
					row << fundraiser
					row << campaign_user.status_as_string
					row << "" << "" << "" << "" << "" << "" << "" << "" << "" << "" << ""
					
					csv << row
				end
				
				all_comments = Comment.find(:all, 
					:conditions => ["comments.campaign_id = ? and users.ok_to_send = ?", campaign.id, true], 
					:group => "comments.creator_id", 
					:order => "comments.created_at desc",
					:include => :creator).map{ |c| [c, c.creator] }
				
				all_comments.each do |comment, user|
					
					row = init_row(campaign)
					
					row << comment.created_at
					row << user.email
					row << campaign.name
					row << campaign.class_year.to_s
					row << user.first_name
					row << user.last_name
					row << user.email
					row << "" << "" << "" << "" << "" << "" << ""
					row << fundraiser
					row << "Commented"
					row << "" << ""
					row << comment.text
					row << "" << "" << "" << "" << "" << "" << "" << ""
					
					csv << row
				end
				
			end
		end
	end
	
end
