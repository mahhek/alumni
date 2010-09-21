class StickerAttribute < ActiveRecord::Base
	after_save :save_events
	stampable
	has_many :sticker_attribute_photos, :order=>'created_at desc', :as => :interface
	belongs_to :organization
	
	def save_events
		primary_colors.each {|color| color.destroy}
		secondary_colors.each {|color| color.destroy}
		if @primary_colors
			@primary_colors.each do |a_color|
				StickerAttribute.create!(:organization_id=>self.organization_id,:parent_id=>self.id,:attribute_name=>'PrimaryColor',:attribute_value=>a_color)
			end
		end
		if @secondary_colors
			@secondary_colors.each do |a_color|
				StickerAttribute.create!(:organization_id=>self.organization_id,:parent_id=>self.id,:attribute_name=>'SecondaryColor',:attribute_value=>a_color)
			end
		end
	end
	
  def to_xml(options = {})
      options[:indent] ||= 2
      xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
      xml.instruct! unless options[:skip_instruct]
	  xml.sticker_attributes do
		write_primary_colors(xml)
		write_secondary_colors(xml)
		write_images(xml)
	end
   end
   def write_primary_colors(xml)
		xml.primary_colors do
			primary_colors.each do |pc|
				xml.color do 
					xml.tag!(:colorText, pc.attribute_value)
					xml.tag!(:colorValue,pc.attribute_value)
				end
			end
		end
	end
	def write_secondary_colors(xml)
		xml.secondary_colors do
			secondary_colors.each do |sc|
				xml.color do 
					xml.tag!(:colorText, sc.attribute_value)
					xml.tag!(:colorValue, sc.attribute_value)
				end
			end
		end
	end
	def write_images(xml)
		xml.images do
			sticker_attribute_photos.each do |photo|
				xml.image do 
					xml.tag!(:image_url, photo.public_filename('small'))
				end
			end
			
		end
	end
	def primary_colors=(collection=[])
		@primary_colors ||= collection
	end
	def secondary_colors=(collection=[])
		@secondary_colors ||= collection
	end
	def primary_colors
		StickerAttribute.find(:all,:conditions=>["parent_id=? and attribute_name='PrimaryColor'", self.id])
	end
	def secondary_colors
		StickerAttribute.find(:all,:conditions=>["parent_id=? and attribute_name='SecondaryColor'", self.id])
	end
	
	def creator
		User.find(creator_id)
	end
end
