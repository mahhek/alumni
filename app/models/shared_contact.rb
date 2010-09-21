class SharedContact < ActiveRecord::Base
	belongs_to :contact_spreadsheet
	belongs_to :campaign
	
	def name
		"#{first_name} #{last_name}"
	end
end