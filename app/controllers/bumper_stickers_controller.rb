class BumperstickersController < ApplicationController
  # GET /bumper_stickers
  # GET /bumper_stickers.xml

  def index
    @bumper_stickers = Bumpersticker.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @bumper_stickers }
    end
  end

  # GET /bumper_stickers/1
  # GET /bumper_stickers/1.xml
  def show
    @bumper_sticker = Bumpersticker.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @bumper_sticker }
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

  # GET /bumper_stickers/1/edit
  def edit
    @bumper_sticker = Bumpersticker.find(params[:id])
  end

  # POST /bumper_stickers
  # POST /bumper_stickers.xml
  def create
    @bumper_sticker = Bumpersticker.new(params[:bumper_sticker])

    respond_to do |format|
      if @bumper_sticker.save
        flash[:notice] = 'BumperSticker was successfully created.'
        format.html { redirect_to(@bumper_sticker) }
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
        flash[:notice] = 'BumperSticker was successfully updated.'
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
    @bumper_sticker.destroy

    respond_to do |format|
      format.html { redirect_to(bumperstickers_url) }
      format.xml  { head :ok }
    end
  end
end
