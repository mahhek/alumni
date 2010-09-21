class PolicyStatement < ActiveRecord::Base
  validates_presence_of :type_of_policy
  has_attachment  :content_type => ['application/pdf'],
                  :storage => :file_system,
                  :size => 0.kilobytes..10.megabytes

#  validates_as_attachment
end
