class SuspendedController < ApplicationController
	def index
		@organization = Organization.find(params[:org])
	end
end