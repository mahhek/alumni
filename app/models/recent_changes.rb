class RecentChanges
	PLACE = 1
	REVIEW = 2
	FRIEND = 3
	USERCHANGE = 4
	attr_accessor :user, :place,:review, :type, :time,:date
	def initialize(options={})
		@user = options[:user]
		@place = options[:place]
		@review = options[:review]
		@friend = options[:friend]
		@type = options[:type]
		@date = options[:date]
		@time = string_time(options[:date]) if options[:date]
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