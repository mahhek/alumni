class Campaign < ActiveRecord::Base
	module Initiation
		Created = 1
		Launched = 5
		Promoted = 2
		Donated = 3
		Done = 4
	end
	
	def initiated(step)
		case step
		when :launch
			step_from = Campaign::Initiation::Created
			step_to   = Campaign::Initiation::Launched
		when :promote
			step_from = Campaign::Initiation::Launched
			step_to   = Campaign::Initiation::Promoted
		when :donate
			step_from = Campaign::Initiation::Promoted
			step_to   = Campaign::Initiation::Donated
		when :finish
			step_from = Campaign::Initiation::Donated
			step_to   = Campaign::Initiation::Done
		end
		if self.creation_step == step_from
			update_attribute(:creation_step, step_to)
			send_finished_info_email if step == :donate
			return true
		end
		nil
	end
	
	
end