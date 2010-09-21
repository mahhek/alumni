class ProfilesController < ApplicationController
     helper PhotosHelper

     before_filter :login_required
     before_filter :set_user

  
  # GET /profiles
  # GET /profiles.xml
  def index
    @profiles = Profile.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @profiles }
    end
  end

  # GET /profiles/1
  # GET /profiles/1.xml
  def show
    
    @user = logged_in_user    
    @questions = logged_in_user.user_attribute_details    
    @change_list = ContentManager.calculate_change_list(@user)    
    @campaigns_to_show = 5
    @owned_campaigns = logged_in_user.owned_campaigns.not_deleted
    @is_org_user = @user.has_role? "OrganizationUser"
    @orgs = OrganizationUser.find_all_by_user_id(@user.id).map(&:organization) if @is_org_user

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @profile }
    end
  end

  # GET /profiles/new
  # GET /profiles/new.xml

  def new
    @profile = Profile.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @profile }
    end
  end

  # GET /profiles/1/edit
  def edit
    @profile = Profile.find(params[:id])
  end

  # POST /profiles
  # POST /profiles.xml
  def create
    @profile = Profile.new(params[:profile])

    respond_to do |format|
      if @profile.save
        flash[:notice] = 'Profile was successfully created.'
        format.html { redirect_to(@profile) }
        format.xml  { render :xml => @profile, :status => :created, :location => @profile }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @profile.errors, :status => :unprocessable_entity }
      end
    end
  end
  def delete_campaign_user
    campaign_user = CampaignUser.find(params[:id]).update_attributes(:status=>CampaignUser::DELETED)
    redirect_to :controller=>:profiles,:action=>:show,:id=>1
  end

  def delete_campaign
     campaign = Campaign.find(params[:id])
     campaign.update_attributes(:status => Campaign::DELETED)
     flash[:notice] = "Fundraising Page #{campaign.name} was successfully deleted."
     redirect_to :controller=>:profiles,:action=>:show,:id=>1
  end

  def close_campaign
     campaign = Campaign.find(params[:id])
     campaign.update_attributes(:status=>Campaign::CLOSED)
     redirect_to :controller=>:profiles,:action=>:show,:id=>1
  end

  def reopen_campaign
     campaign = Campaign.find(params[:id])
     campaign.update_attributes(:status=>Campaign::ACTIVE)
     redirect_to :controller=>:profiles,:action=>:show,:id=>1
  end

  # PUT /profiles/1
  # PUT /profiles/1.xml
  def update
    @profile = Profile.find(params[:id])

    respond_to do |format|
      if @profile.update_attributes(params[:profile])
        flash[:notice] = 'Profile was successfully updated.'
        format.html { redirect_to(@profile) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @profile.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /profiles/1
  # DELETE /profiles/1.xml
  def destroy
    @profile = Profile.find(params[:id])
    @profile.destroy

    respond_to do |format|
      format.html { redirect_to(profiles_url) }
      format.xml  { head :ok }
    end
  end
  private

     def set_user
          @user = logged_in_user
     end

end
