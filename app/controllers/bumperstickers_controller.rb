class BumperstickersController < ApplicationController
	before_filter :admin_login_required,:except=>[:show,:edit,:create]
	before_filter :set_campaign, :only=>[:destroy]
	helper :campaigns
  

def admin_login_required
	if params[:id]
		if Bumpersticker.find(params[:id]).creator_id != logged_in_user.id
			check_admin_role('Administrator')
		end
	end
  end
  def index
	if is_administrator?
		@bumper_stickers = Bumpersticker.find(:all)
	else
		@bumper_stickers = Bumpersticker.find(:all,:conditions=>"creator_id=#{logged_in_user.id}")
	end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @bumper_stickers.to_xml(:dasherize=>false)}
    end
  end

  # GET /bumper_stickers/1
  # GET /bumper_stickers/1.xml
  def show
	@base_url = "http://#{request.host}"
	@base_url = "#{@base_url}:#{request.port}" if request.port != request.standard_port
    @bumper_sticker = Bumpersticker.find(params[:id])
	@campaign = @bumper_sticker.campaign
	set_site_branding_from_campaign
	@user = logged_in_user
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @bumper_sticker.to_xml(:dasherize=>false)}
    end
  end

  # GET /bumper_stickers/new
  # GET /bumper_stickers/new.xml
  def new
    @bumper_sticker = Bumpersticker.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @bumper_sticker }
    end
  end
    def new_sticker
	
    @campaign = Campaign.find(params[:campaign_id])
	@user = logged_in_user
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @bumper_sticker }
    end
  end

  # GET /bumper_stickers/1/edit
  def edit
    @bumper_sticker = Bumpersticker.find(params[:id])
  end

  # POST /bumper_stickers
  # POST /bumper_stickers.xml
  def create
    @bumper_sticker = Bumpersticker.new(params[:bumpersticker])

    respond_to do |format|
      if @bumper_sticker.save
        flash[:notice] = flash_msg('Your e-Bumper Sticker was saved.', %|Now <a href="/bumperstickers/#{@bumper_sticker.id}">send it</a> to your friends!|)
        format.html { redirect_to("/bumperstickers/#{@bumper_sticker.id}") }
        format.xml  { render :xml => @bumper_sticker, :status => :created, :location => @bumper_sticker }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @bumper_sticker.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /bumper_stickers/1
  # PUT /bumper_stickers/1.xml
  def update
    @bumper_sticker = Bumpersticker.find(params[:id])

    respond_to do |format|
      if @bumper_sticker.update_attributes(params[:bumpersticker])
        flash[:notice] = 'Your e-Bumper Sticker was saved.'
        format.html { redirect_to(@bumper_sticker) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @bumper_sticker.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /bumper_stickers/1
  # DELETE /bumper_stickers/1.xml
  def destroy
	@bumper_sticker = Bumpersticker.find(params[:id])
	if @bumper_sticker.destroy
		flash[:notice] = "Your e-Bumper Sticker was deleted."
	end
	
    respond_to do |format|
      format.html { redirect_to("/campaigns/campaign_stickers?campaign_id=#{@campaign.id}") }
      format.xml  { head :ok }
    end
  end
end
