class MyAccountController < ApplicationController

	helper PhotosHelper
	helper UsersHelper

	before_filter :login_required
	before_filter :set_user

	def profile
		@questions = UserAttribute.find(:all, :order => "order_number")
	end

	def photo
		@photo = @user.main_photo
	end
	def password

	end

	def update
		@user = User.find(logged_in_user)
		if params[:user][:password]
			# if User.encrypt(params[:old_password]) != @user.hashed_password
			# 	flash[:notice] = "Your old password doesn't match your current password"
			# 	redirect_to "/my_account/password"
			# 	return
			# end
			
			if @user.update_attributes(params[:user])
				logger.info "WTF ***********************#{@user.hashed_password.blank?}|||||"
				logger.info "WTF ***********************#{@user.password.blank?}|||||"
				logger.info "WTF ***********************#{@user.password_required?}|||||"
				flash[:notice] = "Your password has been changed."
			else
				flash[:notice] = "Your new password must be over 5 characters and match the confirmation"
				redirect_to "/my_account/password"
				return
			end
		elsif params[:user][:first_name] && @user.update_attributes(params[:user])
			flash[:notice] = "Your information has successfully been updated."
		elsif @user.update_attributes(params[:user])
			flash[:notice] = "Your profile has been updated."
		end
		redirect_to "/profiles/show/"
	end

	def create_user_photo
		@photo = UserPhoto.new(params[:photo])
		if @photo.save
			@user.user_photos.each {|pp| pp.destroy}
			@user.user_photos << @photo
			@user.save
			flash[:notice] = 'Your profile photo has been updated.'
			redirect_to "/profiles/show/"
		else
			@photo = @user.main_photo
			render :action => :photo
		end
	end


	private

	def set_user
		@user = logged_in_user
	end

end
