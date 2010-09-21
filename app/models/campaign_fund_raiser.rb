class CampaignFundRaiser < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :fund_raiser
end
