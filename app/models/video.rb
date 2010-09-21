module Video
	URI_PATTERN = /http:\/\/[^"']*/.freeze
	MAX_VIDEO_WIDTH = 360.freeze
	WIDTH_ATTRIBUTE = /width=["'](\d+)["']/i.freeze
	HEIGHT_ATTRIBUTE = /height=["'](\d+)["']/i.freeze
	
	def extract_num(text, dimension)
		unless text.blank?
			data = dimension.match(text)
			return data[1].to_i if data
		end
		nil
	end
	
	def has_wmode_tags(text)
		/wmode/i.match(text)
	end
	
	def add_wmode_tags(text)
		text = text.gsub(/<\/object>/i, "<param name='wmode' value='opaque'></object>")
		text = text.gsub(/<embed\s+/i, "<embed wmode='opaque' ")
		text
	end
	
	def resize_video(text)
		unless text.blank?
			width = extract_num text, Video::WIDTH_ATTRIBUTE
			height = extract_num text, Video::HEIGHT_ATTRIBUTE
			
			if width.nil? || height.nil?
				return ""
			end
			
			if (width.to_i > Video::MAX_VIDEO_WIDTH)
				height = height * Video::MAX_VIDEO_WIDTH / width
				width = Video::MAX_VIDEO_WIDTH
				text.gsub!(Video::WIDTH_ATTRIBUTE, "width='#{width}'")
				text.gsub!(Video::HEIGHT_ATTRIBUTE, "height='#{height}'")
			end
			text = add_wmode_tags(text) unless has_wmode_tags(text)
		end
		text
	end
	
end