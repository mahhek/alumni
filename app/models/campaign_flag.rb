class CampaignFlag < ActiveRecord::Base
	
	belongs_to :campaign
	
	## Status Codes
	UNRESOLVED = 0
	RESOLVED = 1
	
	def initialize(params={})
		params[:status] = CampaignFlag::UNRESOLVED
		super(params)
	end
end