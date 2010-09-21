class CampaignUsersController < ApplicationController
  # GET /campaign_users
  # GET /campaign_users.xml

helper :campaigns
before_filter :admin_login_required, :except=>[:create,:new]
before_filter :login_required
  
  def admin_login_required
	check_admin_role('Administrator')
  end

  def index
    @campaign_users = CampaignUser.find(:all)
	
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @campaign_users }
    end
  end

  # GET /campaign_users/1
  # GET /campaign_users/1.xml
  def show
    @campaign_users = CampaignUser.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @campaign_users }
    end
  end

  # GET /campaign_users/new
  # GET /campaign_users/new.xml
  def new
	@campaign = Campaign.find(params[:campaign_id])   
    @campaign_user = CampaignUser.new(
      :user => logged_in_user, 
      :campaign => @campaign,
      :ok_to_send => true,
      :status => params[:new_status] || CampaignUser::REQUESTED
    )
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @campaign_user }
    end
  end

  # GET /campaign_users/1/edit
  def edit
    @campaign_users = CampaignUser.find(params[:id])
  end

  # POST /campaign_users
  # POST /campaign_users.xml
  def create
	options = params[:campaign_user].dup
    options[:status] = CampaignUser::REQUESTED
    @campaign_users = CampaignUser.new(options)

    if @campaign_users.save
        @campaign_users.request_membership
		flash[:notice] = 'Your request has been sent to the fundraising page owner'
        redirect_to(@campaign_users.campaign)
    else
      render :action => "new"
    end
  end

  # PUT /campaign_users/1
  # PUT /campaign_users/1.xml
  def update
    @campaign_users = CampaignUser.find(params[:id])

    respond_to do |format|
      if @campaign_users.update_attributes(params[:campaign_user])
        flash[:notice] = 'Fundraising page user was successfully updated.'
        format.html { redirect_to(@campaign_users) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @campaign_users.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /campaign_users/1
  # DELETE /campaign_users/1.xml
  def destroy
    @campaign_users = CampaignUser.find(params[:id])
    @campaign_users.destroy

    respond_to do |format|
      format.html { redirect_to(campaign_users_url) }
      format.xml  { head :ok }
    end
  end
end
