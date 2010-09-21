class CampaignsController < ApplicationController
	
	helper :application, :paginate, :form_table
	before_filter :campaign_login_required, :except => [:index, :show, :disabled, :search_with_sort]
	before_filter :set_campaign, :only => [:campaign_stickers, :upload_video, :upload_image, :select_main]
  
	def campaign_stickers
		@is_campaign_creator = (logged_in_user.id == @campaign.creator_id)
		@user = logged_in_user
		@stickers = Bumpersticker.find(:all,:conditions=>["campaign_id=?",@campaign.id])
		@organization = @campaign.organization
		@sticker_setup = @organization.sticker_attributes
		set_site_branding_from_org
		if @stickers.empty? && (@sticker_setup.size == 1)
			redirect_to "/sticker_attributes/sticker_creater/#{@sticker_setup.first.id}?campaign_id=#{@campaign.id}"
			return false
		end
	end

	def check_available
		@campaign = Campaign.find(:first,:conditions=>["name = ? or friendly_url = ?",params[:url],params[:url]])
		if @campaign
			render :update do |page|
				page.replace_html 'unavailable', 'Not Available'
				page.replace_html 'available','&nbsp;'
			end
		else
			render :update do |page|
				page.replace_html 'available', 'Available'
				page.replace_html 'unavailable', '&nbsp;'
			end
		end
	end

  def see_more_funds
    selected_funds = Campaign.find(params[:campaign_id]).fund_raisers
    funds = FundRaiser.find_all_by_organization_id(params[:id])
    optional_funds = funds - selected_funds
    puts "====#{selected_funds.size}"
    puts "====#{funds.size}"
    puts "====#{optional_funds.size}"
    render :update do |page|        
        page.replace_html 'optional_div' , :partial=>"funds_against_campaign" , :locals=>{:funds=>optional_funds}
        page['optional_div'].show
        page['optional_heading_div'].show
        page['see_more_funds_div'].hide
    end
  end
	
	def suggest_url
		suggested_url = params[:url].to_s.gsub(/[^a-zA-Z0-9]+/,'')
		if !Campaign.is_url_available?(suggested_url)
			25.times do |i|
				new_url = suggested_url + (i+1).to_s
				if Campaign.is_url_available?(new_url)
					suggested_url = new_url
					break
				end
			end
		end
		render :text=>suggested_url
	end

	def index
    
		@sort = params[:sort] || "campaigns.name asc"
		@search_text = params[:search_text] || ''
		@campaigns = Campaign.find_by_search_term(@search_text, params[:page], 5, @sort)
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @campaigns }
		end
	end

	def search_with_sort
   puts "1"
		@sort = params[:sort] || "campaigns.name asc"
		@search_text = params[:search_text] || ''
		@campaigns = Campaign.find_by_search_term(@search_text, params[:page], 5, @sort)
		render :partial => 'search_results'
	end

	def upload_video
		@user = logged_in_user
		@campaign = Campaign.find(params[:campaign_id])
		set_site_branding_from_campaign
		#@campaign.embedded_video = ""
	end

	def upload_image
		@user = logged_in_user
		set_site_branding_from_campaign
		@photo = @campaign.main_photo || CampaignPhoto.new
	end

	def select_main
		if params[:main_photo]
			@campaign = Campaign.find(params[:campaign_id])
			@campaign.set_as_main_photo(params[:main_photo])
			flash[:notice] = 'You have successfully changed your main photo.'
			#redirect_to  @campaign
			redirect_to :action => :upload_image, :campaign_id => @campaign.id
		else
			flash[:notice] = 'Could not make changes.'
			redirect_to :action => :upload_image,:campaign_id=>@campaign.id
		end
	end

	def create_camp_photo
		@user = logged_in_user
		@photo = CampaignPhoto.new(params[:photo])
		@campaign = Campaign.find(params[:campaign_id])
		set_site_branding_from_campaign
		# if no filename, skip any other errors
		if  @photo.filename.blank?
			flash[:notice] = 'Please select a photo to upload'
		elsif @photo.save
			@campaign.campaign_photos << @photo
			@campaign.save
			@campaign.set_as_main_photo(@photo.id) if @campaign.campaign_photos.size == 1
			flash[:notice] = 'Your picture has been added.'
		else
			flash[:notice] = 'An error occurred with your upload'
		end
		render :action => :upload_image
	end

	def report_campaign

	end

	def report_form

	end

	def contact_me
		if !logged_in_user.campaign_ids.include?(params[:id].to_i)
			CampaignUser.create(
				:user => logged_in_user, 
				:campaign_id => params[:id],
				:ok_to_send => true,
				:status => CampaignUser::NOTIFIABLE
			)
		end

		flash[:notice] = flash_msg "#{Campaign.find(params[:id]).name} has been added to your Notifications page", "Your Notifications page is a part of your Dashboard.  You can choose your notification settings below."
		redirect_to :controller => 'user_broadcasts', :action => 'edit', :id => params[:id]
	end

	# GET /campaigns/1
	# GET /campaigns/1.xml
	def show
		@campaign = Campaign.find_by_friendly_url(CGI::unescape(params[:id]))
		@campaign = Campaign.find_by_name(CGI::unescape(params[:id])) unless @campaign
		@campaign = Campaign.find_by_id(CGI::unescape(params[:id])) unless @campaign
		
		if @campaign.nil?
			redirect_to "/404.html"
			return false
		end
		
		session[:campaign_id] = @campaign.id
		@campaign_flag = CampaignFlag.new
		@organization = @campaign.organization
		@donor_wall_list = @campaign.get_donors(6)
		@questions = @campaign.creator.user_attribute_details
		@user = logged_in_user

		if @user
			set_admin
		end

		if redirect_due_to_campaign_status
			return false
		end
		
		@is_bot = detect_bot
		
		@comment_lists = @campaign.get_comments(6)
		@comment = Comment.new
		
		@photos = @campaign.campaign_photos.to_a.reject{ |i| i == @campaign.main_photo }
		
		set_site_branding_from_org
		
		respond_to do |format|
			format.html  # show.html.erb
			format.xml  { render :xml => @campaign.to_xml(:dasherize=>false,:methods=>[:currentPercent,:currentAmount] )}
		end
	end

	# GET /campaigns/new
	# GET /campaigns/new.xml
	def new
		@campaign = session[:campaign] || Campaign.new(:public=>true, :organization_id=>params[:organization_id])
		session[:campaign] = nil
		@funds = []
		
		if @selected_org = Organization.find_by_id(@campaign.organization_id)
			@funds = FundRaiser.find(:all,:conditions=>["organization_id=?",@selected_org.id])
			@campaign.campaign_text = @selected_org.campaign_pitch
			set_site_branding(@selected_org)
		end
		
		@organizations = [Organization.new({:name=>'Choose One'})]
		@organizations += Organization.find(:all,:conditions=>["status=?",Organization::STATUS.index("Active") ])
		
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @campaign }
		end
	end

	# GET /campaigns/1/edit
	def edit
		@user = logged_in_user
		@campaign = Campaign.find(params[:id])
		@organization = @campaign.organization
		set_admin
		set_site_branding_from_campaign
		@fund_raisers = @organization.fund_raisers
    @funds = FundRaiser.find(:all,:conditions=>["organization_id=?",@organization.id])
	end

	def advanced
		@user = logged_in_user
		@campaign = Campaign.find(params[:campaign_id])
		set_site_branding_from_campaign
		@fund_raisers = @campaign.organization.fund_raisers
	end

	# POST /campaigns
	# POST /campaigns.xml
	def create
		@campaign = Campaign.new(params[:campaign])
#    puts "====>>>>>>>>>>>>>>>>>>>>>>>>>#{params[:campaign][:organization_id]}"
#    puts "====>>>>>>>>>>>>>>>>>>>>>>>>>#{params[:fund_railser_id].inspect}"
#    puts "====>>>>>>>>>>>>>>>>>>>>>>>>>#{params[:fund_railser_ids].inspect}"
#    puts "====>>>>>>>>>>>>>>>>>>>>>>>>>#{params[:preferred_id].inspect}"
#
#    puts "====>>>>>>>>>>>>>>>>>>>>>>>>>#{@campaign.fund_raisers.inspect}"


    
#    code added by hamid
    @campaign_list = Campaign.find_all_by_organization_id(params[:campaign][:organization_id])
    unless @campaign_list.blank?
      @campaign.is_spread = @campaign_list.first.is_spread
      @campaign.is_start  = @campaign_list.first.is_start
      @campaign.is_donate = @campaign_list.first.is_donate
    end
    
#   -end-
	
		if params[:photo] && !params[:photo][:uploaded_data].blank?
			photo = CampaignPhoto.new(params[:photo])
			if !photo.filename.blank? && photo.save
				session[:photo] = photo
			end
		end
	
    
    
		if @campaign.save
      
        @campaign.fund_raiser_ids = params[:fund_raiser_ids]
			if session[:photo]
				@campaign.campaign_photos << session[:photo]
				@campaign.save
				@campaign.set_as_main_photo(session[:photo].id)
			end
			
			CampaignUser.create_owner(@campaign)
			
			if org_user = @campaign.organization.org_user
        begin
          Notification.deliver_new_campaign_page_created(@campaign, org_user.email)
        rescue Exception=>e
        end

        UserBroadcast.turn_on_for(org_user, @campaign)
			end
			
			session[:campaign] = nil
			session[:photo] = nil
			
			redirect_to "/#{@campaign.url}.html"
		else
			session[:campaign] = @campaign
			redirect_to :action => "new"
		end
	end

	# PUT /campaigns/1
	# PUT /campaigns/1.xml
	def update
		@campaign = Campaign.find(params[:id])

		respond_to do |format|
			if @campaign.update_attributes(params[:campaign])
        @campaign.fund_raiser_ids = params[:fund_raiser_ids]
        if params[:photo] && !params[:photo][:uploaded_data].blank?
					photo = CampaignPhoto.new(params[:photo])
					if !photo.filename.blank? && photo.save
						@campaign.campaign_photos << photo
						@campaign.save
						@campaign.set_as_main_photo(photo.id)
					end
				end
				flash[:notice] = 'Fundraising Page was successfully updated.'
				format.html { redirect_to(@campaign) }
				format.xml  { head :ok }
			else
				@fund_raisers = @campaign.organization.fund_raisers
				format.html { render :action => "edit" }
				format.xml  { render :xml => @campaign.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /campaigns/1
	# DELETE /campaigns/1.xml
	def destroy
		@campaign = Campaign.find(params[:id])
		@campaign.fake_delete!
		session[:campaign_id] = nil
		flash[:notice] = "Fundraising Page was successfully deleted."

		if params[:head_back] == "1"
			redirect_to "/campaigns/list_all/?organization_id=#{@campaign.organization_id}"
		else
			redirect_to "/#{@campaign.url}.html"
		end
	end

	def contributors
		@user = logged_in_user
		@campaign = Campaign.find(params[:id])
		@payments = Payment.find_all_by_campaign_id(params[:id])
		set_site_branding_from_campaign
	end

	def toggle_disable
		@campaign = Campaign.find(params[:id])
		@campaign.toggle!(:disabled)
		redirect_to :action => 'show'
	end

	def disabled

	end

	def suspend
		@campaign = Campaign.find(params[:id])
		@user = logged_in_user

		if !@campaign.is_suspended?
			@campaign.suspend!(params[:reason])
			Notification.deliver_campaign_raised(@campaign.organization.org_user.email, @campaign.organization, params[:reason], @campaign) if @campaign.organization.org_user
			Notification.deliver_campaign_raised(Notification::Admins, @campaign.organization, params[:reason], @campaign)
			Message.create(
			:subject=>"A fundraising page for #{@campaign.organization.full_name} has been suspended",
			:message_text=>%|One of the fundraising pages for #{@campaign.organization.full_name} has been suspended for violations of the Terms of Service.
			<br>
			<br>Fundraising Page: <a href="/#{@campaign.url}.html">#{@campaign.name}</a>
			<br>Reason: #{params[:reason]}|,
			:user_ids=>[@campaign.creator_id, @campaign.organization.creator_id])
			flash[:notice] = "Fundraising Page was successfully suspended."
		end
		if params[:head_back] == "1"
			redirect_to "/campaigns/list_all/?organization_id=#{@campaign.organization_id}"
		else
			redirect_to "/#{@campaign.url}.html"
		end
	end

	def unsuspend
		@campaign = Campaign.find(params[:id])
		@user = logged_in_user

		if @campaign.is_suspended?
			@campaign.unsuspend!
			flash[:notice] = "Fundraising Page was successfully taken out of suspension."
		end

		if params[:head_back] == "1"
			redirect_to "/campaigns/list_all/?organization_id=#{@campaign.organization_id}"
		else
			redirect_to "/#{@campaign.url}.html"
		end
	end

	def undelete
		@campaign = Campaign.find(params[:id])
		@user = logged_in_user

		if @campaign.is_deleted?
			@campaign.undelete!
			flash[:notice] = "Fundraising Page was successfully taken out of deletion."
		end

		if params[:head_back] == "1"
			redirect_to "/campaigns/list_all/?organization_id=#{@campaign.organization_id}"
		else
			redirect_to "/#{@campaign.url}.html"
		end
	end
	
	def list_all
		@user = logged_in_user

		if @user.has_role?('Administrator')      
			@campaign_list = Campaign.find(:all)
		elsif @user.has_role?('OrganizationUser')      
			@show_org_menu = true
			set_organization
			org_ids = @user.administrated_organizations.map(&:organization_id).map(&:to_i)
			
			if !org_ids.include? params[:organization_id].to_i
				redirect_to "/"
				return false
			end
			
			@listed_organization = Organization.find(params[:organization_id])
			@campaign_list = Campaign.find(:all, :conditions=>["organization_id = ?", params[:organization_id]])
		else
			redirect_to "/"
			return false
		end
		
		set_site_branding(Organization.find(params[:organization_id])) if params[:organization_id]

		case params[:sort]
		when "status"
			@campaign_list = @campaign_list.sort_by{ |c| c.status }
		when "name"
			@campaign_list = @campaign_list.sort_by{ |c| c.name }
		when "owner"
			@campaign_list = @campaign_list.sort_by{ |c| c.owner.name }
		when "organization"
			@campaign_list = @campaign_list.sort_by{ |c| c.organization_id }
		else
			@campaign_list = @campaign_list.sort_by{ |c| [c.organization_id, c.name] }
		end
		
		@campaign_list.reverse! if params[:order] == "asc"
		
		@total_pages = ((@campaign_list.size - 1) / 10) + 1

		page = params[:page].to_i
		if page <= 0 || page > @total_pages
			@page =  1
		else
			@page = page
		end
		@page = @page.to_i

		@campaign_list = @campaign_list.slice( (10 * (@page - 1) ) , 10)

	end

  def action_buttons
    puts "===========================================#{params[:organization_id]}==="
    @campaign_list = Campaign.find_all_by_organization_id(params[:organization_id])
    @campaign = @campaign_list.first
    puts "!!!!!!!!!!---->#{@campaign_list.inspect}"
    puts "!!!!!!!!!!---->#{@campaign.inspect}"
   
  end

  def change_status
    puts "------------------>#{params[:spread]}"
    puts "------------------>#{params[:start]}"
    puts "------------------>#{params[:donate]}"
    @campaign_list = Campaign.find_all_by_organization_id(params[:organization_id])
    @campaign_list.each do |campaign|
      campaign.update_attributes( :is_spread=>params[:spread] , :is_start=>params[:start] , :is_donate=>params[:donate])
    end
    flash[:notice] = "Status of the action buttons was changed."
    redirect_to :action=>"action_buttons" , :organization_id => params[:organization_id]
  end

  
	def skip_donate
		c = Campaign.find(params[:campaign_id])
		c.initiated(:donate)
		redirect_to "/#{c.url}.html"
	end
	
	def skip_promote
		c = Campaign.find(params[:campaign_id])
		c.initiated(:promote)
		redirect_to "/dcc/pay?campaign_id=#{c.id}"
	end
	
	def finish_initiation
		c = Campaign.find(params[:campaign_id])
		c.initiated(:finish)
		redirect_to "/#{c.url}.html"
	end
	
	def edit_caption
		campaign = Campaign.find(params[:campaign_id])
		photo = CampaignPhoto.find(params[:campaign_photo][:id])
		photo.update_attribute(:caption, params[:campaign_photo][:caption])
		flash[:notice] = "You have successfully changed your photo's caption."
		redirect_to :action => :upload_image, :campaign_id => campaign.id
	end
	
	private
	
	def redirect_due_to_campaign_status
		return false if @campaign.viewable?
		return false if @is_admin
		
		unless @campaign.is_owner?(@user)
			redirect_to "/suspended?org=#{@campaign.organization_id}" if @campaign.is_suspended?
			redirect_to "/deleted" if @campaign.is_deleted?
			return true
		end

		if @campaign.is_suspended?
			@show_why_suspended_message = true
			@suspended_reasons = @campaign.reasons_for_reported.keys
			@suspended_reasons[-1] = "and #{@suspended_reasons.last}" if @suspended_reasons.size > 1
			@suspended_reasons = @suspended_reasons.join ", "
			return false
		else
			redirect_to "/deleted"
			return true
		end
	end
	
	def redirect_due_to_campaign_visibility
		return false if @is_admin
		return false if @campaign.is_member?(@user)
		redirect_to "/404.html"
		return true
	end
	
	def determine_order_by(sort)
		return "created_at desc" if sort.blank?
		column, direction = sort.split(/\w/)
		if Campaign.column_names.include? column
			sort
		else
			"name asc"
		end
	end

	def campaign_login_required
		login_required(params)
	end

	def email_creator
	end
	
	def detect_bot
		crawlers = ["msnbot", "googlebot", "yahooseeker"]
		user_agent_string = request.env['HTTP_USER_AGENT'].to_s.downcase
		crawlers.each do |c|
			return true if user_agent_string.include? c
		end
		return false
	end

	def set_admin
		@is_admin = @user.has_role?('Administrator') || @user.is_org_admin_for(@organization)
	end

  
  
end
