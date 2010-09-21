require "lib/view_helpers"

class Bumpersticker < ActiveRecord::Base
	belongs_to :campaign
	def participantnumber
		campaign ? (campaign.active_donors) : 0
	end
	def get_imageurl
		if imageurl
			imageurl
		else
			"/images/af/image-holder.png"
		end
	end
	def currentfunds
		view_helper.number_to_currency(self.campaign.currentAmount)
	end
	
	def creator
		User.find(creator_id)
	end
	
	def to_flash_params(url=nil)
		params = self.attributes
		params["participantnumber"] = self.participantnumber
		params["currentfunds"] = self.currentfunds
		params["textcolor"] = Bumpersticker.text_color(self.secondarycolor)
		params["button_textcolor"] = Bumpersticker.text_color(self.primarycolor)
		params["bumper_sticker_id"] = self.id
		params["imageurl"] = self.get_imageurl
		params["base_url"] = "#{CGI.escape(url)}"
		params["name"] = self.name.gsub("'", "&#39;")
		params["stickertext"] = self.name.gsub("'", "&#39;")
		params = params.to_a
		params = params.map{ |pair| pair.join("=") }
		params = params.join("&")
		params
	end
	
	def self.text_color(base_color)
		r = base_color[0..1].to_i(16)
		g = base_color[2..3].to_i(16)
		b = base_color[4..5].to_i(16)
		avg = (r+g+b).to_f / 3
		if avg >= 127.5
			"000000"
		else
			"FFFFFF"
		end
	end
end
