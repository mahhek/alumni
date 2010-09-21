class CampaignEmail < ActiveRecord::Base
  belongs_to :email
  belongs_to :campaign
end