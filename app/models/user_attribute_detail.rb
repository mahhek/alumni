class UserAttributeDetail < ActiveRecord::Base
	belongs_to :user
	belongs_to :user_attribute
	stampable
end
