class FlaggedCampaign < ActiveRecord::Base
	belongs_to :campaign
	belongs_to :organization
	
	ACTIONS = ["warned", "suspended", "none"]
	
	def self.take_action_on(campaign_id, action)
		update_all(["action = ?", action], ["campaign_id = ? AND action is NULL", campaign_id])
	end
	
	def after_create_events
		#org_user = campaign.organization.org_user
		#if org_user.do_not_contact == false
		#    Notification.deliver_campaign_raised(self,org_user)
		#end
	end

	def after_save_events
		#if self.campaign_notified == true
		#	org_user = campaign.organization.org_user
		#    if org_user.do_not_contact == false
		#	    Notification.deliver_notify_owner(self,org_user)
		#    end    
		#end
		#if action=="flag"
		#	campaign.update_attributes(:status=>Campaign::FLAGGED)
		#end
		#if action=="activate"
		#	campaign.update_attributes(:status=>Campaign::ACTIVE)
		#end
	end
end
