class Campaign < ActiveRecord::Base
	has_many :campaign_photos, :order=>'created_at desc', :as => :interface
	has_one :main_photo, :class_name=>'CampaignPhoto',:foreign_key=>:interface_id, :conditions=>"main_image = 1"
	
	alias :photos :campaign_photos
	
	def set_as_main_photo(pid)
		drop_main_photo
		Photo.find(pid).update_attribute(:main_image , true)
	end
	
	def pick_new_main_photo
		if !campaign_photos.empty?
			campaign_photos.first.update_attribute(:main_image , true)
		end
	end
	
	def drop_main_photo
		if main_photo
			main_photo.update_attribute(:main_image, false)
		end
	end
	
	def thumbnail
		if !campaign_photos.empty?
			main_photo.public_filename('thumb')
		else
			"/images/sitewide/images/default_shopping_thumbsm.jpg"
		end
	end
end