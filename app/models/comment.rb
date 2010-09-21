class Comment < ActiveRecord::Base
	stampable
	
	def self.feed_by_campaign(campaign_id, page, page_size, options = {})
		paginate(options.merge(
		    :per_page => page_size, 
		    :conditions => [ "campaign_id=?", campaign_id ], 
		    :page => page,
	        :order => "created_at desc"))
	end	
	
	
end
