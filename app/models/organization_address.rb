class OrganizationAddress < ActiveRecord::Base
	
	belongs_to :organization

  validates_presence_of :street
	validates_presence_of :state
	validates_presence_of :city
#  validates_uniqueness_of     :url_portion 
	
	def self.new_from_registration(orid)
		reg = OrganizationRegistration.find(orid)
		new({
			:street => reg.address, 
			:city => reg.city, 
			:state => State.find_by_name(reg.state.upcase).id, 
			:zip => reg.zip})
	end
end