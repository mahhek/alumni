class FlaggedCampaignsController < ApplicationController
     
     before_filter :set_organization, :only=>[:all, :index]
     before_filter :set_campaign, :only=>:new
	 before_filter :set_org_nav, :except => :new

     def index
          flagged_campains_list = FlaggedCampaign.find(:all, :conditions=>["organization_id = ? AND action is NULL", @organization.id], :order=>"created_at DESC")
          @flagged_campaigns = {}
          flagged_campains_list.each do |fc|
               @flagged_campaigns[fc.campaign_id] ||= []
               @flagged_campaigns[fc.campaign_id] << fc
          end

          @suspended_campaigns = CampaignFlag.find(:all, :conditions=>["organization_id = ? AND status = 0", @organization.id])
		set_site_branding_from_org
     end

     def all
          flagged_campains_list = FlaggedCampaign.find(:all, :conditions=>["organization_id = ?", @organization.id], :order=>"created_at DESC")
          @flagged_campaigns = {}
          flagged_campains_list.each do |fc|
               @flagged_campaigns[fc.campaign_id] ||= []
               @flagged_campaigns[fc.campaign_id] << fc
          end
     end

     def new
          #@flagged_campaign = FlaggedCampaign.new
     end

     def create
          @flagged_campaign = FlaggedCampaign.new(params[:flagged_campaign])
          if @flagged_campaign.save
               c = @flagged_campaign.campaign
               flash[:notice] = 'The organization has been notified. Thank you for your time.'
               redirect_to "/#{c.url}.html"
               # Message.create(
               #      :subject=>"A campaign for #{@flagged_campaign.organization.full_name} has been reported",
               #      :message_text=>%|One of the campaigns for #{@flagged_campaign.organization.full_name} has been reported for violations of the Terms of Service.
               #      <br>
               #      <br>Campaign: <a href="/#{c.url}.html">#{c.name}</a>
               #      <br>Reason: #{@flagged_campaign.category}
               #      <br>Notes: #{@flagged_campaign.description}|,
               #      :user_ids=>[@flagged_campaign.organization.creator_id])

          else
               render :action => "new"
          end
     end

     def take_action
          if FlaggedCampaign::ACTIONS.include? params[:admin_action]
               FlaggedCampaign.take_action_on(params[:campaign_id], params[:admin_action])
               if params[:admin_action] == "warned"
                    c = Campaign.find(params[:campaign_id])
                    Message.create(
                         :subject=>"Your campaign for #{c.organization.full_name} has been warned",
                         :message_text=>%|One of the campaigns for #{c.organization.full_name} has been reported for violations of the Terms of Service.  The administrator would like to remind you that if these violations aren't taken care of, your campaign will be suspended.
                         <br>
                         <br>Campaign: <a href="/#{c.url}.html">#{c.name}</a>|,
                         :user_ids=>[c.creator_id])
               end
          end
          redirect_to "/flagged_campaigns?organization_id=#{params[:organization_id]}"
     end

end
