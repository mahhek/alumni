class StatusController < ApplicationController

  def success
	  if !flash[:message]
      redirect_to :controller=>:guide
    end
  end
end
