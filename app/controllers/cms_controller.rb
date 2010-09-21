class CmsController < ApplicationController
	layout nil
	
	def edit
		c = CMS.find_by_tag(params[:cms][:tag])
		if c
			c.content =  params[:cms][:content]
			c.save!
			logger.debug "wtf"
		else
			CMS.create(params[:cms])
		end
		redirect_to params[:goto]
	end
end