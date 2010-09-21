class Campaign < ActiveRecord::Base

	def suspend!(reason="")
		update_attributes(:status=>Campaign::FLAGGED)
		CampaignFlag.create(:message=>reason, :campaign_id=>self.id, :organization_id=>self.organization_id)
		FlaggedCampaign.take_action_on(self.id, "suspended")
	end

	def unsuspend!
		update_attributes(:status=>Campaign::ACTIVE)
		CampaignFlag.update_all("status = 1", ["status = 0 AND campaign_id = ?", self.id])
	end

	def is_suspended?
		(status == Campaign::FLAGGED)
	end

	def has_been_suspended?
		!campaign_flags.empty?
	end

	def last_time_suspended
		campaign_flags.last.created_at
	end

	def reasons_for_suspension
		campaign_flags.map{ |f| {:time=> f.created_at, :reason=>f.message} }
	end
	
	def suspension_explanation
		campaign_flags.last.message
	end

end