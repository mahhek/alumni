class PromotionController < ApplicationController
	helper CampaignsHelper

	def new
		@campaign = Campaign.find(params[:campaign_id])
		@campaign.initiated(:launch)
		@user = logged_in_user
		set_site_branding_from_campaign
	end

	def manage_contacts
		@campaign = Campaign.find(params[:campaign_id])
		@user = logged_in_user
		@type = params[:type] || "Prospects"
		set_site_branding_from_campaign
		case @type
			when "Prospects"
				@contacts = @user.contacts_for_campaign(@campaign, UserContact::PROSPECT)
			when "Contributors"
				@contacts = @user.contacts_for_campaign(@campaign, UserContact::DONOR)
			when "Thanked"
				@contacts = @user.contacts_for_campaign(@campaign, UserContact::THANKED)
			when "All"
				@contacts = @user.all_contacts_for_campaign(@campaign)
				@contacts = @contacts.sort_by{ |c| c.contact.email_address }
		end
		
	end
	
	def shared
		@campaign = Campaign.find(params[:campaign_id])
		@contacts = @campaign.active_shared_contacts
		@type = "Shared"
	end
	
	def send_shared
		contact_list = []
		params[:contacts].each do |cid|
			contact = SharedContact.find(cid)
			contact_list << contact.email
			contact.update_attribute(:accepted, true)
		end
		params[:to] = contact_list.join(",")
		send_promotion
	end

	def send_promotion

    puts params[:to]
		@user = logged_in_user
		@campaign = Campaign.find(params[:campaign_id])    
		if @user
			contacts_list = @campaign.align_contacts_with(params[:to], @user)
      puts "contacts_list==>>#{contacts_list}"
			if contacts_list.empty?
				flash[:error] = "Please add at least one recipient before sending."
				redirect_to "/promotion/new?campaign_id=#{params[:campaign_id]}"
				return false
			end
			flash[:notice] = flash_msg "Your Appeal has been sent.", "Check <a href='/promotion/manage_contacts?campaign_id=#{@campaign.id}'>Manage Appeals</a> to see the status."
		else
			if params[:message][:from_email].blank?
				redirect_to "/promotion/new?campaign_id=#{params[:campaign_id]}"
				flash[:error] = "Your email can not be blank."
				return false
			elsif params[:message][:from_name].blank?
				redirect_to "/promotion/new?campaign_id=#{params[:campaign_id]}"
				flash[:error] = "Your name can not be blank."
				return false
			end
			contacts_list = params[:to].split(/;|,|\n/)
      
			flash[:notice] = "Your Appeal has been sent."
		end
    contacts_list.each do |user_contact|
      puts "<<<<<****************>>>>>>#{user_contact.contact_id.inspect}"
    end
		@campaign.promote_to([], contacts_list, request, @campaign , params.dup)
		
		if @campaign.is_owner?(@user) && @campaign.initiated(:promote)
			redirect_to "/dcc/pay?campaign_id=#{@campaign.id}"
		else
			redirect_to campaign_url(@campaign)
		end
	end

	def send_nudge
		@campaign = Campaign.find(params[:campaign_id])
		if params[:contacts].to_a.empty?
			flash[:error] = "You must choose someone to nudge"
		else
			@campaign.send_contact(request, params.dup)
			flash[:notice] = "A nudge has been sent for this fundraising page"
		end
		redirect_to "/promotion/manage_contacts?campaign_id=#{@campaign.id}"
	end

	def send_thanks
		@campaign = Campaign.find(params[:campaign_id])
		if params[:contacts].to_a.empty?
			flash[:error] = "You must choose someone to thank"
		else
			@campaign.send_thanks(request, params.dup)
			flash[:notice] = "A thank you has been sent."
		end
		redirect_to "/promotion/manage_contacts?campaign_id=#{@campaign.id}&type=Thanked"
	end

	def send_contact
		@campaign = Campaign.find(params[:campaign_id])
		if params[:contacts].to_a.empty?
			flash[:error] = "You must choose someone to contact"
		else
			@campaign.send_contact(request, params.dup)
			flash[:notice] = "Your contact has been made successfully"
		end
		redirect_to "/promotion/manage_contacts?campaign_id=#{@campaign.id}&type=All"
	end

	def import_contacts
		@campaign = Campaign.find(params[:campaign_id])
		@campaign_list = logged_in_user.owned_campaigns.delete_if{|item| item.id == @campaign.id}
		@user = logged_in_user
	end

	def create_contacts
		@campaign = Campaign.find(params[:campaign_id])
		@user = logged_in_user
		@campaign.align_contacts_with(params[:to], @user)
		redirect_to :action=>:manage_contacts,:campaign_id=>@campaign.id
	end

	def delete_contact
		campaign_contact = CampaignContact.find(params[:campaign_contact_id])
		campaign_id = campaign_contact.campaign_id
		campaign_contact.destroy
		redirect_to :action=>:manage_contacts,:campaign_id=>campaign_id
	end

end
