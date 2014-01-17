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

  def load_app_cache
    content = "CACHE MANIFEST\n" + 
              "#timestamp #{DateTime.now.to_i}\n"+
              "/assets/jquery.mobile-1.3.1.min.css\n"+
              "/assets/jquery.js\n"+
              "/assets/jquery_ujs.js\n"+
              "/assets/mobile/mobilecache.js\n"+
              "/assets/mobile/home.js\n"+
              "/assets/mobile/collections/collection.js\n"+
              "/assets/mobile/collections/on_mobile_collections.js\n"+
              "/assets/mobile/events.js\n"+
              "/assets/mobile/field.js\n"+
              "/assets/mobile/option.js\n"+
              "/assets/jquery.mobile-1.3.1.min.js\n"+
              "/assets/images/ajax-loader.gif\n"+
              "/assets/images/icons-18-white.png\n"+
              "/images/add.png\n"+
              "/images/favicon.ico\n"+
              "/images/remove.ico\n"+
              "NETWORK:\n"+
              "*\n"

    render :text => content, :layout => false, :content_type => 'text/yaml'
  end
end
