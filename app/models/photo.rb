class Photo < ActiveRecord::Base
	stampable
	belongs_to :interface, :polymorphic => true
	
	def caption
		@attributes["caption"].to_s[0..150]
	end
end