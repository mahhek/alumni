class CMS < ActiveRecord::Base
	set_table_name :cms
	before_save :wtf
	after_save :wtf2
	
	def wtf
		logger.debug "wtf"
	end
	
	def wtf2
		logger.debug "wtf2"
	end
end