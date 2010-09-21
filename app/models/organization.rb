class Organization < ActiveRecord::Base
	has_many    :organization_photos, :as => :interface
	has_many    :fund_raisers
	has_many    :campaigns
	has_many    :organization_users, :order=>"created_at desc"
	has_many    :sticker_attributes, :conditions=>"parent_id is null"
	belongs_to  :school
	has_many    :organization_addresses, :order=>"created_at desc"
	has_many    :paypal_credentials, :order=>"created_at desc"
	has_one     :authorize_credential
	has_one     :branded_logo, :as => :interface
	has_many    :contact_spreadsheets
  
	
	validates_presence_of :school_id, :if=>Proc.new { |val| val.new_record? && val.name == ''},:message=>" must be selected if a 501(c) name is not given"
  
	before_save :resize_intro_video
	after_save  :create_funds

	stampable
	attr_accessor :add_paypal_account
	
	concerned_with :donation_options
	
	STATUS=["Inactive","Active","Flagged"]
	ACTIVE=1
	PAYPAL="PayPal"
	AUTHORIZE="Authorize"
	
	def status_text
		STATUS[self.status.to_i]
	end
	
	def self.new_from_registration(orid)
		reg = OrganizationRegistration.find(orid)
		new({:name => reg.name, :description => "", :thank_you_email => "", :campaign_pitch => ""})
	end
	
	def org_user
		organization_users.first.user if organization_users.length > 0
	end

	def has_user(user)
		organization_users.any? { |u| u.user == user }
	end

	def create_funds
		@funds ||= []
		@funds.each do |fund|
			self.fund_raisers << fund
		end
	end

	def notify_contacts
		unless school_id.blank?
			tos = ContactAlert.find_all_by_school_id_and_as_org(school_id, false).map(&:email)
			# Notification.deliver_notify_users_about_new_organization(tos, self)
		end
	end
	
	def paypal_name
		if main_credential && !main_credential.org_name.blank?
			main_credential.org_name
		else
			name
		end
	end

	def main_credential
#    puts "<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>#{paypal_credentials.inspect}<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>"
		paypal_credentials.first
	end
	def main_address
		organization_addresses.first
	end
	def find_default_fund
		fund_raisers.find(:first,:conditions=>"Name='Default' ")
	end
	
	def fund_raisers_text; end
	
	def fund_raisers_text=(text)
		@funds ||= []
		text.split(/,|\n/).each do |a_fund|
			@funds << FundRaiser.new(:name=>a_fund)
		end
	end
	def user_is_org_user(user)
		ret_val = false
		organization_users.each {|a_ouser| ret_val = true if a_ouser.user_id = user.id}
		ret_val
	end

	def sum_payments
		camp_base_donations = Campaign.sum(:base_donations, :conditions => [ 'organization_id = ?', id])
		real_donations = Payment.sum(:amount, :conditions => [ 'campaigns.organization_id = ?', id], :include => :campaign)
		base_donations.to_i + camp_base_donations + real_donations
	end
	
	def num_donors
		camp_base_donors = Campaign.sum(:base_donors, :conditions => [ 'organization_id = ?', id])
		real_donors = Payment.count(:all, :conditions => [ 'campaigns.organization_id = ?', id], :include => :campaign)
		base_donors.to_i + camp_base_donors + real_donors
	end

	def self.find_by_name_or_school_name(school_name)
		if org = find_by_name(school_name)
			return org
		else
			if school = School.find_by_name(school_name)
				org = Organization.find_by_school_id(school.id)
				return org
			end
		end
		nil
	end

	def self.find_by_partial_name(partial_name, opts={})
		search_term = "%#{partial_name}%"
		search_opts = {:conditions=>[ "name like ?", search_term]}
		search_opts.merge!(opts)
		find(:all, search_opts)
	end

	def campaign_count
		campaigns.length
	end

	def photos
		organization_photos.find(:all, :order=>'priority desc')
	end

	def main_photo
		organization_photos.find(:first, :order=>'priority desc')
	end

	def thumbnail
		if !organization_photos.empty?
			main_photo.public_filename('thumb')
		else
			"/images/sitewide/images/default_shopping_thumbsm.jpg"
		end
	end

	def self.find_by_search_term(search_term, page, page_size, order_by)
		search_val= sanitize('%' + search_term + '%') 
		conditions = "organizations.status=#{Organization::ACTIVE}"
		conditions += " and organizations.name like #{search_val}" unless search_val.empty?
		paginate(:per_page => page_size,
		:conditions => conditions, :page=>page,
		:order => order_by)
	end

  

	def self.find_all_by_id(ids)
		find(:all,
		:conditions => ['organizations.id in (?)', ids],
		:order => 'organizations.name')
	end

	def full_name
		if school
			school.name
		else
			name
		end
	end

	def update_campaigns_count
		update_attribute :campaigns_count, Campaign.count(:conditions => ["organization_id=? and status=?", id, Campaign::ACTIVE])
	end

	def thank_you_email
		default_email = \
%|<br>
Thank you for supporting #{name}.<br>
<br>
Your secure online gift has been received and is now being processed.<br>
<br>
#{name} may also choose to mail you a hard-copy receipt for your gift.  If you need a hard-copy receipt and do not receive one, please contact #{name}.<br>
<br>
Thank you again for supporting #{name}.<br>
<br>|
		
		(@attributes["thank_you_email"]) ? @attributes["thank_you_email"] : default_email
	end
	
	def bcc_email
		(blind_copy_on_donation_receipt?) ? blind_copy_email : ""
	end
	
	def appeal_email
		(blind_copy_on_appeals?) ? appeal_bcc_email : ""
	end
	
	def activate!
		update_attribute :status, 1
	end
	
	def top_class_years
		Payment.sum(:amount, :conditions => [ 'campaigns.organization_id = ? and campaigns.class_year is not null', id], :include => :campaign, :group=>"campaigns.class_year").select{|e| e.last.to_i >= class_year_dollar_min}.sort_by{ |e| -e.last }.first(3)
	end
	
	def class_year_total(year)
		Payment.sum(:amount, :conditions => [ 'campaigns.organization_id = ? and campaigns.class_year = ?', id, year], :include => :campaign)
	end

  def active_campaigns
    Campaign.find_all_by_organization_id_and_status( self.id , Campaign::ACTIVE )
  end
	
	# Video
	
	require 'app/models/video'
	include Video
	
	def resize_intro_video
		resize_video introduction_video
	end
	
	def update_paypal_credentials(cred_attrs)
	  creds = PaypalCredential.new(cred_attrs)
	  self.paypal_credentials << creds
	  self.payment_processor = Organization::PAYPAL
	  save
	end
	
	def update_authorize_credentials(cred_attrs)
	  update_attribute :payment_processor, Organization::AUTHORIZE
	  creds = authorize_credential || AuthorizeCredential.new
	  creds.organization_id = self.id
	  creds.update_attributes(cred_attrs)
	end
end
