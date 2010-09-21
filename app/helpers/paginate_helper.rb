module PaginateHelper
	def link_to_sort(name, for_params=[])
		href = "?sort=#{name.downcase}"
		
		for_params.each do |param|
			href += "&#{param}=#{params[param]}" if params[param]
		end
		
		if params[:order] == "desc" && params[:sort] == name.downcase
			href += "&order=asc"
		else
			href += "&order=desc"
		end
		%|<a href="#{href}">#{name}</a>|
	end
end