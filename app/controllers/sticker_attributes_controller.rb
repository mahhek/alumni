class StickerAttributesController < ApplicationController
	helper :campaigns
	
	before_filter :set_bumper_sticker_template, :only=>[:show, :sticker_creater, :edit, :upload_image, :update, :destroy]
	before_filter :set_campaign, :only=>:sticker_creater
	before_filter :set_organization, :only=>[:index, :new]
	before_filter :set_organization_from_template, :only=>[:show, :edit, :upload_image]
	before_filter :set_org_nav, :only=>:index
	
  # GET /sticker_attributes
  # GET /sticker_attributes.xml
  def index
	 if @organization
		@sticker_attributes = @organization.sticker_attributes
		set_site_branding(@organization)
	 else
		@sticker_attributes = StickerAttribute.find(:all,:conditions=>"parent_id is null")
	 end
    

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sticker_attributes }
    end
  end

  # GET /sticker_attributes/1
  # GET /sticker_attributes/1.xml
  def show
	set_site_branding_from_org
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @sticker_attribute.to_xml() }
    end
  end
  def sticker_creater
	@user = logged_in_user
	@campaign = Campaign.find(params[:campaign_id])
	set_site_branding_from_campaign
  end
  # GET /sticker_attributes/new
  # GET /sticker_attributes/new.xml
  def new
    @sticker_attribute = StickerAttribute.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @sticker_attribute }
    end
  end

  # GET /sticker_attributes/1/edit
  def edit
	set_site_branding_from_org
  end

  # POST /sticker_attributes
  # POST /sticker_attributes.xml
  def create
    @sticker_attribute = StickerAttribute.new(params[:sticker_attribute])

    respond_to do |format|
      if @sticker_attribute.save
        flash[:notice] = 'StickerAttribute was successfully created.'
        format.html { redirect_to :action=> :upload_image,:id=>@sticker_attribute.id }
        format.xml  { render :xml => @sticker_attribute, :status => :created, :location => @sticker_attribute }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @sticker_attribute.errors, :status => :unprocessable_entity }
      end
    end
  end
   def upload_image
	set_site_branding_from_org
	@photo =StickerAttributePhoto.new
   end
 def create_sa_photo
		@photo = StickerAttributePhoto.new(params[:photo])
		@sticker_attribute = StickerAttribute.find(params[:sticker_attribute_id])
		if @photo.save
			@sticker_attribute.sticker_attribute_photos << @photo
			flash[:notice] = 'Your picture has been uploaded.'
			redirect_to :action=> :upload_image,:id=>params[:sticker_attribute_id]
		else
			redirect_to :action=> :upload_image,:id=>params[:sticker_attribute_id]
		end
	end
  # PUT /sticker_attributes/1
  # PUT /sticker_attributes/1.xml
  def update

    respond_to do |format|
      if @sticker_attribute.update_attributes(params[:sticker_attribute])
        flash[:notice] = 'Your e-Bumper Sticker template was successfully updated.'
        format.html { redirect_to(@sticker_attribute) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @sticker_attribute.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sticker_attributes/1
  # DELETE /sticker_attributes/1.xml
  def destroy
	org = @sticker_attribute.organization_id
    @sticker_attribute.destroy

    respond_to do |format|
      format.html { redirect_to("/sticker_attributes?organization_id=#{org}") }
      format.xml  { head :ok }
    end
  end

  def destroy_photo
		@photo = StickerAttributePhoto.find(params[:id])
		if @photo.destroy
			flash[:notice] = "Your photo has been removed."
		else
			flash[:error] = "Your photo could not be removed. Please try again later."
		end
		redirect_to :action=> :upload_image,:id=>params[:sticker_attribute_id]
  end
	
	
	private
	
	def set_bumper_sticker_template
		@sticker_attribute = StickerAttribute.find(params[:id])
	end
	
	def set_organization_from_template
		@organization = @sticker_attribute.organization
	end
end
