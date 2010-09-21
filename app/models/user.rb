require 'digest/sha1'
require 'digest/sha2'
class User < ActiveRecord::Base

	attr_protected :hashed_password, :enabled
	attr_accessor :password, :agrees
	cattr_accessor :current_user

	# TO-DO: condense error msgs into just 1 for multiple errors on the same field; or only fail conditionally, 1 at a time
	validates_presence_of         :first_name
	validates_presence_of         :last_name
	validates_presence_of         :email
	validates_format_of           :email, :with => /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/
	validates_uniqueness_of     :email, :case_sensitive => false
	validates_length_of           :email, :within => 5..128
	validates_presence_of       :email_confirmation, :if=>Proc.new { |user| user.new_record? }
	validates_confirmation_of   :email, :if=>Proc.new { |user| user.new_record? }
	validates_presence_of          :password, :if => :password_required?
	validates_presence_of         :password_confirmation, :if => :password_required?
	validates_confirmation_of   :password, :if => :password_required?
	validates_length_of          :password, :within => 5..20, :if => :password_required?

	has_many :user_attribute_details
	has_many :user_attributes, :through => :user_attribute_details

	has_many :role_users
	has_many :roles, :through => :role_users

	has_many :user_photos, :as => :interface
	has_many :site_activities

	has_many :saved_items

	has_many :campaign_users
	has_many :campaigns, :through=>:campaign_users
	has_many :member_campaign_users, :class_name=>'CampaignUser',:foreign_key=>:user_id,:conditions=>"campaign_users.status=#{CampaignUser::MEMBER}", :include=> "campaign"
	has_many :owned_campaigns, :through=>:campaign_users,:source=>:campaign,:conditions=>"campaign_users.status=#{CampaignUser::OWNER}",:order=>"campaigns.name asc"
	has_many :member_campaigns, :through=>:campaign_users,:source=>:campaign,:conditions=>"campaign_users.status=#{CampaignUser::MEMBER}",:order=>"campaigns.name asc"
	has_many :notifiable_campaigns, :through=>:campaign_users,:source=>:campaign,:conditions=>"campaign_users.status=#{CampaignUser::NOTIFIABLE}",:order=>"campaigns.name asc"
	has_many :all_associated_campaigns, :through=>:campaign_users,:source=>:campaign
	
	
	has_many :user_messages do
		def for_message(message)
			find_by_message_id(message.original_message_id)
		end
	end
	
	has_many :messages, :through=>:user_messages, :order=>"messages.created_at desc"

	has_many :user_contacts,:foreign_key=>"creator_id"
	has_many :contacts,:through=>:user_contacts

	has_many :user_broadcasts
	
	model_stamper
	stampable
	
	def xyz
		
	end
	
	def all_campaigns
		(owned_campaigns + member_campaigns).flatten.uniq
	end

	def contacts_for_campaign(campaign, status)
		user_contacts.find(:all, :conditions=>["campaign_id = ? and status=? and subscribed <> '#{CampaignContact::UNSUBSCRIBED}'  ",campaign.id, status])
	end
	def all_contacts_for_campaign(campaign)
		user_contacts.find(:all, :conditions=>["campaign_id = ?",campaign.id])
	end
	def self.get_json_for(user_collection=[])
		ret_hash= []
		user_collection.each do |item|
			ret_hash << {:caption=>item.name,:value=>item.id}
		end
		ret_hash.to_json
	end

	def self.notify_for(campaign, broadcast_name)
		broadcast = Broadcast.find_by_name(broadcast_name)
		campaign.users.each do |user|
			setting = user.broadcast_setting_for(campaign, broadcast)
			if setting.to_s != "off"
				yield user, setting, broadcast
			end
		end
	end
	
	def broadcast_setting_for(campaign, broadcast)
		broadcast_setting = user_broadcasts.for_campaign(campaign.id).of_broadcast(broadcast.id).first
		(broadcast_setting) ? broadcast_setting.setting : "on"
	end

	def has_requests?
		request_count > 0
	end

	def request_count
		CampaignUser.count(:conditions => ["campaign_id in (?) and status = ?", owned_campaigns.map(&:id), CampaignUser::REQUESTED ])
	end


	# get the most recent message in each of the users message threads
	def most_recent_messages
		messages(true).map(&:get_current_message)
	end

	def inbox_messages
		most_recent_messages.to_a.find_all { |message| !has_read? message }
	end

	def all_messages
		most_recent_messages.map { |message| 
			[message, user_messages.for_message(message).read_message_id] 
		}
	end

	def sent_messages
		message_list = Message.find_all_by_creator_id_and_visibility(id, Message::VISIBLE, :order=>'created_at desc')
		message_list.map(&:get_current_message).select(&:visible?).uniq
	end

	def has_read?(message)
		user_messages.for_message(message).has_read(message)
	end

	def mark_read_level_id(message)
		user_message = user_messages.for_message(message)
		user_message.update_attribute(:read_message_id, message.id) if user_message
	end

	def unmark_read_level_id(message)
		user_message = user_messages.for_message(message)
		user_message.update_attribute(:read_message_id, nil) if user_message
	end

	def name
		short_name
	end

	def initialize(*runtime_args)
		create_general_attributes
		super(*runtime_args)
	end

	def self.get_by_search_term(search_term)
		term = "%#{search_term}%"
		User.find(:all,:conditions=>["first_name like ? or last_name like ? or email like ?", term, term, term])
	end
	def self.hashed(str)
		return Digest::SHA1.hexdigest("#{str}")[0..39]
	end
	def self.find_by_token(string)
		find(:first, :conditions=>["salt=?", string])
	end
	def self.encrypt(string)

		return Digest::SHA256.hexdigest(string)
	end
	def self.authenticate(email, password)
		find_by_email_and_hashed_password_and_enabled(email,
		User.encrypt(password), true)
	end
	def validate_on_create # is only run the first time a new object is saved
		#unless i_agree == "1"
		#    errors.add("i_agree", " must be checked below")
		#end
	end
	def password_required?
		self.hashed_password.blank? || !self.password.blank?
	end
	def editable_password
		""
	end
	def editable_password=(value)
		self.password = value
	end
	def i_agree=(value)
		@agrees = value
	end
	
	def i_agree
		@agrees
	end

	def first_name
		self[:first_name].capitalize
	end
	
	def short_name
		"#{first_name} #{last_name}"
	end
	
	def main_photo
		user_photos[user_photos.length - 1]
	end
	
	def thumbnail
		if !user_photos.empty?
			user_photos[user_photos.length - 1].public_filename('small')
		else
			"/images/sitewide/images/default_member_thumbmd.jpg"
		end
	end

	def has_role?(rolename)
		self.roles.find_by_name(rolename) ? true : false
	end

	def send_welcome_email(params)
		if self.do_not_contact == false
			Notification.deliver_welcome_email(self)
		end
	end

	def get_attr_detail(the_attr, value)
		ret_val = []
		an_attrib = UserAttribute.find_by_name(the_attr)

		if value.class == Array
			value.each do |item|
				ret_val << UserAttributeDetail.new(:user_attribute_id=>an_attrib.id,:value=>item, :attribute_name=>the_attr)
			end
		else
			a_detail = user_attribute_details.find(:first, :conditions=>"user_attribute_id=#{an_attrib.id}")
			unless a_detail
				ret_val << UserAttributeDetail.new(:user_attribute_id=>an_attrib.id,:value=>value, :attribute_name=>the_attr)
			else
				a_detail.value = value
				ret_val << a_detail
			end
		end
		ret_val
	end

	def before_save
		self.salt = User.hashed("salt-#{Time.now}") unless self.salt
		self.hashed_password = User.encrypt(password) if !self.password.blank?
	end
	
	def after_save
		@other_attributes ||= []
		@other_attributes.each do |an_attrib|
			an_attrib.each do |saved_value|
				saved_value.user_id = id
				saved_value.save!
			end
		end
	end
	def after_find
		create_general_attributes
	end

	def is_org_admin_for(org)
		if has_role?('OrganizationUser')
      puts "1"
			org_user_relationship = OrganizationUser.find_by_user_id_and_organization_id(id, org.id)
			if org_user_relationship
        puts "2"
				logger.info "DEBUG::::#{org.id} - #{org_user_relationship.organization_id} | #{(org.id == org_user_relationship.organization_id)}"
				return (org.id == org_user_relationship.organization_id)
			end
		end
    puts "3"
		return false
	end

	def administrated_organizations
		return [] if !has_role?('OrganizationUser')    
		OrganizationUser.find_all_by_user_id(id)
	end

	private
	def create_general_attributes
		singleton = class << self; self; end
		UserAttribute.find(:all).each do |attrib|
			eval_var= <<-HTML
			#{attrib.validation_format}
			def #{attrib.name}
			unless @#{attrib.name}
			a_user = user_attribute_details.find(:all, :conditions=>"attribute_name='#{attrib.name}'")
			if a_user.length > 0
			case a_user[0].user_attribute.data_type
			when DataType::CHECKBOXLIST
			return a_user
			when DataType::SELECT
			return a_user[0].value
			when DataType::TEXT
			return a_user[0].value
			else
			return a_user[0].value.to_i
			end
			end
			else
			@#{attrib.name}
			end
			end
			def #{attrib.name}=(value)
			@#{attrib.name} = value
			@other_attributes ||=[]
			@other_attributes << get_attr_detail('#{attrib.name}', value)
			end
			HTML
			singleton.class_eval eval_var
		end
	end
end
