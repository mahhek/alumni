class UserBroadcastsController < ApplicationController
  helper CampaignsHelper
  

  before_filter :load_campaign

  # GET /user_broadcasts
  # GET /user_broadcasts.xml
  def index
    @user_broadcasts = UserBroadcast.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @user_broadcasts }
    end
  end

  # GET /user_broadcasts/1
  # GET /user_broadcasts/1.xml
  def show
    @user_broadcast = UserBroadcast.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user_broadcast }
    end
  end

  # GET /user_broadcasts/new
  # GET /user_broadcasts/new.xml
  def new
    @user_broadcast = UserBroadcast.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user_broadcast }
    end
  end

  # GET /user_broadcasts/1/edit
  def edit
	@user_broadcast = UserBroadcast.new
	@campaigns = logged_in_user.all_associated_campaigns.active
	if logged_in_user.has_role?('OrganizationUser')
		OrganizationUser.find_all_by_user_id(logged_in_user.id).each do |o|
			@campaigns += o.organization.campaigns.active
		end
	end
	@campaigns.uniq!
	@broadcasts_options = UserBroadcast.create_broadcast_hash(logged_in_user, @campaigns)
  end

  # POST /user_broadcasts
  # POST /user_broadcasts.xml
  def create
    @user_broadcast = UserBroadcast.new(params[:user_broadcast])

    respond_to do |format|
      if @user_broadcast.save
        flash[:notice] = 'User Broadcast was successfully created.'
        format.html { redirect_to(@user_broadcast) }
        format.xml  { render :xml => @user_broadcast, :status => :created, :location => @user_broadcast }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user_broadcast.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /user_broadcasts/1
  # PUT /user_broadcasts/1.xml
  def update
    UserBroadcast.update_settings(params[:settings],logged_in_user)
    respond_to do |format|
        flash[:notice] = 'Your notification settings have been saved.'
        format.html { redirect_to "/profiles/show/" }
        format.xml  { head :ok }
    end
  end

  # DELETE /user_broadcasts/1
  # DELETE /user_broadcasts/1.xml
  def destroy
    @user_broadcast = UserBroadcast.find(params[:id])
    @user_broadcast.destroy

    respond_to do |format|
      format.html { redirect_to(user_broadcasts_url) }
      format.xml  { head :ok }
    end
  end

  private

  def load_campaign
    id = params[:campaign_id] || session[:campaign_id]
    @campaign = Campaign.find(id) if id
  end
end
