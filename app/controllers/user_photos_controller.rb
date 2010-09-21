class UserPhotosController < ApplicationController
  
  def destroy
	@user = logged_in_user
  	@photo = @user.user_photos.find(params[:id])
  	if @photo.destroy
  		flash[:notice] = "Your profile picture has been removed."
  	else
  		flash[:error] = "Your picture could not be removed. Please try again later."
  	end
  	redirect_to "/my_account/photo"
  end
    
end
