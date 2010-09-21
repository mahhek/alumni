class Contact < ActiveRecord::Base
  INITIAL=0
  INVITED=1
  NEW=2
  CONTRIBUTED=3
  THANKED=4
  SUBSCRIBED=true
  UNSUBSCRIBED=false
   has_many :campaign_contacts
   has_many :user_contacts
end
