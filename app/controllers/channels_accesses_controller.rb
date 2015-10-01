class ChannelsAccessesController < ApplicationController
  before_filter :authenticate_user!

  def index
    @collections = Collection.joins(:users)
    @channels = Channel.where(:national_setup=>true)  if current_user.is_super_user
    @channels.each do |c|
      p c.name
    end
    @collections.each do |c|
      p c.name
      p c.users
    end
    # users = User.all()
    # @collections = []
    # users.each do |u|
    #   collectionsUser = Collection.joins(:memberships).where("memberships.user_id = :user_id", :user_id => u.id)
    #   collectionsUser.each do |c|
    #     @collections.push({
    #       user_id: u.id,
    #       user_email: u.email, 
    #       collection_id: c.id,
    #       collection_name: c.name, 
    #       is_enabled_national_gateway: c.is_enabled_national_gateway})
    #   end
    # end
    # p @nationalGateways
  end

  def new
    @shareNationalChannel = ShareNationalChannel.new
  end

  def create
    @shareChannel = Collection.find(filter_params[:collection_id])
    if @shareChannel.update_attributes(channel_ids: filter_params[:channel_id])
      redirect_to channels_accesses_path, notice: 'Collection updated'
    else
      flash.now[:alert] = "Failed to update collection"
      render :new
    end    
  end

  def create
    @collection = current_user.collections(params[:collection][:id])
    if @collection.update_attributes(filter_params)
      redirect_to national_gateways_path, notice: 'Project is granted access to the national gateway'
    else
      redirect_to national_gateways_path, alert: 'Fialed to grant access to national gateway'
    end
  end

  def search_user
    users = User.
      where('email LIKE ?', "#{params[:term]}%").
      order('email')

    render json: users.pluck(:email)
  end

  def search_collection
    collections = Collection.includes(:users).where('memberships.owner = ? ',1)
      .where('name LIKE ?', "#{params[:term]}%").
      order('name')

    render json: collections.as_json(include: :users)
  end

  private
  def filter_params
    params.require(:collection).permit(:is_enabled_national_gateway)
  end
end
