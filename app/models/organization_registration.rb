class OrganizationRegistration < ActiveRecord::Base
	attr_accessor :xxxxxx, :yyyyyy, :zzzzzz
	validates_presence_of :contact_name, :contact_phone, :contact_email
	validates_presence_of :name, :address, :city, :state, :zip
	validates_presence_of :year_established, :federal_ein
	#validates_presence_of :description
	validates_presence_of :bank_name, :bank_type, :bank_routing_no, :bank_acct_no
	serialize :fundraisers
	
	has_one :organization
	has_many :org_reg_attachments
	has_one :main_logo,  :class_name => "OrgRegAttachment", :conditions => "attachment_type = 'main_logo'"
	has_one :voided_check, :class_name => "OrgRegAttachment", :conditions => "attachment_type = 'voided_check'"
	has_one :tax_proof, :class_name => "OrgRegAttachment", :conditions => "attachment_type = 'tax_proof'"
end