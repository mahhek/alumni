class Payment < ActiveRecord::Base
	
	before_create :set_display_name
#	after_save :notify_users

	attr_accessor :i_agree, :creditcard_type, :user_entered_acct, :acct, :cvv
	attr_accessor :expire_month, :expire_year, :user_entered_amount, :custom_amount
	attr_accessor :displayed_name_option, :user_entered_display_name

	belongs_to :user
	belongs_to :campaign
  belongs_to :fund_raiser
	
	validate :has_valid_credit_card_info
	validates_inclusion_of  'i_agree',  :in => "1",  :if=>Proc.new { |user| user.new_record? }, :message => "must be checked to continue."
	validates_presence_of :amount
	validates_numericality_of :amount
  validates_numericality_of :graduation_year
	validates_format_of :phone, :allow_blank => true,
	:with => /^(1\s*[-\/\.]?)?(\((\d{3})\)|(\d{3}))\s*[-\/\.]?\s*(\d{3})\s*[-\/\.]?\s*(\d{4})\s*(([xX]|[eE][xX][tT])\.?\s*(\d+))*/
	validates_format_of :email, :with => /^[\w\.=-]+@[\w\.-]+\.[\w]{2,3}$/
	validates_presence_of :i_agree
	validates_presence_of :first_name
	validates_presence_of :last_name
	validates_presence_of :address1
	validates_presence_of :city
	validates_format_of :zip, :with => /^[0-9]{5}([- ]?[0-9]{4})?$/
	#validate :has_matched_company_info
	
	before_validation :normalize_cc_number
#  , :normalize_amount
	
	def self.find_all_with_scope(scope, cid)
		case scope
		when :admin
			find(:all, :conditions=>["campaign_id=?",cid])
		when :anonymous
			find(:all, :conditions=>["campaign_id=? AND ok_to_send = 1",cid])
		end
	end
	
	def self.find_by_user_contact(uc)
		find(:first, :conditions=>{:campaign_id => uc.campaign_id, :email => uc.contact.email_address}, :order => "created_at DESC")
	end

	def expire_date
		"%02d%04d" % [self.expire_month.to_i,  self.expire_year.to_i]
	end

	def notify_users
    
		logger.info "NOTIFYING USERS BEGIN"
		donation_amount_broadcast = Broadcast.find_by_name("donation_of")
		any_donation_broadcast = Broadcast.find_by_name("any_donation")
		users = UserBroadcast.find(:all, :select=>:user_id, :conditions =>["((broadcast_id = ? AND setting <= ? ) or (broadcast_id = ? AND setting = 'on')) and campaign_id = ?",donation_amount_broadcast.id, amount, any_donation_broadcast.id, campaign_id]).map(&:user_id).uniq
		users = User.find(:all, :conditions => ["id in (?)", users])
		
		users.each do |user|
			Notification.deliver_donation_notification(user, campaign, self)
		end
		
		logger.info "NOTIFYING USERS END"
	end
	
	def sanitize
		self.email = self.email.gsub(/ |<|>/, "")
	end
	
	def full_name
		"#{first_name} #{last_name}"
	end

	def normalize_amount
    puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#{self.amount}"
		if self.user_entered_amount.to_i < 0
			self.user_entered_amount = self.custom_amount
		else
			self.custom_amount = nil
		end
		self.amount = self.user_entered_amount.to_s
	end
	
	def normalize_cc_number
		self.acct = self.user_entered_acct.gsub(/\D/, "")
	end
	
	def has_valid_credit_card_info
		if acct.blank? && !offline?
			errors.add(:user_entered_acct)
			errors.add("Card Number", "can't be blank.")
		end
	end
	
	def has_matched_company_info
		if matched?
			[:matched_name, :matched_addr1, :matched_city, :matched_state, :matched_zip, :matched_phone].each do |e|
				errors.add(e, "can't be blank") if send(e).blank?
			end
		end
	end
	
	def donor_wall_name
		return "Anonymous Donor" if self.anonymous?
		return self.display_name if self.display_name
		full_name
	end
	
	def set_display_name
		case self.displayed_name_option
		when "cc_name"
			#self.display_name = self.full_name
		when "hide"
			self.anonymous = true
		when "custom"
			self.display_name = self.user_entered_display_name
		end
	end
	
	def amount_in_cents
    puts "===============amount in cents================#{self.amount * 100}"
	  self.amount * 100
	end
	
	def authorize_type
	  case self.creditcard_type.downcase
      when "visa"
        "visa"
      when "mastercard"
        "master"
      when "amex"
        "american_express"
      when "discover"
        "discover"
    end
	end
end
