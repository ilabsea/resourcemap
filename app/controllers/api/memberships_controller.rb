class Api::MembershipsController < ApplicationController
  protect_from_forgery :except => [:create, :update]

  USER_NAME, PASSWORD = 'iLab', '1c4989610bce6c4879c01bb65a45ad43'

  # POST /user
  def create
    user = User.new(params[:user])
    role = params[:role]
    collection = Collection.find(params[:collection_id])
    if user.save
      if !user.memberships.where(:collection_id => collection.id).exists?
        if role == "Admin"
          user.memberships.create! admin: false, :collection_id => collection.id
        elsif role == "Super Admin"
          user.memberships.create! admin: true, :collection_id => collection.id
        end
      end
      render :json => params[:user], :status => :ok
    else
      render :json => params[:user], :status => :unauthorized
    end
  end

  def update
    user = User.find_by_email(params["user"]["email"])
    role = params[:role]
    begin
      if user.update_attributes!(params[:user])
        if role == "Admin"
          member = user.memberships.find_by_collection_id(params[:collection_id])
          member.update_attributes! admin: false
        elsif role == "Super Admin"
          member = user.memberships.find_by_collection_id(params[:collection_id])
          member.update_attributes! admin: true
        end
        render :json => params[:user], :status => :ok
      else
        render :json => params[:user], :status => :unauthorized
      end
    rescue
      render :json => params[:user], :status => :unauthorized
    end
  end

  def authenticate
    authenticate_or_request_with_http_basic 'Dynamic Resource Map - HTTP' do |username, password|
      USER_NAME == username && PASSWORD == Digest::MD5.hexdigest(password)
    end
  end
end
