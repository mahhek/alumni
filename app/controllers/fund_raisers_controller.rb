class FundRaisersController < ApplicationController
  
  # GET /fund_raisers
  # GET /fund_raisers.xml
  def index
    @fund_raisers = FundRaiser.find(:conditions=>["organization_id=?", params[:organization_id]] )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fund_raisers }
    end
  end

  def campaign_fund_view
    
  	org = Organization.find(params[:organization_id])
    fund_raisers = FundRaiser.find(:all,:conditions=>["organization_id=?", params[:organization_id]])

    
    render :update do |page|
      page["funds_for_school"].replace_html :partial=>'campaign_fund_view',:locals=>{:fund_raisers=>fund_raisers}
      if org.who_will_choose_fund == "the_donors" || org.who_will_choose_fund == "all_gifts_will_be_unrestritced"
        page["funds_for_school"].hide
      end
      page["school_class_years"].replace_html :partial=>'school_class_years' ,:locals=>{:org=>org}
    end
      
  end

  def funds_for_org
    @fund_raisers = FundRaiser.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fund_raisers }
    end
  end
  # GET /fund_raisers/1
  # GET /fund_raisers/1.xml
  def show
    @fund_raiser = FundRaiser.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @fund_raiser }
    end
  end

  # GET /fund_raisers/new
  # GET /fund_raisers/new.xml
  def new
    @fund_raiser = FundRaiser.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @fund_raiser }
    end
  end

  # GET /fund_raisers/1/edit
  def edit
    @fund_raiser = FundRaiser.find(params[:id])
  end

  # POST /fund_raisers
  # POST /fund_raisers.xml
  def create
    @fund_raiser = FundRaiser.new(params[:fund_raiser])
    respond_to do |format|
      if @fund_raiser.save
        flash[:notice] = 'Fund was successfully created.'
		fund_raisers = FundRaiser.find(:all,:conditions=>["organization_id=?", @fund_raiser.organization_id] )
        format.html { render :partial=>'fund_list' ,:locals=>{:fund_raisers=>fund_raisers},:layout=>false}
        format.xml  { render :xml => @fund_raiser, :status => :created, :location => @fund_raiser }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @fund_raiser.errors, :status => :unprocessable_entity }
      end
    end
	flash.clear
  end

  # PUT /fund_raisers/1
  # PUT /fund_raisers/1.xml
  def update
    @fund_raiser = FundRaiser.find(params[:id])

      if @fund_raiser.update_attributes(params[:fund_raiser])
        flash[:notice] = 'Fund was successfully updated.'
        redirect_to "/organizations/manage/#{@fund_raiser.organization_id}"
      else
        render :action => "edit"
      end
  end

  # DELETE /fund_raisers/1
  # DELETE /fund_raisers/1.xml
  def destroy
    @fund_raiser = FundRaiser.find(params[:id])
	organization = @fund_raiser.organization
	
	if @fund_raiser.campaigns.empty?
    	@fund_raiser.destroy
		flash[:notice] = "Fund '#{@fund_raiser.name}' successfully deleted"
	else
		flash[:error] = "You cannot delete a fund with campaigns"
	end
    respond_to do |format|
      fund_raisers = FundRaiser.find(:all,:conditions=>["organization_id=?", organization.id] )
      format.html { render :partial=>'fund_list' ,:locals=>{:fund_raisers=>fund_raisers},:layout=>false }
      format.xml  { head :ok }
    end
	flash.clear
  end
end
