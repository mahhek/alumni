class UserPhoto < Photo
	has_attachment :storage => :file_system,
					:resize_to => '500x500>',
					:thumbnails => {:profile=>'150x200!' ,:thumb => '87x87!',:small=>'66x66!'},
					:size => 0.megabytes..5.megabytes,
					:content_type => :image,
					:processor => 'Rmagick'
	validates_as_attachment
end