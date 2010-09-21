class AdminController < ApplicationController
  auto_complete_for :organization,:name

	helper UsersHelper
	helper PhotosHelper
  helper :form_table, :paginate, :managed_form
  before_filter :check_administrator_role
	def index
		
	end
  def create_new_organization
    has_error = false
    notice = ""

    if params[:organization_id] != "Select an Organization" && params[:new_organization][:joining_date] != "" && params[:new_organization][:expiry_date] != ""
      @org = NewOrganization.find_by_sql("select * from new_organizations where organization_id = #{params[:organization_id]} AND expiry_date > CURDATE()")
      
      if @org.size == 0
        @new_organizations = NewOrganization.new(params[:new_organization])
        @new_organizations.organization_id = params[:organization_id]
        @new_organizations.save
      else
        has_error = true
        notice = "Organization already exists in the list"
      end
    else
      has_error = true
      notice = "Select an Organization, Joining date and Expiry Date"
    end

    if has_error
      @new_organizations = NewOrganization.paginate(:per_page => 5, :conditions => ["expiry_date > CURDATE()"], :page=>params[:page], :order=> "joining_date desc")
      @organizations = Organization.find(:all)
      flash[:notice] = notice
      render :action =>"our_newest_members"
    else
      redirect_to :action =>"our_newest_members"
    end
  end
  
  def our_newest_members
    
        @new_organizations = NewOrganization.paginate(:per_page => 5, :conditions => ["expiry_date > CURDATE()"], :page=>params[:page], :order=> "joining_date desc")
        @organizations = Organization.find(:all)
  end
 def download_by_type
    @policy_statement = PolicyStatement.find_by_type_of_policy(params[:type_of])
    unless @policy_statement.nil?
      send_file("#{RAILS_ROOT}/public#{@policy_statement.public_filename}" ,:type => @policy_statement.content_type)
    else
      redirect_to :back
    end
 end
  def download
    @policy_statement = PolicyStatement.find_by_id(params[:id])
    send_file("#{RAILS_ROOT}/public#{@policy_statement.public_filename}" ,:type => @policy_statement.content_type)
  end
	
	def setting
   
		Admin.get(params[:k]).update_attribute(:setting, params[:v])
		flash[:notice] = "Your setting has been changed"
		redirect_to "/admin"
	end
  
  def edit_donate_what_this
    @donate_whats_this = DonateWhatsThis.find(:all).first
  end

  def policy_statements
    
    @privacy_policies = PolicyStatement.find(:all)
    
  end
  def donar_what_this_save
   puts "here we are"
    @whats_this = DonateWhatsThis.find(:all)

   if @whats_this.size == 0
     @donate = DonateWhatsThis.new(params[:donate_whats_this])
     puts @donate.save
   else
     @donate = DonateWhatsThis.find(:all).first
     @donate.content = params[:donate_whats_this][:content]
     puts @donate.save
   end

   redirect_to :controller=>"admin", :action=>"index"
   
  end

  def create_policy_statement

    has_error = false
    notice = ""
    
   if PolicyStatement.find_by_type_of_policy(params[:type_of_policy]).nil?
    @policy_statement = PolicyStatement.new(params[:policy_statement])
    @policy_statement.type_of_policy =  params[:type_of_policy]
    if @policy_statement.save
      has_error = false
    else
      has_error = true
      notice = "Policy Statement not uploaded"
    end
   else
     has_error = true
     notice = "Policy Statement alreay exists. Delete you existing policy statement and try again."
   end
   if has_error
      @privacy_policies = PolicyStatement.find(:all)
      flash[:notice] = notice
      render :action => "policy_statements"
   else
      @privacy_policies = PolicyStatement.find(:all)
       flash[:notice] = "Policy statement uploaded successfully"
       redirect_to :controller=> "admin", :action=>"policy_statements"
   end

  end

  def delete_privacy_statement

    @policy_statement = PolicyStatement.find_by_id(params[:id])
    
    if @policy_statement.destroy
      @privacy_policies = PolicyStatement.find(:all)
      flash[:notice] = "Policy Statement deleted successfully!!"
      redirect_to :controller=> "admin", :action=>"policy_statements"
   else
      @privacy_policies = PolicyStatement.find(:all)
       flash[:notice] = "Policy statement not deleted"
       render :action => "policy_statements"
       
   end
  end
end