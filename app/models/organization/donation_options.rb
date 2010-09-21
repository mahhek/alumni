class Organization < ActiveRecord::Base
	serialize :multiple_choice_donations
	def donation_options
		DonationOptions.new(
			:categories_switch => !multiple_choice_donations.blank?,
			:named_categories => multiple_choice_donations.is_a?(Hash),
			:categories => multiple_choice_donations
		)
	end
end

class DonationOptions
	attr_accessor :categories_switch, :named_categories, :categories
	def initialize(args={})
		args.each do |k, v|
			send("#{k}=", v)
		end
	end
	
	def json_categories
		if named_categories
			json_array = []
			categories.each do |k, v|
				json_array << [k, v]
			end
			json_array.sort.to_json
		else
			categories.to_a.to_json
		end
	end
	
	def size
		return 0 if categories.to_s.blank?
		return categories.keys.size if named_categories
		return categories.size if categories.is_a? Array
		return 0
	end
	
	def sorted_categories    
		return categories.keys.sort
	end
		
end