class OrganizationUser < ActiveRecord::Base
 INITIAL=0
  belongs_to :organization
  belongs_to :user
end
