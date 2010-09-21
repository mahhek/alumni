class NewOrganization < ActiveRecord::Base

    belongs_to :organization
    
  	def self.find_newest_members(page, page_size, date)
puts date
        conditions = "new_organizations.expiry_date > #{date}"
      order = "joining_date desc"
		paginate(:per_page => page_size,
		:conditions => conditions, :order => order, :page=>page)
	end
end
