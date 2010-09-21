class FeaturedCampaign < ActiveRecord::Base
	validates_uniqueness_of :campaign_id
	belongs_to :campaign
	
	def self.get_hottest
		find(:all, 
		:include=>"campaign", 
		:conditions=>["campaigns.public = 1 and expiration > ?", Time.now]).map(&:campaign).sort{|a, b| b.active_donors <=> a.active_donors }
	end
	
	def active?
		expiration > Time.now
	end
end
