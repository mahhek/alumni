class TextModulesController < ApplicationController
  
  
  before_filter :admin_login_required
  before_filter :login_required
  
  def admin_login_required
	check_admin_role('Administrator')
  end

  # GET /text_modules
  # GET /text_modules.xml
  def index
    @text_modules = TextModule.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @text_modules }
    end
  end

  # GET /text_modules/1
  # GET /text_modules/1.xml
  def show
    @text_module = TextModule.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @text_module }
    end
  end

  # GET /text_modules/new
  # GET /text_modules/new.xml
  def new
    @text_module = TextModule.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @text_module }
    end
  end

  # GET /text_modules/1/edit
  def edit
    @text_module = TextModule.find(params[:id])
  end

  # POST /text_modules
  # POST /text_modules.xml
  def create
    @text_module = TextModule.new(params[:text_module])

    respond_to do |format|
      if @text_module.save
        flash[:notice] = 'TextModule was successfully created.'
        format.html { redirect_to(params[:back_to] ) }
        format.xml  { render :xml => @text_module, :status => :created, :location => @text_module }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @text_module.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /text_modules/1
  # PUT /text_modules/1.xml
  def update
    @text_module = TextModule.find(params[:id])

    respond_to do |format|
      if @text_module.update_attributes(params[:text_module])
        flash[:notice] = 'TextModule was successfully updated.'
        format.html { redirect_to(params[:back_to] ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @text_module.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /text_modules/1
  # DELETE /text_modules/1.xml
  def destroy
    @text_module = TextModule.find(params[:id])
    @text_module.destroy

    respond_to do |format|
      format.html { redirect_to(request.referer) }
      format.xml  { head :ok }
    end
  end
end
