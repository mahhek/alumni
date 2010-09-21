class CampaignPhoto < Photo
	has_attachment :storage => :file_system,
					:resize_to => '500x500>',
					:thumbnails => {:reg=>'198x173!',:thumb => '122x73!', :small=>'66x66!',:gallery=>'273x230!'},
					:size => 0.megabytes..5.megabytes,
					:content_type => :image,
					:processor => 'Rmagick'
	validates_as_attachment
end
