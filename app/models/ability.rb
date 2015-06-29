class Ability
  include CanCan::Ability

  def initialize(user, format = nil)

    user ||= User.new :is_guest => true

    ### Collection ###

    # Admin abilities
    can [:destroy, :create_snapshot, :recreate_index, :update, :members,:send_new_member_sms, :register_gateways], Collection, :memberships => { :user_id => user.id , :admin => true }
    can :manage, Snapshot, :collection => {:memberships => { :user_id => user.id , :admin => true } }

    # User can read collection if she is a collection member or if the collection is public
    can [:read, :sites_by_term, :search, :sites_info, :alerted_collections, :register_gateways], Collection, :memberships => { :user_id => user.id }
    can [:read, :sites_by_term, :search, :sites_info, :alerted_collections, :register_gateways], Collection, :public => true

    can [:search, :index, :search_alert_site], Site, :collection => {:public => true}
    can [:search, :index, :search_alert_site], Site, :collection => {:memberships => { :user_id => user.id }}
    can :delete, Site, :collection => {:memberships => { :user_id => user.id , :admin => true } }
    
    if !user.is_guest
      can [:new, :create], Collection
    end

    # Member Abilities
    can [:csv_template, :upload_csv, :unload_current_snapshot, :load_snapshot, :register_gateways, :message_quota, :reminders, :settings, :quotas], Collection, :memberships => { :user_id => user.id }

    # In progress
    can :max_value_of_property, Collection, :memberships => { :user_id => user.id }
    can :decode_hierarchy_csv, Collection, :memberships => { :user_id => user.id }
    can :decode_location_csv, Collection, :memberships => { :user_id => user.id }
    can :download_location_csv, Collection, :memberships => { :user_id => user.id }


    #Move from InSTEDD RM
    can :update_site_property, Field do |field, site|
      if user.is_guest
        false
      else
        collection = field.collection
        membership = Membership.where("user_id = ? and collection_id = ?", user.id, collection.id).first

        if membership
          admin = membership.try(:admin?)
          lm = LayerMembership.where("user_id = ? and collection_id = ? and layer_id = ?",user.id,collection.id,field.layer_id).first
          # lm = membership.layer_memberships.find{|layer_membership| layer_membership.layer_id == field.layer_id}
          admin || (lm && lm.write)
        else
          false
        end
      end
    end

    # Full update, only admins have rights to do this
    can :update, Site, :collection => { :memberships => { :user_id => user.id, :admin => true } }

    can :update_name, Membership do |user_membership|
      user_membership.can_update?("name")
    end

    can :update_location, Membership do |user_membership|
      user_membership.can_update?("location")
    end

  end
end
