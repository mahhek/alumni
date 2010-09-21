class UserContact < ActiveRecord::Base
	belongs_to :campaign
	belongs_to :contact
	PROSPECT = 1
	THANKED = 2
	DONOR=3
	stampable
	STATUS_TEXT = {1=>"Prospect", 2=>"Thanked", 3=>"Donor"}
	
	def initialize(attributes = {})
		super(attributes)
		self.last_contacted = Time.now
	end
	
	def status_text
		return "Unsubscribed" if self.subscribed == CampaignContact::UNSUBSCRIBED
		return STATUS_TEXT[self.status]
	end
	
	def donate!
		update_attribute(:status, UserContact::DONOR) if status == UserContact::PROSPECT
	end
	
	def mark_as_contacted
		update_attribute(:last_contacted, Time.now)
	end
	
	def payment
		Payment.find_by_user_contact(self)
	end
	
	def unsubscribe!
		UserContact.update_all("subscribed = #{CampaignContact::UNSUBSCRIBED}", ["contact_id=? and campaign_id=?", self.contact_id, self.campaign_id])
	end
	
end
