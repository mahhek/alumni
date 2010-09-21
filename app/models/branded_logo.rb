class BrandedLogo < Photo
	has_attachment :storage => :file_system,
					:resize_to => '350x65>',
					:size => 0.megabytes..5.megabytes,
					:content_type => :image
#					:processor => 'Rmagick'
	validates_as_attachment
end
