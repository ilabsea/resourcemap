class HomeController < ApplicationController
  
  before_filter :authenticate_user!, :except => [:show, :index]

  def index
    if current_user && !params[:explicit]
      if mobile_device?
        redirect_to mobile_collections_path 
      else
        redirect_to collections_path
      end
    else
      if mobile_device?
        redirect_to new_user_session_path 
      end
    end
  end
end
