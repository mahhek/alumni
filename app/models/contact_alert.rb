class ContactAlert < ActiveRecord::Base
	validates_presence_of :first_name
	validates_presence_of :last_name
	validates_presence_of :email
	after_save :alert_admin, :thank_contact
	belongs_to :school

	def name
		"#{first_name} #{last_name}"
	end

	def organization_name
		return school.name if school
		"Unknown"
	end

	def alert_admin
		Notification.deliver_contact_signup(self)
	end
	
	def thank_contact
		Notification.deliver_contact_signup_thanks(self)
	end
	
	def readable_contact_me
		(contact_me?) ? "yes" : "no"
	end
end
