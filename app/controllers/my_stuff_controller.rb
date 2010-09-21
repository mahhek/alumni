class MyStuffController < ApplicationController

	helper PhotosHelper

	before_filter :login_required
	before_filter :set_user	

    def member_requests
		@user = logged_in_user
		@campaigns = @user.owned_campaigns.alive
	end

	def approve_member_request
		@cu=CampaignUser.find(params[:campaign_user_id])
		@cu.update_attributes(:status=>CampaignUser::MEMBER)
		redirect_to :action=>'member_requests'
	end

	def remove_member
		@cu=CampaignUser.find(params[:campaign_user_id])
		@cu.update_attributes(:status=>params[:status])
		redirect_to :action=>'member_requests'
	end

	def remove_member_by_user
		@cu=CampaignUser.find(:all, :conditions=>["user_id=? and campaign_id=? and status != #{CampaignUser::OWNER} ",params[:user_id], params[:campaign_id] ])
		@cu.each do |campaign|
			campaign.update_attributes(:status=>params[:status])
		end
		redirect_to :action=>'member_requests'
	end

private

	def set_user
		@user = logged_in_user
	end
	
	def set_content_counts
		
	end
	
end
