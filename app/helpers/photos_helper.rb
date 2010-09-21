module PhotosHelper

	def load_thumb(a_user)
		if a_user.main_photo
			image_tag(a_user.main_photo.public_filename('thumb'), :class=>"thumb", :alt=>"user thumbnail", :title=>"#{a_user.short_name}")
		else
		  a_user.short_name ||= ""
			image_tag("/images/af/image-holder.png", :class=>"thumb", :alt=>"user thumbnail", :title=>"#{a_user.short_name}")
		end
	end

	def load_full(a_user)
		if a_user.main_photo
			image_tag(a_user.main_photo.public_filename('profile') , :class=>"pic", :alt=>"user picture", :title=>"#{a_user.short_name}")
		else
		  a_user.short_name ||= ""
			image_tag("/images/af/organization_photo_reg.png", :class=>"pic", :alt=>"user picture", :title=>"#{a_user.short_name}")
		end
	end
	def load_featured(a_user)
		if a_user.main_photo
			image_tag(a_user.main_photo.public_filename('featured') , :class=>"pic", :alt=>"user thumbnail", :title=>"#{a_user.short_name}")
		end
	end
	def load_small(a_camp)
		if a_camp.main_photo
			image_tag(a_camp.main_photo.public_filename('small') , :alt=>"user thumbnail", :width=>"68", :height=>"68", :title=>"#{a_camp.name}")
		else
		  a_camp.name ||= ""
			image_tag("/images/af/image-holder.png", :class=>"thumb", :width=>"68", :height=>"68", :alt=>"user thumbnail", :title=>"#{a_camp.name}")
		end
	end
	def load_tiny(a_user)
		if a_user.main_photo
			image_tag(a_user.main_photo.public_filename('small') , :class=>"thumb", :alt=>"user thumbnail",:width=>"45", :title=>"#{a_user.short_name}")
		else
		  a_user.short_name ||= ""
			image_tag("/images/af/image-holder.png", :class=>"thumb", :alt=>"user thumbnail",:width=>"45", :title=>"#{a_user.short_name}")
		end
	end

end
