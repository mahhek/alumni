module CampaignsHelper

	def default_photo(obj)
		return obj.main_photo if obj.main_photo
		return obj.user_photos.first if obj.respond_to? :user_photos
		return obj.organization_photos.first if obj.respond_to? :organization_photos
	end

	def load_full(a_camp)
		photo = default_photo(a_camp)
		if photo
			image_tag(photo.public_filename('reg') , :class=>"pic", :alt=>"user picture", :title=>"#{a_camp.name}")
		else
			a_camp.name ||= ""
			image_tag("/images/af/organization_photo_reg.png", :class=>"pic", :alt=>"user picture", :title=>"#{a_camp.name}")
		end
	end

	def load_featured(a_camp)
		photo = default_photo(a_camp)
		if photo
			image_tag(a_camp.main_photo.public_filename('featured') , :class=>"pic", :alt=>"user thumbnail", :title=>"#{a_camp.name}")
		end
	end

	def load_small(a_camp)
		photo = default_photo(a_camp)
		if photo
			image_tag(photo.public_filename('small') , :class=>"thumb", :alt=>"user thumbnail", :title=>"#{a_camp.name}")
		else
			""
		end
	end

	def load_tiny(a_camp)
		photo = default_photo(a_camp)
		if photo
			image_tag(photo.public_filename('small') , :class=>"thumb", :alt=>"user thumbnail",:width=>"45", :title=>"#{a_camp.name}")
		else
			a_camp.name ||= ""
			image_tag("/images/sitewide/images/default_member_thumbmd.jpg", :class=>"thumb", :alt=>"user thumbnail",:width=>"45", :title=>"#{a_camp.name}")
		end
	end

	def setup_yield
		case(@campaign.status)
		when Campaign::ACTIVE
			define_controls
		end
	end

	def define_controls

		# Contributors
		contrib_data = ""

		content_for :campaign_link do
			"<li id='ns01' class='first'><a href='/#{@campaign.url}.html'>#{@campaign.name[0..30]} </a></li>"
		end

		content_for :contributors do
			contrib_data
		end
	end

	def can_delete_comment(comment)
		return false unless logged_in_user
		return true if comment.creator.id == logged_in_user.id
		return true if logged_in_user == @campaign.creator.id
		return true if is_administrator?
		return true if @campaign.organization.has_user(logged_in_user)
		false
	end

	def user_is_member
		return false unless logged_in_user
		logged_in_user.id == @campaign.creator_id or @campaign.is_member?(logged_in_user)
	end
end
