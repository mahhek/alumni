class FundRaiser < ActiveRecord::Base
  stampable
  belongs_to :organization
  has_many :campaigns
  has_one  :payment
  has_many :campaign_fund_raiser
  has_many :campaigns , :through=>:campaign_fund_raiser
  
end
