class PaymentInformationsController < ApplicationController
  layout 'application'
  # GET /payment_informations
  # GET /payment_informations.xml
  def index
    @payment_informations = PaymentInformation.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @payment_informations }
    end
  end

  # GET /payment_informations/1
  # GET /payment_informations/1.xml
  def show
    @payment_information = PaymentInformation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @payment_information }
    end
  end

  # GET /payment_informations/new
  # GET /payment_informations/new.xml
  def new
    @payment_information = PaymentInformation.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @payment_information }
    end
  end

  # GET /payment_informations/1/edit
  def edit
    @payment_information = PaymentInformation.find(params[:id])
  end

  # POST /payment_informations
  # POST /payment_informations.xml
  def create
    @payment_information = PaymentInformation.new(params[:payment_information])

    respond_to do |format|
      if @payment_information.save
        flash[:notice] = 'PaymentInformation was successfully created.'
        format.html { redirect_to(@payment_information) }
        format.xml  { render :xml => @payment_information, :status => :created, :location => @payment_information }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @payment_information.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /payment_informations/1
  # PUT /payment_informations/1.xml
  def update
    @payment_information = PaymentInformation.find(params[:id])

    respond_to do |format|
      if @payment_information.update_attributes(params[:payment_information])
        flash[:notice] = 'PaymentInformation was successfully updated.'
        format.html { redirect_to(@payment_information) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @payment_information.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /payment_informations/1
  # DELETE /payment_informations/1.xml
  def destroy
    @payment_information = PaymentInformation.find(params[:id])
    @payment_information.destroy

    respond_to do |format|
      format.html { redirect_to(payment_informations_url) }
      format.xml  { head :ok }
    end
  end
end
