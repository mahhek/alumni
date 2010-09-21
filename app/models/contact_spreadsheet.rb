class ContactSpreadsheet < ActiveRecord::Base
	require 'spreadsheet'
	
	attr_accessor :sheet, :email_col, :fname_col, :lname_col
	
	belongs_to :organization
	has_many :shared_contacts
	has_attachment :storage => :file_system, :max_size => 5.megabytes
	
	def build!
		open
		parse_header_row
		sheet.each_with_index do |row, i|
			next if i == 0
			SharedContact.create(contact_data(row))
		end
	end
	
	def contact_data row
		{
			:first_name => row[fname_col],
			:last_name => row[lname_col],
			:email => row[email_col],
			:contact_spreadsheet_id => id
		}
	end
	
	def system_filename
		"#{RAILS_ROOT}/public#{public_filename}"
	end
	
	def open
		self.sheet = Spreadsheet.open(system_filename).worksheet 0
	end
	
	def parse_header_row
		self.sheet.row(0).each_with_index do |col, i|
			self.email_col = i if (!self.email_col && check_match(col, "email"))
			self.fname_col = i if (!self.fname_col && check_match(col, "first"))
			self.lname_col = i if (!self.lname_col && check_match(col, "last"))
		end
	end
	
	def check_match data, str
		data.downcase.include? str
	end
end