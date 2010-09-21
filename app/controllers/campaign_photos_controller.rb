class CampaignPhotosController < ApplicationController
  def destroy
  	@photo = CampaignPhoto.find(params[:id])
	campaign = Campaign.find(@photo.interface_id)
	
  	if @photo.destroy
		logger.info "*"*20 + "PHOTO:#{@photo.main_image?}"
		if @photo.main_image?
			campaign.pick_new_main_photo
		end
  		flash[:notice] = "Your picture has been removed."
  	else
  		flash[:error] = "Your picture could not be removed. Please try again later."
  	end
  	redirect_to :controller => :campaigns, :action=>'upload_image',:campaign_id=>campaign.id
  end
end
