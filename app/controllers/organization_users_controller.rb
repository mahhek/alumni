class OrganizationUsersController < ApplicationController
  # GET /organization_users
  # GET /organization_users.xml
  layout 'application'
  before_filter :check_administrator_role , :only => [:index,:new]

  def index
    @organization_users = OrganizationUser.find(:all)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @organization_users }
    end
  end

  # GET /organization_users/new
  # GET /organization_users/new.xml
  def new
    @organizations = Organization.find(:all)
    @organization_user = OrganizationUser.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @organization_user }
    end
  end

  # POST /organization_users
  # POST /organization_users.xml
  def create
    puts "===#{params.dup}"
  options = params.dup
	options[:organization_user][:status] = OrganizationUser::INITIAL
	user = User.find_by_id(options[:organization_user][:user_id])
	if user.nil?
		flash[:error] = "You must pick a user to become an admin."
		redirect_to "/organization_users/new"
    puts "after redirect"
		return false
	end  
    @organization_user = OrganizationUser.new(options[:organization_user])     
    respond_to do |format|
      if @organization_user.save
        User.find(options[:organization_user][:user_id]).roles << Role.find_by_name('OrganizationUser')
        flash[:notice] = 'Organization User was successfully created.'
        format.html { redirect_to "/organization_users" }
        format.xml  { render :xml => @organization_user, :status => :created, :location => @organization_user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @organization_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /organization_users/1
  # DELETE /organization_users/1.xml
  def destroy
    @organization_user = OrganizationUser.find(params[:id])
    @organization_user.destroy

    respond_to do |format|
      format.html { redirect_to(organization_users_url) }
      format.xml  { head :ok }
    end
  end
end
