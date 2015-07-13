module Api::V2
	class TokensController < ApiController
	  before_filter :authenticate_api_user!

	  def index
	    render :json => {:token => current_user.authentication_token}
	  end

	  def destroy
	    current_user.reset_authentication_token!
	  end
	end
end