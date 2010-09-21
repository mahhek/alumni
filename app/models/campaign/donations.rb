class Campaign < ActiveRecord::Base
	has_many :payments
	has_many :user_donors, 
		:through=>:payments, 
		:source=>:user, 
		:select=>"users.first_name, users.last_name, payments.display_name, users.id, sum(payments.amount) as amount_total, payments.hide_amount", 
		:conditions=>"payments.anonymous = 0 AND payments.offline = 0 AND payments.user_id IS NOT NULL AND payments.display_name IS NULL AND payments.hide_amount = 0", 
		:group=>"payments.user_id"
	
	has_many :drive_by_donors,
		:class_name=>"Payment",
		:select=>"payments.first_name, payments.last_name, payments.display_name, sum(payments.amount) as amount_total, anonymous, payments.hide_amount", 
		:conditions=>"payments.anonymous = 0 AND payments.hide_amount = 0 AND (payments.user_id IS NULL OR (payments.offline = 1 AND payments.user_id IS NOT NULL) OR payments.display_name IS NOT NULL)", 
		:group=>"payments.email"
	
	has_many :anonymous_donors,
		:class_name=>"Payment",
		:select=>"sum(amount) as amount_total, anonymous, payments.hide_amount",
		:conditions=>"anonymous = 1 AND payments.hide_amount = 0", 
		:group=>"payments.email"
		
	has_many :hidden_amount_donors,
		:class_name=>"Payment",
		:select=>"payments.first_name, payments.last_name, payments.display_name, amount as amount_total, anonymous, payments.hide_amount",
		:conditions=>"payments.hide_amount = 1"
	
	def get_donors(per_page = 10)
		all_donors = (user_donors + drive_by_donors + anonymous_donors + hidden_amount_donors).sort_by{ |d| d.amount_total.to_i }.reverse
		array_div(all_donors, per_page)
	end
	
	def active_donors
		real_donors = self.payments.count
		base_donors.to_i + real_donors
	end
	
	def payments_for_blast(type)
		case type
		when :daily
			time = 1.day.ago
		when :weekly
			time = 7.days.ago
		end
			
		payments.find(:all, :conditions=>["created_at > ? ", time])
	end
	
	def fundraiser_total
    if fund_raiser_id.nil?
      total = 0.to_f
      self.payments.each do |payment|
        if self.fund_raisers.include?(payment.fund_raiser)
          puts "base=>#{Campaign.sum(:base_donations,:include=>:fund_raisers, :conditions => [ 'fund_raisers.id = ?', payment.fund_raiser])}"
          puts "payment=>#{Payment.sum(:amount, :conditions => [ 'fund_raiser_id = ?', payment.fund_raiser])}"          
          base_aggregate_donations = Campaign.sum(:base_donations,:include=>:fund_raisers, :conditions => [ 'fund_raisers.id = ?', payment.fund_raiser])
          total = total + base_aggregate_donations + Payment.sum(:amount, :conditions => [ 'fund_raiser_id = ?', payment.fund_raiser])
          puts "total=>#{total}"
        end
      end
      total
    else
      base_aggregate_donations = Campaign.sum(:base_donations, :conditions => [ 'fund_raiser_id = ?', fund_raiser_id])
      base_aggregate_donations + Payment.sum(:amount, :conditions => [ 'campaigns.fund_raiser_id = ?', fund_raiser_id], :include => :campaign)
    end		
	end
end