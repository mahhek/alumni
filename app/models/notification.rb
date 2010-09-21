class Notification < ActionMailer::Base

	helper :application
	Admins = ["david@alumnifidelity.com", "will@alumnifidelity.com"]

	def status_update(type, to, campaign, sent_at=Time.now)
		case type
		when :daily
			blast_message = "Your daily notification for #{campaign.name}"
		when :weekly
			blast_message = "Your weekly notification for #{campaign.name}"
		end
		
		blast_message = "#{RAILS_ENV.upcase}: " + blast_message if RAILS_ENV != "production"
		
		@recipients   = to
		@from         = "AlumniFidelity <admin@alumnifidelity.com>"
		@sent_on      = sent_at
		@content_type = "text/html"
		@subject = blast_message
		@body = {
			:campaign => campaign,
			:payments => campaign.payments_for_blast(type),
			:blast_message => blast_message
		}
	end

	def notify_owner(flagged_campaign, sent_at=Time.now)
		@from  = "AlumniFidelity <admin@alumnifidelity.com>"
		@sent_on      = Time.now
		@content_type = "text/html"
		@recipients   =  [flagged_campaign.campaign.creator.email]
		@subject    = "Your fundraising page has been flagged"
		@body = {
			:campaign=>flagged_campaign.campaign,
			:status=>flagged_campaign.category,
			:action=>flagged_campaign.action,
			:contact_who=>flagged_campaign.organization.org_user.email,
			:message=>flagged_campaign.description,
			:sent_on => sent_at
		}
	end

	def campaign_raised(to, org, reason, campaign, sent_at=Time.now)
		@from  = "AlumniFidelity <admin@alumnifidelity.com>"
		@sent_on      = Time.now
		@content_type = "text/html"
		@recipients   =  to.to_a
		@subject    = "A fundraising page has been suspended for #{org.full_name}"
		@body = {
			:organization=>org,
			:campaign=>campaign,
			:message=>reason,
			:sent_on => sent_at
		}
	end

	def donation_notification(user, campaign, payment, sent_at = Time.now)
    puts "---------------^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^---------------"
		setup_email(user)
		@subject = "Someone has donated to #{campaign.name}"

		@body = {
			:campaign => campaign,
			:payment => payment,
			:to => user.email
		}
	end

	def forgot_password(user)
		setup_email(user)
		@subject    = 'IMPORTANT: How to change your AlumniFidelity password'
		@body = {
			:user => user,
			:sent_on => Time.now,
			:link=>"#{LocalURL}/account/password_change_request?key=#{user.salt}"
		}
	end

	def request_campaign_membership(campaign_user, sent_at = Time.now)
		setup_email(campaign_user.campaign.creator)
		@subject = "#{campaign_user.user.short_name} requested to be a part of #{campaign_user.campaign.name}..."
		@body = {
			:sent_on => sent_at,
			:link => "#{LocalURL}/my_stuff/member_requests",
			:friend =>  campaign_user.user,
			:message => campaign_user.message,
			:campaign_name => campaign_user.campaign.name
		}
	end

	def thanks_for_payment(payment, campaign)
    @from         = "AlumniFidelity <admin@alumnifidelity.com>"
		@sent_on      = Time.now
		@content_type = "text/html"
		@subject    = "Thank you for giving to #{campaign.organization.name}"
		@recipients = payment.email
#    @recipients = "mrhamidraza@hotmail.com"
    @bcc = []
    if campaign.organization.bcc_email.include? ";"
      bcc_array = campaign.organization.bcc_email.split(";")
      bcc_array.each do |email|
        @bcc << email
      end
    else
      @bcc << campaign.organization.bcc_email
    end
		@body = {
			:link => "#{LocalURL}/#{campaign.url}.html",
			:campaign => campaign,
			:organization => campaign.organization,
			:payment => payment
		}    
	end

	def welcome_email(user, sent_at = Time.now)

		setup_email(user)
		@subject    = "Welcome to AlumniFidelity!  Now what?"
		@body = {
			:user => user,
			:sent_on => sent_at
		}
    @body[:help]  = "#{LocalURL}/organizations/help/1"
	end

	def send_promotion(notification, contact, sent_at=Time.now)
		send_promotion_for_campaign(notification, contact.contact.email_address, contact.campaign, sent_at)
	end

	def send_promotion_for_campaign(notification, to, campaign, sent_at=Time.now)

    @from = "appeals@alumnifidelity.com"
    @reply_to  = "#{notification[:message][:from_email]}"
		@sent_on      = Time.now
		@content_type = "text/html"
		@recipients = to
		@subject    = notification[:promotion][:subject]
		@bcc = []
    if campaign.organization.appeal_email.include? ";"
      appeal_array = campaign.organization.appeal_email.split(";")
      appeal_array.each do |email|
        @bcc << email
      end
    else
      @bcc << campaign.organization.appeal_email
    end
		@body = {
			:campaign => campaign,
			:message => notification[:promotion][:body],
			:sent_on => sent_at,
			:to => to
		}
	end

	def message_sent(user_message, sent_at=Time.now)
		from "AlumniFidelity <admin@alumnifidelity.com>"
		sent_on sent_at
		content_type "text/html"
		recipients "#{user_message.user.name} <#{user_message.user.email}>"
		subject "You have a message in your AlumniFidelity inbox."
		body :user => user_message.user, :link => "#{LocalURL}/"
	end

	def notify_users_about_new_organization(to, organization, sent_at=Time.now)
		from "AlumniFidelity <admin@alumnifidelity.com>"
		sent_on sent_at
		content_type "text/html"
		recipients "AlumniFidelity <admin@alumnifidelity.com>"
		bcc to
		subject "#{organization.name} has registered with AlumniFidelity!"
		body :organization => organization, :link => "#{LocalURL}/organizations/#{organization.id}.html"
	end

	def contact_signup(contact_alert, sent_at=Time.now)
		from "AlumniFidelity <admin@alumnifidelity.com>"
		sent_on sent_at
		content_type "text/html"
		recipients Admins
		subject "#{contact_alert.name} wants to register #{contact_alert.organization_name} with AlumniFidelity"
		info = {
			"Name" => :name,
			"Email" => :email,
			"Org" => :organization_name,
			"Typed Org" => :school_name,
			"Phone" => :phone
		}
		info["Contact?"] = :readable_contact_me if !contact_alert.contact_me.nil?
		
		@body = {
			:contact => contact_alert,
			:info_to_display => info
		}
	end
	
	def contact_signup_thanks(contact_alert)
		from "AlumniFidelity <admin@alumnifidelity.com>"
		sent_on Time.now
		content_type "text/html"
		recipients contact_alert.email
		subject "Thank you for registering with AlumniFidelity"
	end
	
	def org_registered(org_reg)
		from "AlumniFidelity <admin@alumnifidelity.com>"
		sent_on Time.now
		content_type "text/html"
		recipients Admins
		subject "#{org_reg.contact_name} has completed the registration for #{org_reg.name}"
		info = {
			"Name" => :contact_name,
			"Email" => :contact_email,
			"Org" => :name,
			"Phone" => :contact_phone
		}
		
		@body = {
			:registration => org_reg,
			:info_to_display => info
		}
	end
	
	def need_any_campaign_help(user)
		setup_email(user)
		subject "You've created a fundraising page.  Need any help?"
	end
	
	def campaign_page_complete_congrats(user)
		setup_email(user)
		subject "You've promoted your page.  Now here is the REALLY cool stuff:"
	end
	
	def custom_user_email(to, subject, body)
		from "AlumniFidelity <admin@alumnifidelity.com>"
		sent_on Time.now
		content_type "text/html"
		recipients to
		subject subject
		@body = {:data => body}
	end
	
	def new_campaign_page_created(c, to)
#		from "AlumniFidelity <admin@alumnifidelity.com>"
    from "AlumniFidelity <appeals@alumnifidelity.com>"
		sent_on Time.now
		content_type "text/html"
    puts "=============================================>#{c}"
		recipients to
    puts "=============================================>#{to}"
		subject "A new Fundraising Page has been created."
		@body = {:campaign => c}
	end
		
	
	protected

	def setup_email(user)
		@recipients   = "#{user.email}"
		@from         = "AlumniFidelity <admin@alumnifidelity.com>"
		@sent_on      = Time.now
		@content_type = "text/html"
	end    
end
