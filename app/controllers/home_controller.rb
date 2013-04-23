class HomeController < ApplicationController
  
  before_filter :authenticate_user!, :except => [:show, :index]

  def index
    redirect_to collections_path if current_user && !params[:explicit]
  end

end
