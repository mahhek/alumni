class UserBroadcast < ActiveRecord::Base
	
	named_scope :for_campaign, lambda { |cid| { :conditions => { :campaign_id => cid } } }
	named_scope :of_broadcast, lambda { |bid| { :conditions => { :broadcast_id => bid} } }
	
	def self.find_user_broadcast_by_name(user, campaign, key)
		broadcast = Broadcast.find_by_name(key.to_s)
		UserBroadcast.find_by_user_id_and_broadcast_id_and_campaign_id(user.id, broadcast.id, campaign.id)
	end
	
	def self.turn_on_for(user, campaign)
		[:any_donation, :daily_account, :weekly_account].each do |key|
			set_setting(user, campaign, key, 'on')
		end
	end

	def self.set_setting(user, campaign, key, value)
		broadcast = Broadcast.find_by_name(key.to_s)
		ub = UserBroadcast.find_by_user_id_and_broadcast_id_and_campaign_id(user.id, broadcast.id, campaign.id)
		
		if ub
			ub.update_attributes(:setting => value)
		else
			UserBroadcast.create!(:user_id => user.id, :broadcast_id => broadcast.id, :campaign_id => campaign.id, :setting => value)
		end
	end

	def self.update_settings(options, user)
		options[:campaigns].each do |cid|
			campaign = Campaign.find(cid)
			set_setting(user, campaign, :any_donation, options[:any_donation][campaign.id.to_s])
			set_setting(user, campaign, :daily_account, options[:daily_account][campaign.id.to_s])
			set_setting(user, campaign, :weekly_account, options[:weekly_account][campaign.id.to_s])

			options[:donation_of][campaign.id.to_s] if options[:donation_of_amount][campaign.id.to_s] == 'off'
			set_setting(user, campaign, :donation_of, options[:donation_of][campaign.id.to_s])
		end
	end
	
	def self.get_or_create_setting(user, campaign, key, default)
		if ub = find_user_broadcast_by_name(user, campaign, key)
			return ub.setting
		else
			set_setting(user, campaign, key, default)
			return default
		end
	end

	def self.create_broadcast_hash(user, campaigns)
		options={}
		options[:any_donation]={}
		options[:donation_of]={}
		options[:donation_of_amount]={}
		options[:daily_account] ={}
		options[:weekly_account] = {}
		campaigns.each do |campaign|
			options[:any_donation][campaign.id] = get_or_create_setting(user, campaign, :any_donation, 'on')
			options[:daily_account][campaign.id] = get_or_create_setting(user, campaign, :daily_account, 'off')
			options[:weekly_account][campaign.id] = get_or_create_setting(user, campaign, :weekly_account, 'on')
			options[:donation_of][campaign.id] = get_or_create_setting(user, campaign, :donation_of, 0)
		end
		options
		end
	end
