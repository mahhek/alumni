class StickerAttributePhoto < Photo
	has_attachment :storage => :file_system,
					:resize_to => '500x500>',
					:thumbnails => {:small=>'66x66!'},
					:size => 0.megabytes..5.megabytes,
					:content_type => :image,
					:processor => 'Rmagick'
	validates_as_attachment
end