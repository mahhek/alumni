class ContentManager

	def self.calculate_change_list(a_user, age=7.days)
    puts "in calculation"
		loc_change_list = []
		a_user.all_campaigns.each do |campaign|

			loc_change_list << SceneAlerts.new( campaign.creator, :alert_type => SceneAlerts::INFO_CHANGED, :campaign => campaign, :alert_date => campaign.updated_at ) if campaign.updated_at > age.ago

			campaign.campaign_users.find(:all, :conditions => [ "status=#{CampaignUser::MEMBER} and campaign_users.created_at > ?", age.ago.to_s( :db ) ] ).each do |camp_user|
				loc_change_list << SceneAlerts.new( camp_user.user, :alert_type => SceneAlerts::MEMBER_ADDED, :campaign => campaign, :alert_date => camp_user.created_at )
			end
#puts "111"
			campaign.payments.find(:all,:conditions=>["payments.created_at > ?",age.ago.to_s(:db)]).each do |payment|
#        puts "===><><<><>-----#{payment.inspect}"
				loc_change_list << SceneAlerts.new( payment.user, 
                                            :alert_type => SceneAlerts::DONATION_MADE,
                                            :campaign => campaign,
                                            :alert_date => payment.created_at,
                                            :donation_amount => payment.amount,
                                            :donated_by => payment.full_name ,
                                            :fund_name=>payment.fund_raiser.name )
                                          puts "=======>#{payment.fund_raiser.name}"
			end
#puts "222"
		end
#    puts "333"
		ContentManager.sort_list(loc_change_list.flatten.compact)
	end

	def self.sort_list(list)
		list.sort do |item_a,item_b|
			item_b.alert_date <=> item_a.alert_date
		end
	end

end
