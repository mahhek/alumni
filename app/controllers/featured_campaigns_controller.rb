class FeaturedCampaignsController < ApplicationController
  # GET /admin_featured_campaigns
  # GET /admin_featured_campaigns.xml
  layout 'application'
  before_filter :check_administrator_role , :only => [:index]
  def index
    @featured_campaigns = FeaturedCampaign.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @featured_campaigns }
    end
  end

  # GET /admin_featured_campaigns/1
  # GET /admin_featured_campaigns/1.xml
  def show
    @featured_campaign = FeaturedCampaign.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @featured_campaign }
    end
  end

  # GET /admin_featured_campaigns/new
  # GET /admin_featured_campaigns/new.xml
  def new
    @featured_campaign = FeaturedCampaign.new
	@campaigns = Campaign.find(:all, :conditions => { :public => true, :status => Campaign::ACTIVE } )
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @featured_campaign }
    end
  end

  # GET /admin_featured_campaigns/1/edit
  def edit
    @featured_campaign = FeaturedCampaign.find(params[:id])
  end

  # POST /admin_featured_campaigns
  # POST /admin_featured_campaigns.xml
  def create
    @featured_campaign = FeaturedCampaign.new(params[:featured_campaign])

    respond_to do |format|
      if @featured_campaign.save
        flash[:notice] = 'FeaturedCampaign was successfully created.'
        format.html { redirect_to(:controller=>'featured_campaigns') }
        format.xml  { render :xml => @featured_campaign, :status => :created, :location => @featured_campaign }
      else
	  @campaigns = Campaign.find(:all)
        format.html { render :action => "new" }
        format.xml  { render :xml => @featured_campaign.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /admin_featured_campaigns/1
  # PUT /admin_featured_campaigns/1.xml
  def update
    @featured_campaign = FeaturedCampaign.find(params[:id])

    respond_to do |format|
      if @featured_campaign.update_attributes(params[:featured_campaign])
        flash[:notice] = 'FeaturedCampaign was successfully updated.'
       format.html { redirect_to(:controller=>'featured_campaigns') }
        format.xml  { head :ok }
      else
	   @campaigns = Campaign.find(:all)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @featured_campaign.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_featured_campaigns/1
  # DELETE /admin_featured_campaigns/1.xml
  def destroy
    @featured_campaign = FeaturedCampaign.find(params[:id])
    @featured_campaign.destroy

    respond_to do |format|
      format.html { redirect_to(:controller=>'featured_campaigns') }
      format.xml  { head :ok }
    end
  end
end
