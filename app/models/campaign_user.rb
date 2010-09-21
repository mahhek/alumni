class CampaignUser < ActiveRecord::Base

	OWNER = 1
	MEMBER=2
	REQUESTED=3
	FLAGGED=4
	DELETED=5
	DENIED=6
	NOTIFIABLE=7
	
	Digest_Status = [CampaignUser::OWNER, CampaignUser::MEMBER, CampaignUser::NOTIFIABLE]

	belongs_to :user
	belongs_to :campaign
	stampable

	named_scope :alive, :conditions => [ "campaigns.status NOT IN (?)", Campaign::Dead_Status ]

	def request_membership
		if user
			Notification.deliver_request_campaign_membership(self)
		end
	end

	def self.create_owner(campaign)
		@cu = CampaignUser.new(:user_id=>campaign.creator.id ,:campaign_id=>campaign.id,:status=>CampaignUser::OWNER)
		@cu.save!
	end

	def self.get_notification_recipients(type)
    puts "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
		users_to_notify = find(:all,
			:include => "campaign",
			:conditions => ["campaign_users.status IN (?) AND campaigns.status NOT IN (?)", 
				CampaignUser::Digest_Status, 
				Campaign::Dead_Status])
		users_to_notify.select{|cu| cu.can_contact_for_campaign?(type) }
	end
	
	def can_contact_for_campaign?(type)
		case type
		when :daily
			broadcast_id = Broadcast.find_by_name('daily_account').id
		when :weekly
			broadcast_id = Broadcast.find_by_name('weekly_account').id
		end
		
		UserBroadcast.find(:first,:conditions=>["user_id = ? and broadcast_id = ? and campaign_id = ? and setting = 'off' ", user_id, broadcast_id, campaign_id]).nil?
	end
	
	def remove_from_contact
		daily_broadcast = Broadcast.find_by_name('daily_account')
		weekly_broadcast = Broadcast.find_by_name('weekly_account')
		a_broadcast = UserBroadcast.find(:all,:conditions=>["user_id = ? and broadcast_id = ?  and campaign_id = ?  ",user_id, weekly_broadcast.id,campaign_id])
		if a_broadcast.length > 0 
			a_broadcast .each do |broadcast|
				broadcast.update_attributes(:setting => 'off')
			end
		else
			UserBroadcast.create!(:user_id=>user_id, :broadcast_id=>weekly_broadcast.id,:campaign_id=>campaign_id,:setting=>'off')
		end
		a_broadcast = UserBroadcast.find(:all,:conditions=>["user_id = ? and broadcast_id = ?  and campaign_id = ?  ",user_id, daily_broadcast.id,campaign_id])
		if a_broadcast.length > 0 
			a_broadcast .each do |broadcast|
				broadcast.update_attributes(:setting => 'off')
			end
		else
			UserBroadcast.create!(:user_id=>user_id, :broadcast_id=>daily_broadcast.id,:campaign_id=>campaign_id,:setting=>'off')
		end		
	end

	DOWNLOAD_USER_STATUSES = [CampaignUser::OWNER, CampaignUser::MEMBER, CampaignUser::NOTIFIABLE]

	def include_in_download?
		ok_to_send? and DOWNLOAD_USER_STATUSES.include?(status)
	end

	def status_as_string
		['Unknown', 'Owner', 'Member', 'Pending Member', 'Flagged', 'Removed Member', 'Denied Member', 'Notified'][status] if status
	end
end
