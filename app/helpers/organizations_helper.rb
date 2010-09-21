module OrganizationsHelper
    def load_full(a_camp)
		if a_camp.main_photo
			image_tag(a_camp.main_photo.public_filename('reg') , :class=>"pic", :alt=>"user picture", :title=>"#{a_camp.name}")
		else
		  a_camp.name ||= ""
			image_tag("/images/af/organization_photo_reg.png", :class=>"pic", :alt=>"user picture", :title=>"#{a_camp.name}")
		end
	end
	def load_featured(a_camp)
		if a_camp.main_photo
			image_tag(a_camp.main_photo.public_filename('featured') , :class=>"pic", :alt=>"user thumbnail", :title=>"#{a_camp.name}")
		end
	end
	def load_small(a_camp)
		if a_camp.main_photo
			image_tag(a_camp.main_photo.public_filename('small') , :alt=>"user thumbnail", :title=>"#{a_camp.name}")
		else
		  a_camp.name ||= ""
			image_tag("/images/af/image-holder.png", :alt=>"user thumbnail", :title=>"#{a_camp.name}", :width=>"68" ,:height=>"68")
		end
	end
  def load_small_branded_logo(a_camp)
		if a_camp.branded_logo
			image_tag(a_camp.branded_logo.public_filename , :alt=>"branded logo", :title=>"#{a_camp.name}")
		else
		  a_camp.name ||= ""
			image_tag("/images/af/image-holder.png", :alt=>"branded logo", :title=>"#{a_camp.name}", :width=>"68" ,:height=>"68")
		end
	end
	def load_tiny(a_camp)
		if a_camp.main_photo
			image_tag(a_camp.main_photo.public_filename('small') , :class=>"thumb", :alt=>"user thumbnail",:width=>"45", :title=>"#{a_camp.name}")
		else
		  a_camp.name ||= ""
			image_tag("/images/sitewide/images/default_member_thumbmd.jpg", :class=>"thumb", :alt=>"user thumbnail",:width=>"45", :title=>"#{a_camp.name}")
		end
	end
	def setup_yield
		if @user && (@organization.creator.id == @user.id || @organization.user_is_org_user(@user))
          @show_org_menu = true
		end
	end
end
