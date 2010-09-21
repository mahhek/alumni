class School < ActiveRecord::Base
	def self.find_by_partial_name(partial_name, opts={})
		search_term = "%#{partial_name}%"
		search_opts = {:conditions=>[ "name like ?", search_term]}
		search_opts.merge!(opts)
		find(:all, search_opts)
	end
end
