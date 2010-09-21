class OrganizationPhoto < Photo
	has_attachment :storage => :file_system,
					:resize_to => '600x600>',
					:thumbnails => {:reg=>'200x200>',:thumb => '150x150>', :small=>'100x100>'},
					:size => 0.megabytes..5.megabytes,
					:content_type => :image
#					:processor => 'Rmagick'
	validates_as_attachment
end
