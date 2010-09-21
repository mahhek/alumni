class CampaignContact < ActiveRecord::Base
	INITIAL=0
	NEW=1
	INVITED=2
	DONATED = 3
	THANKED = 4
	JOINED=5
	UNSUBSCRIBED=false
	SUBSCRIBED=true
	STATUS_ARRAY=["Initial","New","Invited","Donated","Thanked","Joined"]
	stampable
	belongs_to :contact
	belongs_to :campaign
	
end
