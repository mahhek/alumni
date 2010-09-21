class OrgRegAttachment < ActiveRecord::Base
  has_attachment :storage => :file_system,
				 :max_size => 5.megabytes
  validates_as_attachment
end
