module Api::V1
  class MembershipsController < ApplicationController
    before_filter :authenticate_user!
    before_filter :authenticate_collection_admin!, :only => [:index]
    
    include ApplicationHelper 
    
    def index
      layer_memberships = collection.layer_memberships.all.inject({}) do |hash, membership|
        (hash[membership.user_id] ||= []) << membership
        hash
      end
      memberships = collection.memberships.includes([:user, :read_sites_permission, :write_sites_permission]).all.map do |membership|
        user_display_name = User.generate_user_display_name membership.user
        if user_display_name == membership.user.phone_number
          user_phone_number = ""
        else
          user_phone_number = membership.user.phone_number
        end
        
        {
          user_id: membership.user_id,
          user_display_name: user_display_name,
          user_phone_number: user_phone_number,
          admin: membership.admin?,
          layers: (layer_memberships[membership.user_id] || []).map{|x| {layer_id: x.layer_id, read: x.read?, write: x.write?}},
          sites: {
            none: membership.none_sites_permission,
            read: membership.read_sites_permission,
            write: membership.write_sites_permission
          }
        }
      end
      render json: memberships
    end

    def search
      users = User.
        where('email LIKE ?', "#{params[:term]}%").
        where("id in (?)", collection.memberships.value_of(:user_id)).
        order('email')

      render json: users.pluck(:email)
    end
  end
end
