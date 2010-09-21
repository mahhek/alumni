class Admin < ActiveRecord::Base
	set_table_name :admin_settings
	
	def self.is_site_down?
		(get("site_down").on?)
	end
	
	def self.disable_site
		get("site_down").on!
	end
	
	def self.enable_site
		get("site_down").off!
	end
	
	def self.get(name)
		find_by_name(name)
	end
	
	def on?
		setting == "on"
	end
	
	def off?
		setting == "on"
	end
	
	def on!
		update_attribute(:setting, "on")
	end
	
	def off!
		update_attribute(:setting, "off")
	end
	
end