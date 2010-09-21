require "erb"
require "lib/array_helper"
class Campaign < ActiveRecord::Base

	ACTIVE = 1
	FLAGGED = 2
	LEGACY = 3
	SUCCESSFUL = 4
	DELETED = 5
	CLOSED = 6
	STATUS_ARRAY=[ "", "Active", "Suspended", "Legacy", "Successful", "Deleted", "Closed" ]
	
	Dead_Status = [Campaign::DELETED, Campaign::CLOSED]
	
	include ERB::Util
	include ArrayHelper
	
	belongs_to :organization
	belongs_to :fund_raiser
	has_many :campaign_users
  has_many :payments
	has_many :users, :through=>:campaign_users
	has_many :members,:through=>:campaign_users,:source=>:user,:conditions=>"status=#{CampaignUser::MEMBER}"
	has_one  :owner,:through=>:campaign_users,:source=>:user,:conditions=>"status=#{CampaignUser::OWNER}"
	has_many :requested_members,:through=>:campaign_users,:source=>:user, :conditions=>"status=#{CampaignUser::REQUESTED}"
	has_many :flagged_campaigns
	has_many :campaign_flags
	has_many :requested_campaign_users,:class_name=>"CampaignUser",:conditions=>"status=#{CampaignUser::REQUESTED}"
	has_many :comments, :order=>"created_at desc"
	has_many :shared_contacts
  
  has_many :campaign_fund_raiser
  has_many :fund_raisers , :through=>:campaign_fund_raiser
	
#	validate :has_fundraiser
	validates_presence_of :organization_id,:message=>" must be selected"
	validates_presence_of :goal
	validates_numericality_of :goal
	validates_presence_of :name
	validates_uniqueness_of :friendly_url,:if=>Proc.new { |val| !val.friendly_url.blank? }
	
	before_save :set_donor_wall_settings
	before_save :set_class_year
	after_save :update_organization_campaign_count
	after_create :send_need_help_email
	
	concerned_with :video, :promotion, :photo, :donations, :initiation, :suspension
	stampable
	
	named_scope :active, :conditions => { :status => Campaign::ACTIVE }
	named_scope :limit_to, lambda { |amt| {:limit => amt} }
	named_scope :alive, :conditions => [ "campaigns.status NOT IN (?)", Campaign::Dead_Status ]
	named_scope :visible_to_all, :conditions => { :public => true }
	named_scope :not_deleted, :conditions => [ "campaigns.status NOT IN (?)", [Campaign::DELETED] ]
	
	def set_class_year
		self.class_year = nil if self.class_year.to_i <= 0
	end
	
	def status_text
		STATUS_ARRAY[self.status]
	end
	
	def get_comments(per_page = 10)
		array_div(comments, per_page)
	end
	
	def is_member?(user)
		(user == owner) or members.include?(user)
	end

	def url
		friendly_url && !friendly_url.empty? ? url_encode(friendly_url) : url_encode(name)
	end

	def self.find_by_search_term(search_term, page, page_size, order_by = "create_at desc")
		search_val=  sanitize('%' + search_term + '%')
		conditions  = ["public = 1"]
		conditions << "campaigns.status = #{Campaign::ACTIVE}"
		conditions << "campaigns.creation_step <> #{Campaign::Initiation::Created}"
		conditions << "campaign_users.status = #{CampaignUser::OWNER}"
		conditions << "(campaigns.name like #{search_val} or organizations.name like #{search_val})" unless search_val.empty?
		
		conditions = conditions.join(" and ")
		
		paginate(:per_page => page_size,
			:conditions => conditions,
			:joins => [:organization, :users],
			:page=>page,
			:order=>order_by)
	end
	
	def self.is_url_available?(url)
		!Campaign.exists?(["name = ? or friendly_url = ?",url,url])
	end
	
	def formatted_goal
		goal ? number_to_currency(goal) : ''
	end

	def formatted_goal=(value)
		self.goal = value.gsub(/\$|,/,'')
	end

	def number_with_delimiter(number, delimiter=",", separator=".")
		begin
			parts = number.to_s.split('.')
			parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
			parts.join separator
		rescue
			number
		end
	end

	def number_to_currency(number, options = {})
		options   = options.stringify_keys
		precision = options["precision"] || 2
		unit      = options["unit"] || "$"
		separator = precision > 0 ? options["separator"] || "." : ""
		delimiter = options["delimiter"] || ","
		format    = options["format"] || "%u%n"

		begin
			parts = number_with_precision(number, precision).split('.')
			format.gsub(/%n/, number_with_delimiter(parts[0], delimiter) + separator + parts[1].to_s).gsub(/%u/, unit)
		rescue
			number
		end
	end

	def number_with_precision(number, precision=3)
		"%01.#{precision}f" % ((Float(number) * (10 ** precision)).round.to_f / 10 ** precision)
	rescue
		number
	end

	def self.send_timed_donation_blast(type)    
		campaign_users = CampaignUser.get_notification_recipients(type)
		
		array_hash = {}
		campaign_users.each do |campaign_user|
			cid = campaign_user.campaign_id
			array_hash[cid] ||= []
			array_hash[cid] << campaign_user.user.email
			array_hash[cid].uniq!
		end
		
		array_hash.each do |campaign_id, user_list|
			campaign = Campaign.find(campaign_id)
			user_list.each do |user_email|
				Notification.deliver_status_update(type, user_email,campaign)
			end
		end
	end
	
	def self.send_daily_mail
		send_timed_donation_blast(:daily)
	end

	def self.send_weekly_mail
		send_timed_donation_blast(:weekly)
	end

	def currentPercent(options={})
		(current_amount.to_f  / (self.goal.to_f || 1.0 )  ).to_s
	end
	
	def current_amount
		real_amount = Payment.sum(:amount, :conditions => { :campaign_id => id })
		base_donations.to_i + real_amount
	end
	
	alias :currentAmount :current_amount

	def self.find_all_by_id(ids)
		find(:all,
			:conditions => ['campaigns.id in (?)', ids],
			:order => 'campaigns.name')
	end

	def member_count
		members.length
	end

	def has_been_reported?
		!flagged_campaigns.empty?
	end

	def last_time_reported
		flagged_campaigns.last.created_at
	end

	def reasons_for_reported
		reasons = Hash.new(0)
		flagged_campaigns.map{ |e| e.category }.each do |c|
			reasons[c] += 1
		end
		reasons
	end

	def fake_delete!
		update_attributes(:status=>Campaign::DELETED)
	end

	def is_deleted?
		(status == Campaign::DELETED)
	end
	
	def undelete!
		update_attributes(:status=>Campaign::ACTIVE)
	end
	
	def viewable?
		not (is_suspended? or is_deleted?)
	end

	def is_owner?(user)    
		return false unless user
		owner.id == user.id
	end

	def update_organization_campaign_count
		organization.update_campaigns_count
	end
	
	def send_need_help_email
    begin
      Notification.deliver_need_any_campaign_help(self.creator)
    rescue Exception=>e
    end


	end
	
	def send_finished_info_email
   
    Notification.deliver_campaign_page_complete_congrats(self.creator)
   
	end
	
	def has_fundraiser
		errors.add("Fund", "can't be blank") if fund_raiser_id.blank?
	end
	
	def set_donor_wall_settings
		if self.donor_goal.to_i <= 0
			self.donor_goal = 0
			self.disable_donor_goal_widget = true
		end
		true
	end
	
	def formatted_base
		base_donations ? number_to_currency(base_donations) : ''
	end

	def formatted_base=(value)
		self.base_donations = value.gsub(/\$|,/,'')
	end
	
	def active_shared_contacts
		shared_contacts.select{ |s| !s.accepted? }
	end
	
end
