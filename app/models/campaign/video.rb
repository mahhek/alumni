class Campaign < ActiveRecord::Base
	before_save :extract_embeded_video_url
	before_save :resize_main_video
	validate :has_youtube_code
	require 'app/models/video'
	include Video
	
	def extract_embeded_video_url
		unless embeded_video.blank?
			self.embeded_video = embeded_video.match(Video::URI_PATTERN).to_s
		end
	end
	
	def resize_main_video
		resize_video main_embeded_video
	end
	
	def has_youtube_code
		unless main_embeded_video.blank?
			width = extract_num main_embeded_video, Video::WIDTH_ATTRIBUTE
			height = extract_num main_embeded_video, Video::HEIGHT_ATTRIBUTE
		
			if width.nil? || height.nil?
				self.main_embeded_video = ""
				errors.add(:main_embeded_video, "needs to have 'embed' code from youtube")
			end
		end
	end
	
end