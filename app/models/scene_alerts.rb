class SceneAlerts 
  
  DEFAULT_EXPIRATION_DATE = 80.days.ago
  INFO_CHANGED = 1
  MEMBER_ADDED = 2
  DONATION_MADE = 3
    
  attr_reader :options, :user, :alert_type, :alert_date, :campaign, :donation_amount, :donated_by_whom , :fund_name
  
  def initialize(user,options = {})
    @user = user
    @options = options
	@alert_type = options[:alert_type]
	@alert_date = options[:alert_date]
	@campaign = options[:campaign]
	@donation_amount = options[:donation_amount]
	@donated_by_whom = options[:donated_by]
  @fund_name = options[:fund_name]
  end
  def day
		self.alert_date.strftime('%A, %b %d')
	end
	def string_time(time)
		days = ((Time.now - time) / (60 *60*24))
		hours = ((Time.now - time) / (60 * 60))
		minutes = ((Time.now - time) / 100 )
		ret_string = ""
		if days.to_i > 0
			"#{days.to_i}  day#{'s' unless days.to_i == 1} ago"
		elsif hours.to_i > 0
			"#{hours.to_i} hour#{'s' unless hours.to_i == 1} ago"
		elsif minutes.to_i > 0 
			"#{minutes.to_i} minute#{'s' unless minutes.to_i == 1} ago"
		else
			"just added"
		end
	end
end
