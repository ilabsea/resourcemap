class MessagesController < ApplicationController

	expose(:collections) { 
    if current_user && !current_user.is_guest
      # public collections are accesible by all users
      # here we only need the ones in which current_user is a member
      current_user.collections.reject{|c| c.id.nil?}
    else
      Collection.accessible_by(current_ability)
    end 
  }

  expose(:users) {
  	if current_user && !current_user.is_guest
  		collections_id = current_user.collections.pluck(:collection_id)
  		users_id = Membership.where(collection_id: collections_id).pluck(:user_id).uniq
  		users = User.where(id: users_id)
		else
			Collection.accessible_by(current_ability)
		end
  }

def index
	# debugger

	respond_to do |format|
		format.html
		format.json do
			collections_id = current_user.memberships.pluck(:collection_id)
			all_messages = []
			size = 25

			collections_id.push(nil)

			if params[:raws] || params[:collection_ids]
				if params[:raws] == ["0"] && !params[:collection_ids]
					collections_id = current_user.memberships.pluck(:collection_id)
				elsif params[:raws] != ["0"] && !params[:collection_ids]
					collections_id = current_user.memberships.pluck(:collection_id).push(nil)
				elsif params[:raws] == ["0"] && params[:collection_ids] != 0
					collections_id = params[:collection_ids]
				elsif params[:raws] != ["0"] && params[:collection_ids] == ["0"]
					collections_id = [nil]
				elsif params[:raws] != ["0"] && params[:collection_ids] != ["0"]
					collections_id = params[:collection_ids].push(nil)
				else
					collections_id = ["0"]
				end
			end

			msgs = Message.order('id desc').where(collection_id: collections_id)
			msgs = msgs.limit(25)
      msgs = msgs.where('id < ?', params[:before_id]) if params[:before_id]

			if params[:phone_number]
				phone_number = "%#{params[:phone_number]}%"
				msgs = msgs.where('`from` like ?', phone_number)
			end

			activities_json = msgs.map do |message|
				collection_name = message.collection_id.nil? ? "" : message.collection.name
				{
					id: message.id,
					collection: collection_name,
					user: message.from.split("//")[1],
					description: message.body,
					created_at: message.created_at
				}
			end
			render json: activities_json
		end
	end
end

end