class Campaign < ActiveRecord::Base
	
	has_many :campaign_contacts
	has_many :contacts,:through=>:campaign_contacts
	has_many :initial_contacts,:through=>:campaign_contacts,:conditions=>"campaign_contacts.status = #{CampaignContact::INITIAL}"
	has_many :new_contacts,:through=>:campaign_contacts,:conditions=>"campaign_contacts.status = #{CampaignContact::NEW}"
	has_many :donated_contacts,:through=>:campaign_contacts,:conditions=>"campaign_contacts.donated = 1"
	has_many :thanked_contacts,:through=>:campaign_contacts,:conditions=>"campaign_contacts.status = #{CampaignContact::THANKED}"
	has_many :eligible_contacts,:through=>:campaign_contacts,:source=>:contact ,:conditions=>"campaign_contacts.subscribed = 1"
	
	def align_contacts_with(raw_emails, a_user)
		contact_list = []

		raw_emails = raw_emails.gsub(/ |\r|\n/, "")

		email_list = raw_emails.split(/;|,/)

		email_list = email_list.map{ |e|
			scan = e.scan(/<(.+)>/)
			if scan.empty?
				e
			else
				scan.first.first
			end
		}.uniq
#    puts "**************************************************************"
		puts "email_list==>>#{email_list}"
		email_list.each do |a_contact|
      
      if a_contact != ""
        puts "ssssssssssssssss==>#{a_contact}"
        contact_list << find_or_create_user_contact_for(a_user, a_contact)
      end
		end
#    puts "--------------------------------------------------------------"
		contact_list
	end
	
	def find_or_create_user_contact_for(user, email)
		contact = Contact.find(:first,
			:conditions=>["email_address = ?", email])
			
		contact = Contact.create!(
			:email_address => email,
			:status => Contact::INITIAL) if !contact
		
		user_contact = UserContact.find(:first,
			:conditions => ["contact_id=? and campaign_id=? and creator_id = ?",
        contact.id, self.id, user.id] )
		
		if !user_contact	
			subscription_setting = UserContact.find(:first,
				:select => [:subscribed],
				:conditions => ["contact_id=? and campaign_id=?", contact.id, self.id] )
			if !subscription_setting.nil?
				subscription_setting = subscription_setting.subscribed
			else
				subscription_setting = CampaignContact::SUBSCRIBED
			end
			
			user_contact = UserContact.create!(
				:contact_id => contact.id,
				:campaign_id => id,
				:status => UserContact::PROSPECT,
				:subscribed => subscription_setting,
				:creator_id => user.id) if !user_contact
		end
		
		return user_contact
	end
	
#	def promote_to(status_hash, new_contact_list, request, options={})
#		new_contact_list.each do |contact|
#			if contact.respond_to? :subscribed
#				unless contact.subscribed == CampaignContact::UNSUBSCRIBED ||  contact.contact.subscribed == Contact::UNSUBSCRIBED
#					Notification.deliver_send_promotion(options,contact)
#				end
#			else
#				Notification.deliver_send_promotion_for_campaign(options, contact, self)
#			end
#		end
#	end

  def promote_to(status_hash, new_contact_list, request, campaign , options={})
    organization = campaign.organization
    
		new_contact_list.each do |contact|
      unsubscribe_email_address = Contact.find_by_id(contact.contact_id).email_address

      puts UnsubscribeOrganization.find_by_email_and_organization_id(unsubscribe_email_address , organization.id)
      
      if UnsubscribeOrganization.find_by_email_and_organization_id(unsubscribe_email_address , organization.id).nil?
        puts "NIL AA GYA HIA ISS LIYA IF MAIN AA GYA HAI"
        if contact.respond_to? :subscribed
          unless contact.subscribed == CampaignContact::UNSUBSCRIBED ||  contact.contact.subscribed == Contact::UNSUBSCRIBED
            begin
              Notification.deliver_send_promotion(options,contact)
            rescue Exception=>e
            end
          end
        else
          begin
            Notification.deliver_send_promotion_for_campaign(options, contact, self)
            rescue Exception=>e
          end
        end
        
      else
        puts "NIL NAHI AAYA ISS LIYA ELSE MAIN AA GYA HAI"
        unsubs_contact = Contact.find_by_email_address(unsubscribe_email_address)
        if a_user = User.find_by_email(unsubscribe_email_address)
          a_user.campaign_users.each do |campaign_user|
            campaign_user.remove_from_contact if campaign_user.campaign_id == campaign.id.to_i
          end
        end
        user_contact = UserContact.find(:first, :conditions=>["campaign_id = ? AND contact_id = ?", campaign.id, unsubs_contact.id])
        user_contact.unsubscribe!
      end

		end
	end

	def send_contact(request, options={})
		options[:contacts].to_a.each do |contact|
			a_con = UserContact.find(contact)
			unless a_con.subscribed == CampaignContact::UNSUBSCRIBED ||  a_con.contact.subscribed == Contact::UNSUBSCRIBED
				Notification.deliver_send_promotion(options,a_con)
				a_con.mark_as_contacted
			end
		end
	end

	def send_thanks(request, options={})
		options[:contacts].each do |contact|
			a_con = UserContact.find(contact)
			a_con.update_attributes(:status=>UserContact::THANKED)
			Notification.deliver_send_promotion(options,a_con)
			a_con.mark_as_contacted
		end
	end
end